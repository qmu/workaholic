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
   public_misses:[$in.observations[]|select(.visibility=="public_miss")]}
' "$TRANSPORT_REQUEST_FILE")
count=$(printf '%s' "$resolution" | jq '.matches|length')
workspaces=$(printf '%s' "$resolution" | jq '.workspaces|length')
if [ "$count" -eq 0 ]; then
    transport_result deferred target_unverified "$TRANSPORT_REQUEST_ID" "$(printf '%s' "$resolution" | jq '{public_misses:(.public_misses|length)}')"
    exit 0
fi
if [ "$workspaces" -gt 1 ]; then
    transport_result deferred ambiguous_target "$TRANSPORT_REQUEST_ID" "$(printf '%s' "$resolution" | jq '{workspaces}')"
    exit 0
fi
# A display label and workspace do not identify the account that will speak.
# More than one described account/sender tuple is therefore an ambiguity, even
# when every route reaches a channel with the same name.
identities=$(printf '%s' "$resolution" | jq '[.matches[]|[(.account//""),(.sender_id//"")]|@tsv]|unique|length')
if [ "$identities" -gt 1 ]; then
    transport_result deferred ambiguous_identity "$TRANSPORT_REQUEST_ID" "$(printf '%s' "$resolution" | jq '{identities:[.matches[]|{account:(.account//null),sender_id:(.sender_id//null)}]|unique}')"
    exit 0
fi

canonical=$(printf '%s' "$resolution" | jq -c '
  .matches | sort_by(if .transport=="qfs" then 0 elif .transport=="connector" then 1 else 2 end) |
  .[0] as $primary |
  {mount:($primary.mount//null),account:($primary.account//null),workspace:$primary.workspace,
   channel:$primary.channel,channel_id:($primary.channel_id//null),sender_id:($primary.sender_id//null),
   operations:([.[].operations[]?]|unique),routes:[.[]|{transport,mount:(.mount//null),account:(.account//null),operations:(.operations//[]),sender_id:(.sender_id//null),described:(.described//false)}],
   thread_map:($primary.thread_map//{})}
')
binding_id=$(printf '%s' "$canonical" | sha256sum | cut -c1-32)
data=$(printf '%s' "$canonical" | jq -c --arg id "$binding_id" '{binding_id:$id,binding:.}')
transport_result ok "" "$TRANSPORT_REQUEST_ID" "$data"
