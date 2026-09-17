#!/bin/sh -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/result.sh"
transport_parse_request_arg "$@"
[ "$TRANSPORT_OPERATION" = discover ] || transport_usage "resolve-target requires discover"

# Discovery observations are supplied by the caller that actually described its
# connector/QFS maps. A public listing miss is deliberately not negative proof.
jq -e '(.input.target|type=="object") and (.input.target.channel|type=="string" and length>0) and (.input.observations|type=="array")' "$TRANSPORT_REQUEST_FILE" >/dev/null 2>&1 \
  || transport_usage "discover requires target.channel and observations"

resolution=$(jq -c '
  .input as $in | $in.target as $t |
  [$in.observations[] |
    select(.available==true) |
    select((.workspace // null) == ($t.workspace // null) or (($t.workspace // null)==null)) |
    select((.channel==$t.channel) or (.channel_id==$t.channel)) |
    select((($t.account // null)==null) or .account==$t.account) |
    select((($t.sender_id // null)==null) or .sender_id==$t.sender_id) |
    select((($t.mount // null)==null) or .mount==$t.mount)] as $matches |
  {matches:$matches,
   workspaces:([$matches[].workspace // empty]|unique),
   public_misses:[$in.observations[]|select(.visibility=="public_miss")],
   sender_blind:[$in.observations[] |
     select(.available==true) |
     select((.workspace // null) == ($t.workspace // null) or (($t.workspace // null)==null)) |
     select((.channel==$t.channel) or (.channel_id==$t.channel)) |
     select((($t.account // null)==null) or .account==$t.account) |
     select((($t.mount // null)==null) or .mount==$t.mount)]}
' "$TRANSPORT_REQUEST_FILE")
count=$(printf '%s' "$resolution" | jq '.matches|length')
workspaces=$(printf '%s' "$resolution" | jq '.workspaces|length')
if [ "$count" -eq 0 ]; then
    # A DECLARED sender that no described route can prove is not "nothing reaches this channel".
    # A route does reach it and cannot prove who would speak, which is a different fact needing a
    # different fix, and it is refused WITHOUT the caller opting in: the seam below served only a
    # caller that asked, so the loop's own write path never reached it and a fallback then posted
    # under whatever identity it carried. `target_unverified` keeps its meaning exactly.
    if [ -n "$(jq -r '.input.target.sender_id // empty' "$TRANSPORT_REQUEST_FILE")" ] &&
       [ "$(printf '%s' "$resolution" | jq '.sender_blind|length')" -gt 0 ]; then
        transport_result deferred sender_unverified "$TRANSPORT_REQUEST_ID" \
          "$(printf '%s' "$resolution" | jq -c --arg expected "$(jq -r '.input.target.sender_id' "$TRANSPORT_REQUEST_FILE")" \
             '{expected_sender_id:$expected,accounts:([.sender_blind[].account//null]|unique),
               offered_sender_ids:([.sender_blind[].sender_id//null]|unique)}')"
        exit 0
    fi
    transport_result deferred target_unverified "$TRANSPORT_REQUEST_ID" "$(printf '%s' "$resolution" | jq '{public_misses:(.public_misses|length)}')"
    exit 0
fi
if [ "$workspaces" -gt 1 ]; then
    transport_result deferred ambiguous_target "$TRANSPORT_REQUEST_ID" "$(printf '%s' "$resolution" | jq '{workspaces}')"
    exit 0
fi

# Required operations are part of the binding, not a preference applied afterwards. A route
# that reaches the right channel in the right workspace and cannot perform what the operator
# declared is a DIFFERENT route, and saying so here is what stops a loop from resolving a
# read-only mount and discovering at post time that it can never speak. Narrowing runs after
# the two ambiguity checks so `target_unverified` still means "nothing reaches this channel".
required=$(jq -c '.input.target.operations // []' "$TRANSPORT_REQUEST_FILE")
if [ "$(printf '%s' "$required" | jq 'length')" -gt 0 ]; then
    narrowed=$(printf '%s' "$resolution" | jq -c --argjson required "$required" '
      .matches = [.matches[] | . as $m | select([$required[] | . as $op | select((($m.operations // []) | index($op)) == null)] | length == 0)]
      | .workspaces = ([.matches[].workspace // empty] | unique)')
    if [ "$(printf '%s' "$narrowed" | jq '.matches|length')" -eq 0 ]; then
        transport_result deferred operations_unsatisfied "$TRANSPORT_REQUEST_ID" \
          "$(printf '%s' "$resolution" | jq -c --argjson required "$required" '{required:$required, offered:([.matches[].operations[]?]|unique)}')"
        exit 0
    fi
    resolution=$narrowed
fi
# A display label and workspace do not identify the account that will speak.
# More than one described account/sender tuple is therefore an ambiguity, even
# when every route reaches a channel with the same name.
identities=$(printf '%s' "$resolution" | jq '[.matches[]|[(.account//""),(.sender_id//"")]|@tsv]|unique|length')
if [ "$identities" -gt 1 ]; then
    transport_result deferred ambiguous_identity "$TRANSPORT_REQUEST_ID" "$(printf '%s' "$resolution" | jq '{identities:[.matches[]|{account:(.account//null),sender_id:(.sender_id//null)}]|unique}')"
    exit 0
fi

# A declared sender that no described route can prove is a REFUSAL, not a warning, when the
# caller asked for one: `account` is an operator-facing profile label and Slack never connects
# it to the identity that will speak, so accepting it would let a post go out over an account
# nobody verified while the binding claimed the declared one.
if jq -e '.input.target.require_verified_sender == true' "$TRANSPORT_REQUEST_FILE" >/dev/null 2>&1; then
    if [ "$(printf '%s' "$resolution" | jq '[.matches[] | select((.sender_id // "") != "")] | length')" -eq 0 ]; then
        transport_result deferred sender_unverified "$TRANSPORT_REQUEST_ID" \
          "$(printf '%s' "$resolution" | jq -c '{accounts:([.matches[].account//null]|unique)}')"
        exit 0
    fi
fi

canonical=$(printf '%s' "$resolution" | jq -c --argjson digest "$(jq -c '.input.declared_digest // null' "$TRANSPORT_REQUEST_FILE")" '
  .matches | sort_by(if .transport=="qfs" then 0 elif .transport=="connector" then 1 else 2 end) |
  .[0] as $primary |
  {mount:($primary.mount//null),account:($primary.account//null),workspace:$primary.workspace,
   channel:$primary.channel,channel_id:($primary.channel_id//null),sender_id:($primary.sender_id//null),
   channel_verified:($primary.channel_verified//false),
   sender_verified:(($primary.sender_id//"") != ""),
   declared_digest:$digest,
   operations:([.[].operations[]?]|unique),routes:[.[]|{transport,mount:(.mount//null),account:(.account//null),operations:(.operations//[]),sender_id:(.sender_id//null),described:(.described//false)} +
     (if .dialect == "pipe-sql" then {dialect,map_verified,thread_map_verified} else {} end)],
   thread_map:($primary.thread_map//{})}
')
binding_id=$(printf '%s' "$canonical" | sha256sum | cut -c1-32)
data=$(printf '%s' "$canonical" | jq -c --arg id "$binding_id" '{binding_id:$id,binding:.}')
transport_result ok "" "$TRANSPORT_REQUEST_ID" "$data"
