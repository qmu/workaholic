#!/bin/sh -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/result.sh"
transport_parse_request_arg "$@"
[ "$TRANSPORT_OPERATION" != discover ] || exec "${SCRIPT_DIR}/resolve-target.sh" --request "$TRANSPORT_REQUEST_FILE"
jq -e '.binding_id|type=="string" and length>0' "$TRANSPORT_REQUEST_FILE" >/dev/null 2>&1 || transport_usage "operation requires binding_id"
jq -e '.input.binding|type=="object" and (.workspace|type=="string" and length>0) and (.channel|type=="string" and length>0) and (.routes|type=="array")' "$TRANSPORT_REQUEST_FILE" >/dev/null 2>&1 || transport_usage "operation requires resolved binding"
binding_id=$(jq -r .binding_id "$TRANSPORT_REQUEST_FILE")
case "$binding_id" in *[!A-Za-z0-9._-]*|.|..) transport_usage "binding_id is not path safe";; esac
tmpdir=$(mktemp -d); trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM
case "$TRANSPORT_OPERATION" in read_thread|post_reply)
  if [ -z "$(jq -r '.input.thread_ts // empty' "$TRANSPORT_REQUEST_FILE")" ]; then
    thread_key=$(jq -r '.input.thread_key // empty' "$TRANSPORT_REQUEST_FILE")
    mapped=$(jq -r --arg key "$thread_key" '.input.binding.thread_map[$key] // empty' "$TRANSPORT_REQUEST_FILE")
    [ -n "$mapped" ] || { transport_result deferred thread_unresolved "$TRANSPORT_REQUEST_ID" '{}'; exit 0; }
    jq --arg thread "$mapped" '.input.thread_ts=$thread' "$TRANSPORT_REQUEST_FILE" >"$tmpdir/mapped-request.json"
    TRANSPORT_REQUEST_FILE="$tmpdir/mapped-request.json"
  fi;;
esac

required_sender=""
case "$TRANSPORT_OPERATION" in post_root|post_reply|add_reaction)
  required_sender=$(jq -r '.input.expected_sender_id // .input.binding.sender_id // empty' "$TRANSPORT_REQUEST_FILE")
  if [ -n "$required_sender" ] && ! jq -e --arg op "$TRANSPORT_OPERATION" --arg sender "$required_sender" \
      '.input.binding.routes[]?|select((.operations|index($op)) and (.sender_id//"")==$sender)' "$TRANSPORT_REQUEST_FILE" >/dev/null 2>&1; then
    actual=$(jq -c --arg op "$TRANSPORT_OPERATION" '[.input.binding.routes[]?|select(.operations|index($op))|.sender_id//null]|unique' "$TRANSPORT_REQUEST_FILE")
    transport_result deferred sender_mismatch "$TRANSPORT_REQUEST_ID" "$(jq -cn --arg expected "$required_sender" --argjson actual "$actual" '{expected_sender_id:$expected,actual_sender_ids:$actual}')"
    exit 0
  fi;;
esac

# Candidate filtering and ranking are one operation. The route whose sender was
# checked is therefore always the route that executes, regardless of input order.
has_route() {
  jq -e --arg t "$1" --arg op "$TRANSPORT_OPERATION" --arg sender "$required_sender" \
    '.input.binding.routes[]?|select(.transport==$t and (.operations|index($op)) and ($sender=="" or (.sender_id//"")==$sender))' "$TRANSPORT_REQUEST_FILE" >/dev/null 2>&1
}

choose_route() {
    if has_route qfs && jq -e --arg op "$TRANSPORT_OPERATION" --arg sender "$required_sender" '.input.binding.routes[]?|select(.transport=="qfs" and .described==true and (.operations|index($op)) and ($sender=="" or (.sender_id//"")==$sender))' "$TRANSPORT_REQUEST_FILE" >/dev/null 2>&1; then echo qfs
    elif has_route connector; then echo connector
    elif has_route slack_token && [ -n "${SLACK_BOT_TOKEN:-}" ]; then echo slack_token
    elif has_route qfs; then echo qfs_unproved
    elif has_route slack_token; then echo token_unavailable
    else echo unavailable
    fi
}

