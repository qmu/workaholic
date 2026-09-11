#!/bin/sh -eu
# Persist every observed message before advancing the binding cursor.
# Usage: capture-inbox.sh --request FILE
#
# The request may carry `window_since` (a number, or null for an unbounded read): the lower
# bound the proved read actually asked for. This is the ONE place `unproved_since` is cleared
# -- in the same revision-checked write that advances the cursor, and only when that window
# reached the mark (`window_since` null or <= `unproved_since`). A request without the key
# (a thread capture) carries the mark forward untouched. Two writers of one record would race.
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
[ "${1:-}" = --request ] || { printf '{"status":"error","reason":"request_required"}\n'; exit 2; }
REQ=${2:-}; jq -e '(.repo_root|type=="string") and (.binding_id|type=="string") and (.messages|type=="array") and has("next_cursor") and (.now|type=="string")' "$REQ" >/dev/null 2>&1 || { printf '{"status":"error","reason":"invalid_request"}\n'; exit 2; }
repo=$(jq -r .repo_root "$REQ"); binding=$(jq -r .binding_id "$REQ"); now=$(jq -r .now "$REQ"); STATE="$SCRIPT_DIR/../../runtime/scripts/state.sh"
call() { (cd "$repo" && sh "$STATE" "$@"); }
meta=$(call read --scope binding --id "$binding"); [ "$(printf '%s' "$meta" | jq -r '.data.found')" = true ] || { printf '{"status":"deferred","reason":"binding_missing"}\n'; exit 0; }
record=$(printf '%s' "$meta" | jq -c .data.record); owner=$(printf '%s' "$record" | jq -c .owner); generation=$(printf '%s' "$record" | jq -r .generation)
tmp=$(mktemp -d); LEASE_HELD=false; lease_revision=0
cleanup_capture() {
  if [ "$LEASE_HELD" = true ]; then
    jq -cn --arg now "$now" --argjson owner "$owner" --argjson generation "$generation" '{updated_at:$now,event:"release",owner:$owner,generation:$generation}' >"$tmp/release.json" 2>/dev/null || true
    call transition --scope binding --id "$binding" --expected-revision "$lease_revision" --input "$tmp/release.json" >/dev/null 2>&1 || true
  fi
  rm -rf "$tmp"
}
trap cleanup_capture EXIT HUP INT TERM
if [ "$owner" = null ]; then
  boot=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || printf unknown); start=$(awk '{print $22}' "/proc/$$/stat" 2>/dev/null || printf unknown)
  nonce=$(printf '%s' "$binding:$$:$start" | sha256sum | cut -c1-24)
  owner=$(jq -cn --arg i "capture-$binding" --arg n "$nonce" --argjson p "$$" --arg b "$boot" --arg s "$start" '{instance_id:$i,nonce:$n,process_id:$p,boot_id:$b,process_start:$s}')
  rev=$(printf '%s' "$record" | jq -r .revision)
  jq -cn --arg now "$now" --argjson owner "$owner" '{updated_at:$now,event:"acquire",owner:$owner}' >"$tmp/acquire.json"
  acquired=$(call transition --scope binding --id "$binding" --expected-revision "$rev" --input "$tmp/acquire.json")
  [ "$(printf '%s' "$acquired" | jq -r .status)" = ok ] || { printf '{"status":"deferred","reason":"binding_busy"}\n'; exit 0; }
  record=$(printf '%s' "$acquired" | jq -c .data.record); generation=$(printf '%s' "$record" | jq -r .generation); lease_revision=$(printf '%s' "$record" | jq -r .revision); LEASE_HELD=true
fi
captured=0
new_ids="$tmp/new-ids"; duplicate_ids="$tmp/duplicate-ids"; : >"$new_ids"; : >"$duplicate_ids"
jq -c '.messages[]' "$REQ" | while IFS= read -r message; do
  provider_id=$(printf '%s' "$message" | jq -jr '.id // .ts // empty')
  [ -n "$provider_id" ] || exit 9
  id=$(printf '%s' "$provider_id" | sha256sum | cut -d' ' -f1)
  jq -cn --arg now "$now" --arg provider_id "$provider_id" --argjson owner "$owner" --argjson generation "$generation" --argjson message "$message" '{updated_at:$now,owner:$owner,generation:$generation,data:{state:"captured",provider_id:$provider_id,message:$message}}' > "$tmp/inbox.json"
  result=$(call create --scope binding --id "$binding" --record "inbox/$id" --input "$tmp/inbox.json")
  status=$(printf '%s' "$result" | jq -r .status); reason=$(printf '%s' "$result" | jq -r .reason)
  if [ "$status" != ok ]; then
    [ "$reason" = revision_conflict ] || exit 10
    existing=$(call read --scope binding --id "$binding" --record "inbox/$id")
    printf '%s' "$existing" | jq -e --arg provider_id "$provider_id" --argjson message "$message" \
      '.status=="ok" and .data.found==true and .data.record.data.provider_id==$provider_id and .data.record.data.message==$message' >/dev/null 2>&1 || exit 10
    printf '%s\n' "$provider_id" >>"$duplicate_ids"
  else
    printf '%s\n' "$provider_id" >>"$new_ids"
  fi
done
pipe_status=$?; [ "$pipe_status" -eq 0 ] || { printf '{"status":"deferred","reason":"capture_incomplete"}\n'; exit 0; }
rev=$(printf '%s' "$record" | jq -r .revision)
cleared=$(printf '%s' "$record" | jq -c --slurpfile req "$REQ" '
  (.data.unproved_since // null) as $mark |
  if ($req[0] | has("window_since")) and $mark != null and ($req[0].window_since == null or $req[0].window_since <= $mark)
  then $mark else null end')
data=$(printf '%s' "$record" | jq -c --argjson cursor "$(jq -c .next_cursor "$REQ")" --argjson cleared "$cleared" \
  '.data + {cursor:$cursor} | if $cleared != null then del(.unproved_since) else . end')
jq -cn --arg now "$now" --argjson data "$data" '{updated_at:$now,data:$data}' > "$tmp/meta.json"
updated=$(call update --scope binding --id "$binding" --expected-revision "$rev" --input "$tmp/meta.json")
[ "$(printf '%s' "$updated" | jq -r .status)" = ok ] || { printf '{"status":"deferred","reason":"cursor_conflict"}\n'; exit 0; }
lease_revision=$(printf '%s' "$updated" | jq -r .data.record.revision)
count=$(jq '.messages|length' "$REQ")
jq -cn --argjson count "$count" --argjson cursor "$(jq -c .next_cursor "$REQ")" --argjson cleared "$cleared" \
  --argjson new "$(jq -Rsc 'split("\n")|map(select(length>0))' "$new_ids")" \
  --argjson duplicates "$(jq -Rsc 'split("\n")|map(select(length>0))' "$duplicate_ids")" \
  '{status:"ok",reason:"",data:{captured:$count,new_input_ids:$new,duplicate_input_ids:$duplicates,cursor:$cursor,cleared_unproved_since:$cleared}}'
