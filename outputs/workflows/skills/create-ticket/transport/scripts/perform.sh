#!/bin/sh -eu

# THE ROLE THIS PATH RUNS UNDER (2026-09-11, issue #1151): the base-ref gate reads
# `WORKAHOLIC_ROLE`, and an unattended path names itself at its own entry rather than trusting a
# caller to compose an assignment prefix. An already-set role (a dispatch's) is kept.
: "${WORKAHOLIC_ROLE:=notify}"
export WORKAHOLIC_ROLE

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/result.sh"
transport_parse_request_arg "$@"
[ "$TRANSPORT_OPERATION" != discover ] || exec "${SCRIPT_DIR}/resolve-target.sh" --request "$TRANSPORT_REQUEST_FILE"
jq -e '.binding_id|type=="string" and length>0' "$TRANSPORT_REQUEST_FILE" >/dev/null 2>&1 || transport_usage "operation requires binding_id"
jq -e '.input.binding|type=="object" and (.workspace|type=="string" and length>0) and (.channel|type=="string" and length>0) and (.routes|type=="array")' "$TRANSPORT_REQUEST_FILE" >/dev/null 2>&1 || transport_usage "operation requires resolved binding"
binding_id=$(jq -r .binding_id "$TRANSPORT_REQUEST_FILE")
case "$binding_id" in *[!A-Za-z0-9._-]*|.|..) transport_usage "binding_id is not path safe";; esac
# ---- Revalidation ------------------------------------------------------------------------
# A caller that knows which declaration it resolved against says so, and a binding resolved
# against a DIFFERENT declaration is refused rather than used: an operator who re-points the
# channel must not have the next effect land at the old one because a resolution outlived the
# declaration it came from. Absent on both sides, nothing changes.
expected_digest=$(jq -r '.input.expected_declared_digest // empty' "$TRANSPORT_REQUEST_FILE")
if [ -n "$expected_digest" ]; then
  actual_digest=$(jq -r '.input.binding.declared_digest // empty' "$TRANSPORT_REQUEST_FILE")
  if [ "$expected_digest" != "$actual_digest" ]; then
    transport_result deferred binding_stale "$TRANSPORT_REQUEST_ID" \
      "$(jq -cn --arg expected "$expected_digest" --arg actual "$actual_digest" '{expected_declared_digest:$expected,binding_declared_digest:(if $actual=="" then null else $actual end)}')"
    exit 0
  fi
fi
tmpdir=$(mktemp -d)
LEASE_HELD=false
cleanup_transport() {
  if [ "$LEASE_HELD" = true ]; then
    jq -cn --arg now "$(date -Iseconds)" --argjson owner "$owner" --argjson generation "$generation" \
      '{updated_at:$now,event:"release",owner:$owner,generation:$generation}' >"$tmpdir/release.json" 2>/dev/null || true
    state_call transition --scope binding --id "$binding_id" --expected-revision "$meta_revision" --input "$tmpdir/release.json" >/dev/null 2>&1 || true
  fi
  rm -rf "$tmpdir"
}
trap cleanup_transport EXIT HUP INT TERM
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
  required_sender=$(jq -r '.input.expected_sender_id // .input.binding.sender_id // empty' "$TRANSPORT_REQUEST_FILE");;
esac
# A DECLARED sender is a term of the binding, not a preference: a write that cannot be proved to
# speak as it must be refused rather than delivered under whatever identity a fallback happens to
# carry. Measured in one channel: 94 messages from a person's account, 3 from a bot, 0 from the
# declared sender. The refusal is made BELOW, once the outbox exists, so it is a delivery status
# an operator can see and reconcile rather than an early exit that recorded nothing. A binding
# declaring NO sender is untouched here — the advisory `unverifiable_sender` names that
# repository, and stopping such a loop is not this rule's job.
sender_proved() {
  [ -n "$required_sender" ] || return 0
  jq -e --arg op "$TRANSPORT_OPERATION" --arg sender "$required_sender" \
    '.input.binding.routes[]?|select((.operations|index($op)) and (.sender_id//"")==$sender)' "$TRANSPORT_REQUEST_FILE" >/dev/null 2>&1
}

# Candidate filtering and ranking are one operation. The route whose sender was
# checked is therefore always the route that executes, regardless of input order.
has_route() {
  jq -e --arg t "$1" --arg op "$TRANSPORT_OPERATION" --arg sender "$required_sender" \
    '.input.binding.routes[]?|select(.transport==$t and (.operations|index($op)) and ($sender=="" or (.sender_id//"")==$sender))' "$TRANSPORT_REQUEST_FILE" >/dev/null 2>&1
}