case "$TRANSPORT_OPERATION" in
  read_channel_delta|read_thread|search_exact)
    route=$(choose_route)
    case "$route" in
      qfs) exec "${SCRIPT_DIR}/adapters/qfs.sh" --request "$TRANSPORT_REQUEST_FILE" ;;
      connector)
        data=$(jq -c '{operation, target:(.input.binding|{workspace,channel,channel_id}), arguments:(.input|del(.binding,.parent_observation))}' "$TRANSPORT_REQUEST_FILE")
        transport_result needs_parent connector_required "$TRANSPORT_REQUEST_ID" "$data" ;;
      qfs_unproved) transport_result deferred qfs_map_unverified "$TRANSPORT_REQUEST_ID" '{}' ;;
      *) transport_result deferred operation_unavailable "$TRANSPORT_REQUEST_ID" '{}' ;;
    esac
    exit 0
    ;;
esac

case "$TRANSPORT_REQUEST_ID" in *[!A-Za-z0-9._-]*|.|..) transport_usage "send request_id is not path safe";; esac
STATE="${SCRIPT_DIR}/../../runtime/scripts/state.sh"
[ -x "$STATE" ] || { transport_result error state_writer_missing "$TRANSPORT_REQUEST_ID" '{}'; exit 0; }
repo=$(jq -r .repo_root "$TRANSPORT_REQUEST_FILE"); [ -d "$repo" ] || transport_usage "repo_root does not exist"
now=$(jq -r '.input.now // empty' "$TRANSPORT_REQUEST_FILE"); [ -n "$now" ] || now=$(date -Iseconds)
nonce=$(printf '%s' "$(jq -r .instance_id "$TRANSPORT_REQUEST_FILE"):$binding_id" | sha256sum | cut -c1-24)
owner=$(jq -cn --arg i "$(jq -r .instance_id "$TRANSPORT_REQUEST_FILE")" --arg n "$nonce" --arg h "transport:$binding_id" '{instance_id:$i,nonce:$n,harness_receipt:$h}')
state_call() { (cd "$repo" && "$STATE" "$@"); }
meta=$(state_call read --scope binding --id "$binding_id")
if [ "$(printf '%s' "$meta" | jq -r '.data.found')" != true ]; then
    jq -cn --arg now "$now" --argjson owner "$owner" --argjson target "$(jq -c .input.binding "$TRANSPORT_REQUEST_FILE")" '{updated_at:$now,owner:$owner,data:{lease_status:"acquired",target:$target}}' >"$tmpdir/meta.json"
    created=$(state_call create --scope binding --id "$binding_id" --input "$tmpdir/meta.json")
    if [ "$(printf '%s' "$created" | jq -r .status)" != ok ]; then meta=$(state_call read --scope binding --id "$binding_id"); else meta=$(printf '%s' "$created" | jq -c '{data:{found:true,record:.data.record}}'); fi
fi
record=$(printf '%s' "$meta" | jq -c '.data.record')
current_owner=$(printf '%s' "$record" | jq -c .owner); generation=$(printf '%s' "$record" | jq -r .generation)
if [ "$current_owner" = null ]; then
    rev=$(printf '%s' "$record" | jq -r .revision)
    jq -cn --arg now "$now" --argjson owner "$owner" '{updated_at:$now,event:"acquire",owner:$owner}' >"$tmpdir/acquire.json"
    acquired=$(state_call transition --scope binding --id "$binding_id" --expected-revision "$rev" --input "$tmpdir/acquire.json")
    [ "$(printf '%s' "$acquired" | jq -r .status)" = ok ] || { transport_result deferred binding_busy "$TRANSPORT_REQUEST_ID" '{}'; exit 0; }
    record=$(printf '%s' "$acquired" | jq -c '.data.record'); current_owner=$(printf '%s' "$record" | jq -c .owner); generation=$(printf '%s' "$record" | jq -r .generation)
