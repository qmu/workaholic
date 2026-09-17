#!/bin/sh -eu
# Persist every observed message before advancing the binding cursor.
# Usage: capture-inbox.sh --request FILE
#
# The request may carry `window_since` (a number, or null for an unbounded read): the lower
# bound the proved read actually asked for. This is the ONE place `unproved_since` is cleared
# -- in the same revision-checked write that advances the cursor, and only when that window
# reached the mark (`window_since` null or <= `unproved_since`). A request without the key
# (a thread capture) carries the mark forward untouched. Two writers of one record would race.
#
# ---- THE DUPLICATE KEY (2026-09-18, ticket 20260918055010) --------------------------------
# The dedup is PROVIDER-ID KEYED, and the key is `provider_id` + the message's SENDER. It is
# declared here rather than derived by subtraction, because a record written under an older
# adapter's field set must still be readable: each term is read with a normalising default, so
# a term neither side carries reduces to null on both.
#
# WHAT IDENTIFIES A MESSAGE: `provider_id` (Slack's `ts`, unique per channel, and already this
# record's own key) and `sender_id // user` (who spoke; `qfs-native.sh` sets `sender_id` from
# `.user`, `qfs.sh` selects it directly, so every route that has ever fed this seam carries one).
#
# WHAT IS A RENDERING AND IS NOT COMPARED, each with its reason:
#   `thread_ts` -- PER-OPERATION. Measured 2026-09-18: one `thread_broadcast` message read
#     through `read_thread` carries the root's ts and read through `read_channel_delta` carries
#     `null`. The whole-object test this replaces therefore refused a message it had already
#     captured correctly, and refused it on every tick.
#   `user`, `subtype`, `edited_at` -- PER-ROUTE. `qfs-native.sh` selects `user`/`subtype` and
#     `qfs.sh` selects `edited_at`, so a record captured through one route never matched the
#     other's read of the same message.
#   `text` -- MUTABLE CONTENT. An edit changes what a message says, not which message it is
#     (`qfs.sh` selects `edited_at` for exactly that reason). COST, STATED: the inbox keeps the
#     text as first observed, which is right for an ARRIVAL record and is why an edited message
#     no longer stalls the cursor.
#
# The direction of the remaining error is chosen deliberately. Too NARROW a key drops a
# genuinely different message under a reused provider id; too WIDE a key stalls the cursor
# forever on a re-read. Slack does not reuse `ts` within a channel and this record is scoped to
# one binding, so the narrow error is unreachable in practice while the wide one was measured
# hourly. A sender that does not match is still refused, by name.
#
# AND THE REFUSAL IS REACHABLE. Every failing branch below writes its cause to a file and leaves
# the loop with status 0: the loop runs in a pipeline subshell, so an `exit 9`/`exit 10` there
# made the PIPELINE fail, and under `sh -eu` that aborted the script before it could print
# anything. Measured: the consumer saw empty output and substituted `capture_unreadable` for a
# cause the capture knew. A capture that cannot complete now prints `status: deferred`,
# `reason: capture_incomplete`, and `data` naming the cause and the offending provider id, on
# stdout with exit 0.
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
new_ids="$tmp/new-ids"; duplicate_ids="$tmp/duplicate-ids"; incomplete="$tmp/incomplete"
: >"$new_ids"; : >"$duplicate_ids"; : >"$incomplete"
# `$incomplete` carries the cause OUT of the pipeline subshell, and every branch below leaves the
# loop with status 0 so `sh -eu` cannot abort before the refusal is printed. `|| walk_status=$?`
# closes the rest of the class: a command inside the loop that fails for a reason no branch
# names -- a broken `jq`, no `sha256sum` -- is a typed refusal with the cursor held rather than an
# abort. It must never be `|| true`, which would advance the cursor over a walk that stopped.
walk_status=0
jq -c '.messages[]' "$REQ" | while IFS= read -r message; do
  provider_id=$(printf '%s' "$message" | jq -jr '.id // .ts // empty')
  if [ -z "$provider_id" ]; then
    jq -cn '{cause:"message_without_provider_id",provider_id:null}' >"$incomplete"; exit 0
  fi
  id=$(printf '%s' "$provider_id" | sha256sum | cut -d' ' -f1)
  jq -cn --arg now "$now" --arg provider_id "$provider_id" --argjson owner "$owner" --argjson generation "$generation" --argjson message "$message" '{updated_at:$now,owner:$owner,generation:$generation,data:{state:"captured",provider_id:$provider_id,message:$message}}' > "$tmp/inbox.json"
  result=$(call create --scope binding --id "$binding" --record "inbox/$id" --input "$tmp/inbox.json" 2>/dev/null || printf '')
  if ! printf '%s' "$result" | jq -e 'has("status")' >/dev/null 2>&1; then
    jq -cn --arg pid "$provider_id" '{cause:"record_write_unreadable",provider_id:$pid}' >"$incomplete"; exit 0
  fi
  status=$(printf '%s' "$result" | jq -r .status); reason=$(printf '%s' "$result" | jq -r '.reason // ""')
  if [ "$status" != ok ]; then
    if [ "$reason" != revision_conflict ]; then
      jq -cn --arg pid "$provider_id" --arg r "$reason" '{cause:("record_write_failed:"+$r),provider_id:$pid}' >"$incomplete"; exit 0
    fi
    existing=$(call read --scope binding --id "$binding" --record "inbox/$id" 2>/dev/null || printf '')
    if ! printf '%s' "$existing" | jq -e '.status=="ok" and .data.found==true' >/dev/null 2>&1; then
      jq -cn --arg pid "$provider_id" '{cause:"stored_record_unreadable",provider_id:$pid}' >"$incomplete"; exit 0
    fi
    # The declared key, and nothing else: `provider_id` plus the sender. `//` is safe on both
    # terms because each is a string or null and never `false`.
    if ! printf '%s' "$existing" | jq -e --arg provider_id "$provider_id" --argjson message "$message" \
      '(.data.record.data.provider_id == $provider_id)
       and (((.data.record.data.message // {}) | (.sender_id // .user // null))
            == ($message | (.sender_id // .user // null)))' >/dev/null 2>&1; then
      jq -cn --arg pid "$provider_id" '{cause:"stored_message_key_mismatch",provider_id:$pid}' >"$incomplete"; exit 0
    fi
    printf '%s\n' "$provider_id" >>"$duplicate_ids"
  else
    printf '%s\n' "$provider_id" >>"$new_ids"
  fi
done || walk_status=$?
if [ -s "$incomplete" ]; then
  jq -cn --slurpfile detail "$incomplete" '{status:"deferred",reason:"capture_incomplete",data:$detail[0]}'
  exit 0
fi
if [ "$walk_status" -ne 0 ]; then
  jq -cn --arg s "$walk_status" '{status:"deferred",reason:"capture_incomplete",data:{cause:("capture_walk_failed:"+$s),provider_id:null}}'
  exit 0
fi
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