# ---- Typed fallback -----------------------------------------------------------------------
# An operation leaves the preferred route ONLY on a named failure, and this case is the one
# derivation of which. Every other failure keeps the operation where it was declared: an untyped
# switch is how a route nobody configured starts carrying the loop's traffic while every report
# says it succeeded. TYPED IS NOT THE SAME AS FALLBACK-PERMITTING, and exactly one of the four
# classes is not: `qfs_preview_refused` is typed and answers `none`, because an authorization
# denial stays a refusal and no alternate route, alternate spelling, parent delegation or second
# account is used to get past one (`branching/scripts/refusal-capability.sh`'s `not_permitted`).
qfs_fallback_class() {
  case "$1" in
    qfs_unavailable) echo availability ;;
    qfs_operation_unavailable|qfs_map_unverified) echo capability ;;
    qfs_preview_refused) echo none ;;
    qfs_preview_failed) echo reachability ;;
    *) echo none ;;
  esac
}
# A READ may also leave on a reachability failure; a WRITE may NOT. Every write class above
# fails BEFORE `--commit`, so nothing was accepted; `qfs_connector_failure` and
# `accepted_send_timeout` happen after it, and an unknown effect is reconciled, never resent.
read_fallback_class() {
  case "$1" in qfs_connector_failure) echo reachability ;; *) qfs_fallback_class "$1" ;; esac
}
# The declared order governs. An absent `fallback` keeps the historical order; an explicitly
# EMPTY one forbids every fallback, which is how an operator says "this route or nothing".
fallback_permits() {
  jq -e --arg t "$1" 'if (.input.binding | has("fallback"))
    then (((.input.binding.fallback // []) | index($t)) != null) else true end' "$TRANSPORT_REQUEST_FILE" >/dev/null 2>&1
}
fallback_order() {
  jq -r 'if (.input.binding | has("fallback")) then ((.input.binding.fallback // [])[]?)
         else ("connector", "slack_token") end' "$TRANSPORT_REQUEST_FILE"
}
# The PREFERRED transport is a property of the binding, not of one operation: a binding that
# declares a QFS route declares QFS as its route, and an operation that leaves it has left it.
prefers_qfs() {
  jq -e '.input.binding.routes[]?|select(.transport=="qfs")' "$TRANSPORT_REQUEST_FILE" >/dev/null 2>&1
}
# Why it left, in the vocabulary the classifier already uses.
undescribed_reason() {
  if jq -e --arg op "$TRANSPORT_OPERATION" --arg sender "$required_sender" \
      '.input.binding.routes[]?|select(.transport=="qfs" and (.operations|index($op)) and ($sender=="" or (.sender_id//"")==$sender))' "$TRANSPORT_REQUEST_FILE" >/dev/null 2>&1
  then echo qfs_map_unverified; else echo qfs_operation_unavailable; fi
}
DEGRADED_FROM="" DEGRADATION_REASON=""
# Every result says which route carried it and whether that route was the declared one. A
# connector success is a DEGRADED success: it proves the message arrived, and proves nothing
# about the preferred route's configuration or about who spoke.
decorate() {
  printf '%s' "$1" | jq -c --arg route "$2" --arg from "$DEGRADED_FROM" --arg why "$DEGRADATION_REASON" \
    '.data = ((.data // {}) + {route:$route, degraded:($from != ""),
       degraded_from:(if $from == "" then null else $from end),
       degradation_reason:(if $why == "" then null else $why end),
       preferred_route_verified:($from == "" and $route == "qfs" and .status == "ok")})'
}
connector_handoff() {
  # Workspace, channel ID, thread timestamp and expected sender ride the handoff verbatim:
  # a fallback that re-resolved the destination would be a different destination.
  data=$(jq -c '{operation, target:(.input.binding|{workspace,channel,channel_id}), arguments:(.input|del(.binding,.parent_observation))}' "$TRANSPORT_REQUEST_FILE")
  decorate "$(transport_result needs_parent connector_required "$TRANSPORT_REQUEST_ID" "$data")" connector
}

choose_route() {
    if has_route qfs && jq -e --arg op "$TRANSPORT_OPERATION" --arg sender "$required_sender" '.input.binding.routes[]?|select(.transport=="qfs" and .described==true and (.operations|index($op)) and ($sender=="" or (.sender_id//"")==$sender))' "$TRANSPORT_REQUEST_FILE" >/dev/null 2>&1; then echo qfs
    elif has_route connector && { ! prefers_qfs || fallback_permits connector; }; then echo connector
    elif has_route slack_token && [ -n "${SLACK_BOT_TOKEN:-}" ] && { ! prefers_qfs || fallback_permits slack_token; }; then echo slack_token
    elif has_route qfs; then echo qfs_unproved
    elif has_route slack_token; then echo token_unavailable
    else echo unavailable
    fi
}
# The first declared fallback that can actually carry this operation, or nothing.
next_route() {
    for candidate in $(fallback_order); do
      case "$candidate" in
        connector) if has_route connector; then echo connector; return 0; fi ;;
        slack_token) if has_route slack_token && [ -n "${SLACK_BOT_TOKEN:-}" ]; then echo slack_token; return 0; fi ;;
      esac
    done
    return 0
}