fi
[ "$(printf '%s' "$current_owner" | jq -r .instance_id)" = "$(jq -r .instance_id "$TRANSPORT_REQUEST_FILE")" ] || { transport_result deferred binding_owned "$TRANSPORT_REQUEST_ID" '{}'; exit 0; }
owner=$current_owner

out=$(state_call read --scope binding --id "$binding_id" --record "outbox/$TRANSPORT_REQUEST_ID")
if [ "$(printf '%s' "$out" | jq -r '.data.found')" != true ]; then
    intent=$(jq -c '{operation,target:(.input.binding|{workspace,channel,channel_id}),arguments:(.input|del(.binding,.parent_observation))}' "$TRANSPORT_REQUEST_FILE")
    jq -cn --arg now "$now" --argjson owner "$owner" --argjson generation "$generation" --argjson intent "$intent" '{updated_at:$now,owner:$owner,generation:$generation,data:{state:"planned",intent:$intent,provider_result:null}}' >"$tmpdir/outbox.json"
    out=$(state_call create --scope binding --id "$binding_id" --record "outbox/$TRANSPORT_REQUEST_ID" --input "$tmpdir/outbox.json")
    [ "$(printf '%s' "$out" | jq -r .status)" = ok ] || { transport_result deferred outbox_conflict "$TRANSPORT_REQUEST_ID" '{}'; exit 0; }
    out_record=$(printf '%s' "$out" | jq -c .data.record)
else out_record=$(printf '%s' "$out" | jq -c .data.record)
fi
out_state=$(printf '%s' "$out_record" | jq -r '.data.state'); out_rev=$(printf '%s' "$out_record" | jq -r .revision)
if [ "$out_state" = confirmed ]; then transport_result ok "" "$TRANSPORT_REQUEST_ID" "$(printf '%s' "$out_record" | jq -c '.data.provider_result')"; exit 0; fi
if [ "$out_state" = refused ]; then transport_result deferred delivery_refused "$TRANSPORT_REQUEST_ID" '{}'; exit 0; fi

transition_outbox() {
    _to_event=$1 _to_result=${2:-null}
    jq -cn --arg now "$now" --arg event "$_to_event" --argjson owner "$owner" --argjson generation "$generation" --argjson result "$_to_result" '{updated_at:$now,event:$event,owner:$owner,generation:$generation,data:{provider_result:$result}}' >"$tmpdir/transition.json"
    changed=$(state_call transition --scope binding --id "$binding_id" --record "outbox/$TRANSPORT_REQUEST_ID" --expected-revision "$out_rev" --input "$tmpdir/transition.json")
    [ "$(printf '%s' "$changed" | jq -r .status)" = ok ] || { transport_result deferred outbox_conflict "$TRANSPORT_REQUEST_ID" '{}'; exit 0; }
    out_record=$(printf '%s' "$changed" | jq -c .data.record); out_rev=$(printf '%s' "$out_record" | jq -r .revision); out_state=$(printf '%s' "$out_record" | jq -r '.data.state')
}

