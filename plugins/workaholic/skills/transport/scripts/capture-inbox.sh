#!/bin/sh -eu
# Persist every observed message before advancing the binding cursor.
# Usage: capture-inbox.sh --request FILE
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
[ "${1:-}" = --request ] || { printf '{"status":"error","reason":"request_required"}\n'; exit 2; }
REQ=${2:-}; jq -e '(.repo_root|type=="string") and (.binding_id|type=="string") and (.messages|type=="array") and has("next_cursor") and (.now|type=="string")' "$REQ" >/dev/null 2>&1 || { printf '{"status":"error","reason":"invalid_request"}\n'; exit 2; }
repo=$(jq -r .repo_root "$REQ"); binding=$(jq -r .binding_id "$REQ"); now=$(jq -r .now "$REQ"); STATE="$SCRIPT_DIR/../../runtime/scripts/state.sh"
call() { (cd "$repo" && sh "$STATE" "$@"); }
meta=$(call read --scope binding --id "$binding"); [ "$(printf '%s' "$meta" | jq -r '.data.found')" = true ] || { printf '{"status":"deferred","reason":"binding_missing"}\n'; exit 0; }
record=$(printf '%s' "$meta" | jq -c .data.record); owner=$(printf '%s' "$record" | jq -c .owner); generation=$(printf '%s' "$record" | jq -r .generation)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT HUP INT TERM
captured=0
jq -c '.messages[]' "$REQ" | while IFS= read -r message; do
  id=$(printf '%s' "$message" | jq -jr '.id // .ts // empty' | tr -c 'A-Za-z0-9._-' '-')
  [ -n "$id" ] || exit 9
  jq -cn --arg now "$now" --argjson owner "$owner" --argjson generation "$generation" --argjson message "$message" '{updated_at:$now,owner:$owner,generation:$generation,data:{state:"captured",message:$message}}' > "$tmp/inbox.json"
  result=$(call create --scope binding --id "$binding" --record "inbox/$id" --input "$tmp/inbox.json")
  status=$(printf '%s' "$result" | jq -r .status); reason=$(printf '%s' "$result" | jq -r .reason)
  [ "$status" = ok ] || [ "$reason" = revision_conflict ] || exit 10
done
pipe_status=$?; [ "$pipe_status" -eq 0 ] || { printf '{"status":"deferred","reason":"capture_incomplete"}\n'; exit 0; }
rev=$(printf '%s' "$record" | jq -r .revision); data=$(printf '%s' "$record" | jq -c --argjson cursor "$(jq -c .next_cursor "$REQ")" '.data + {cursor:$cursor}')
jq -cn --arg now "$now" --argjson data "$data" '{updated_at:$now,data:$data}' > "$tmp/meta.json"
updated=$(call update --scope binding --id "$binding" --expected-revision "$rev" --input "$tmp/meta.json")
[ "$(printf '%s' "$updated" | jq -r .status)" = ok ] || { printf '{"status":"deferred","reason":"cursor_conflict"}\n'; exit 0; }
count=$(jq '.messages|length' "$REQ"); jq -cn --argjson count "$count" --argjson cursor "$(jq -c .next_cursor "$REQ")" '{status:"ok",reason:"",data:{captured:$count,cursor:$cursor}}'