case "$TRANSPORT_OPERATION" in
  read_channel_delta|list_thread_changes|read_thread|search_exact)
    route=$(choose_route)
    if [ "$route" = qfs ]; then
      adapter_code=0
      result=$("${SCRIPT_DIR}/adapters/qfs.sh" --request "$TRANSPORT_REQUEST_FILE") || adapter_code=$?
      # An adapter that REFUSED THE INPUT is our defect, not a route failure: it exits
      # non-zero and its verdict is passed through untouched, never turned into a fallback.
      [ "$adapter_code" -eq 0 ] || { printf '%s\n' "$result"; exit "$adapter_code"; }
      if [ "$(printf '%s' "$result" | jq -r .status)" = ok ]; then decorate "$result" qfs; exit 0; fi
      reason=$(printf '%s' "$result" | jq -r .reason)
      if [ "$(read_fallback_class "$reason")" = none ]; then printf '%s\n' "$result"; exit 0; fi
      fallback=$(next_route)
      [ -n "$fallback" ] || { printf '%s\n' "$result"; exit 0; }
      DEGRADED_FROM=qfs; DEGRADATION_REASON=$reason; route=$fallback
    elif prefers_qfs; then
      # A declared QFS route that cannot carry this operation — its map was never described,
      # or the operation is not in it. The switch is permitted, it is a capability failure,
      # but it is never silent and it never certifies the preferred route.
      DEGRADED_FROM=qfs; DEGRADATION_REASON=$(undescribed_reason)
    fi
    case "$route" in
      connector) connector_handoff ;;
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
boot_id=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || printf unknown)
process_start=$(awk '{print $22}' "/proc/$$/stat" 2>/dev/null || printf unknown)
owner=$(jq -cn --arg i "$(jq -r .instance_id "$TRANSPORT_REQUEST_FILE")" --arg n "$nonce" --argjson pid "$$" --arg boot "$boot_id" --arg start "$process_start" '{instance_id:$i,nonce:$n,process_id:$pid,boot_id:$boot,process_start:$start}')
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
if [ "$(printf '%s' "$current_owner" | jq -r .instance_id)" != "$(jq -r .instance_id "$TRANSPORT_REQUEST_FILE")" ]; then
    old_pid=$(printf '%s' "$current_owner" | jq -r '.process_id // empty'); old_boot=$(printf '%s' "$current_owner" | jq -r '.boot_id // empty'); old_start=$(printf '%s' "$current_owner" | jq -r '.process_start // empty')
    old_ended=false
    if [ -n "$old_pid" ] && [ -n "$old_boot" ] && [ -n "$old_start" ] && [ "$boot_id" != unknown ]; then
      if [ "$old_boot" != "$boot_id" ] || [ ! -r "/proc/${old_pid}/stat" ]; then old_ended=true
      else live_start=$(awk '{print $22}' "/proc/${old_pid}/stat" 2>/dev/null || printf ''); [ "$live_start" = "$old_start" ] || old_ended=true; fi
    fi
    [ "$old_ended" = true ] || { transport_result deferred binding_owned "$TRANSPORT_REQUEST_ID" '{}'; exit 0; }
    rev=$(printf '%s' "$record" | jq -r .revision)
    jq -cn --arg now "$now" --argjson owner "$owner" --argjson old "$current_owner" '{updated_at:$now,event:"takeover",expired:true,old_owner_ended:true,old_owner_evidence:{owner:$old,process:"ended"},owner:$owner}' >"$tmpdir/takeover.json"
    acquired=$(state_call transition --scope binding --id "$binding_id" --expected-revision "$rev" --input "$tmpdir/takeover.json")
    [ "$(printf '%s' "$acquired" | jq -r .status)" = ok ] || { transport_result deferred binding_busy "$TRANSPORT_REQUEST_ID" '{}'; exit 0; }
    record=$(printf '%s' "$acquired" | jq -c '.data.record'); current_owner=$(printf '%s' "$record" | jq -c .owner); generation=$(printf '%s' "$record" | jq -r .generation)
fi
owner=$current_owner
meta_revision=$(printf '%s' "$record" | jq -r .revision)
LEASE_HELD=true

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