if jq -e '.input.parent_observation|type=="object"' "$TRANSPORT_REQUEST_FILE" >/dev/null 2>&1; then
    printf '%s\n' "$(jq -c .input.parent_observation "$TRANSPORT_REQUEST_FILE")" >"$tmpdir/observation.json"
    accepted=$("${SCRIPT_DIR}/accept-observation.sh" --request "$TRANSPORT_REQUEST_FILE" --result "$tmpdir/observation.json") || {
      accept_code=$?; printf '%s\n' "$accepted"; exit "$accept_code"
    }
    if [ "$(printf '%s' "$accepted" | jq -r .status)" = ok ]; then
      [ "$out_state" = sending ] || [ "$out_state" = unknown ] || { transport_result deferred invalid_delivery_state "$TRANSPORT_REQUEST_ID" '{}'; exit 0; }
      transition_outbox confirmed "$(printf '%s' "$accepted" | jq -c .data)"
      printf '%s\n' "$accepted"; exit 0
    fi
    case "$(printf '%s' "$accepted" | jq -r .reason)" in connector_failure|delivery_unconfirmed) [ "$out_state" = sending ] && transition_outbox unknown;; *) [ "$out_state" = planned ] || [ "$out_state" = sending ] && transition_outbox refused;; esac
    printf '%s\n' "$accepted"; exit 0
fi

if [ "$TRANSPORT_OPERATION" = reconcile_send ]; then
    [ "$out_state" = unknown ] || { transport_result deferred reconcile_not_needed "$TRANSPORT_REQUEST_ID" "$(jq -cn --arg state "$out_state" '{state:$state}')"; exit 0; }
else
    if [ "$out_state" = sending ]; then transition_outbox unknown; transport_result deferred needs_reconcile "$TRANSPORT_REQUEST_ID" '{}'; exit 0; fi
    [ "$out_state" = planned ] || { transport_result deferred needs_reconcile "$TRANSPORT_REQUEST_ID" '{}'; exit 0; }
    transition_outbox sending
fi

route=$(choose_route)
case "$route" in
  qfs) adapter="${SCRIPT_DIR}/adapters/qfs.sh";;
  slack_token) adapter="${SCRIPT_DIR}/adapters/slack-token.sh";;
  connector)
    data=$(jq -c '{operation,target:(.input.binding|{workspace,channel,channel_id}),arguments:(.input|del(.binding,.parent_observation))}' "$TRANSPORT_REQUEST_FILE")
    transport_result needs_parent connector_required "$TRANSPORT_REQUEST_ID" "$data"; exit 0;;
  qfs_unproved) [ "$out_state" = sending ] && transition_outbox unknown; transport_result deferred qfs_map_unverified "$TRANSPORT_REQUEST_ID" '{}'; exit 0;;
  token_unavailable) transition_outbox refused; transport_result deferred no_token "$TRANSPORT_REQUEST_ID" '{}'; exit 0;;
  *) transition_outbox refused; transport_result deferred operation_unavailable "$TRANSPORT_REQUEST_ID" '{}'; exit 0;;
esac
result=$("$adapter" --request "$TRANSPORT_REQUEST_FILE")
status=$(printf '%s' "$result" | jq -r .status); reason=$(printf '%s' "$result" | jq -r .reason)
if [ "$status" = ok ]; then
  # Provider adapters and parent connectors cross the same confirmation seam.
  # An adapter's successful invocation is not delivery evidence until the
  # returned target, timestamp, and sender satisfy the original request.
  printf '%s' "$result" | jq -c --arg op "$TRANSPORT_OPERATION" '
    {request_id,operation:$op,status,target:(.data|{workspace,channel,channel_id}),data}' >"$tmpdir/adapter-observation.json"
  accepted=$("${SCRIPT_DIR}/accept-observation.sh" --request "$TRANSPORT_REQUEST_FILE" --result "$tmpdir/adapter-observation.json")
  if [ "$(printf '%s' "$accepted" | jq -r .status)" = ok ]; then
    transition_outbox confirmed "$(printf '%s' "$accepted" | jq -c .data)"
    result=$accepted
  else
    # The provider may already have accepted the effect. Missing or mismatched
    # evidence therefore requires reconciliation and never licenses a resend.
    transition_outbox unknown
    result=$accepted
  fi
elif [ "$reason" = accepted_send_timeout ] || [ "$reason" = provider_timeout ] || [ "$reason" = qfs_connector_failure ]; then transition_outbox unknown
else transition_outbox refused
fi
printf '%s\n' "$result"