# The write's identity is settled before a route is chosen, and the refusal is RECORDED: the
# outbox goes `refused`, so a later identical request answers `delivery_refused` rather than
# trying again, and the result carries the typed reason with `route: null` and
# `preferred_route_verified: false` — an unavailable identity is visible rather than inferred
# from a channel's message counts. Nothing was sent, under any account.
if ! sender_proved; then
    actual=$(jq -c --arg op "$TRANSPORT_OPERATION" '[.input.binding.routes[]?|select(.operations|index($op))|.sender_id//null]|unique' "$TRANSPORT_REQUEST_FILE")
    [ "$TRANSPORT_OPERATION" = reconcile_send ] || transition_outbox refused
    transport_result deferred sender_mismatch "$TRANSPORT_REQUEST_ID" \
      "$(jq -cn --arg expected "$required_sender" --argjson actual "$actual" \
         '{expected_sender_id:$expected,actual_sender_ids:$actual,route:null,degraded:false,
           degraded_from:null,degradation_reason:null,preferred_route_verified:false}')"
    exit 0
fi
route=$(choose_route)
if [ "$route" != qfs ] && prefers_qfs; then DEGRADED_FROM=qfs; DEGRADATION_REASON=$(undescribed_reason); fi
select_adapter() {
  case "$1" in
    qfs) adapter="${SCRIPT_DIR}/adapters/qfs.sh" ;;
    slack_token) adapter="${SCRIPT_DIR}/adapters/slack-token.sh" ;;
    *) adapter="" ;;
  esac
}
case "$route" in
  qfs) adapter="${SCRIPT_DIR}/adapters/qfs.sh";;
  slack_token) adapter="${SCRIPT_DIR}/adapters/slack-token.sh";;
  connector) connector_handoff; exit 0;;
  qfs_unproved) [ "$out_state" = sending ] && transition_outbox unknown; transport_result deferred qfs_map_unverified "$TRANSPORT_REQUEST_ID" '{}'; exit 0;;
  token_unavailable)
    if [ "$TRANSPORT_OPERATION" = reconcile_send ]; then transport_result deferred reconciliation_unavailable "$TRANSPORT_REQUEST_ID" '{}';
    else transition_outbox refused; transport_result deferred no_token "$TRANSPORT_REQUEST_ID" '{}'; fi
    exit 0;;
  *)
    if [ "$TRANSPORT_OPERATION" = reconcile_send ]; then transport_result deferred reconciliation_unavailable "$TRANSPORT_REQUEST_ID" '{}';
    else transition_outbox refused; transport_result deferred operation_unavailable "$TRANSPORT_REQUEST_ID" '{}'; fi
    exit 0;;
esac
adapter_code=0
result=$("$adapter" --request "$TRANSPORT_REQUEST_FILE") || adapter_code=$?
[ "$adapter_code" -eq 0 ] || { printf '%s\n' "$result"; exit "$adapter_code"; }
status=$(printf '%s' "$result" | jq -r .status); reason=$(printf '%s' "$result" | jq -r .reason)
# A WRITE leaves the preferred route only on a failure `qfs_fallback_class` admits — that
# function is the one derivation, and naming its classes over again here is exactly what let
# this comment drift out of step with the guard on the next line. What the comment is FOR is the
# distinction it draws: every class that function admits failed BEFORE the provider was asked to
# commit, so the outbox stays `sending`, nothing was accepted, and the fallback is a first
# attempt rather than a resend.
if [ "$status" != ok ] && [ "$route" = qfs ] && [ "$(qfs_fallback_class "$reason")" != none ]; then
  fallback=$(next_route)
  if [ -n "$fallback" ] && [ "$fallback" != qfs ]; then
    DEGRADED_FROM=qfs; DEGRADATION_REASON=$reason; route=$fallback
    if [ "$route" = connector ]; then connector_handoff; exit 0; fi
    select_adapter "$route"
    if [ -n "$adapter" ]; then
      adapter_code=0
      result=$("$adapter" --request "$TRANSPORT_REQUEST_FILE") || adapter_code=$?
      [ "$adapter_code" -eq 0 ] || { printf '%s\n' "$result"; exit "$adapter_code"; }
      status=$(printf '%s' "$result" | jq -r .status); reason=$(printf '%s' "$result" | jq -r .reason)
    fi
  fi
fi
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
elif [ "$reason" = accepted_send_timeout ] || [ "$reason" = provider_timeout ] || [ "$reason" = qfs_connector_failure ] || [ "$reason" = qfs_receipt_unavailable ]; then transition_outbox unknown
else transition_outbox refused
fi
decorate "$result" "$route"
