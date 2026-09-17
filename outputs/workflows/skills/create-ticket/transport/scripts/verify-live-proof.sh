#!/bin/sh -eu
# Validate the end-to-end proof required before Slack delivery incidents may close.
# Usage: verify-live-proof.sh --root REPO [--evidence FILE]

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
ROOT=''; EVIDENCE=''
while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT=${2:-}; shift 2 ;;
    --evidence) EVIDENCE=${2:-}; shift 2 ;;
    *) printf '{"ok":false,"closure_eligible":false,"reason":"invalid_argument"}\n'; exit 2 ;;
  esac
done
[ -n "$ROOT" ] || { printf '{"ok":false,"closure_eligible":false,"reason":"root_required"}\n'; exit 2; }

decl=$(sh "$SCRIPT_DIR/read-declared-binding.sh" --root "$ROOT" 2>/dev/null || true)
printf '%s' "$decl" | jq -e '.ok == true and .declared == true' >/dev/null 2>&1 \
  || { printf '{"ok":false,"closure_eligible":false,"reason":"binding_unreadable","incidents_unresolved":11}\n'; exit 0; }

sender=$(printf '%s' "$decl" | jq -r '.binding.sender_id // empty')
required=$(printf '%s' "$decl" | jq -c '.binding.operations // []')
digest=$(printf '%s' "$decl" | jq -r '.declared_digest')
workspace=$(printf '%s' "$decl" | jq -r '.binding.workspace')
channel=$(printf '%s' "$decl" | jq -r '.binding.channel')

if [ -z "$EVIDENCE" ]; then
  missing_sender=false; [ -n "$sender" ] || missing_sender=true
  jq -cn --arg digest "$digest" --arg workspace "$workspace" --arg channel "$channel" \
    --argjson required "$required" --argjson missing_sender "$missing_sender" \
    '{ok:true,closure_eligible:false,reason:(if $missing_sender then "unverifiable_sender" else "live_evidence_required" end),declared_digest:$digest,target:{workspace:$workspace,channel:$channel},required_operations:$required,missing_sender:$missing_sender,incidents_unresolved:11}'
  exit 0
fi

[ -s "$EVIDENCE" ] && jq -e . "$EVIDENCE" >/dev/null 2>&1 \
  || { printf '{"ok":false,"closure_eligible":false,"reason":"evidence_unreadable","incidents_unresolved":11}\n'; exit 0; }

jq -c --arg digest "$digest" --arg workspace "$workspace" --arg channel "$channel" \
  --arg sender "$sender" --argjson required "$required" '
  . as $e |
  [$required[] | select(($e.operations[.]?.proved // false) != true)] as $missing |
  (($sender != "") and ($e.sender_id // "") == $sender) as $sender_ok |
  (($e.declared_digest // "") == $digest and ($e.workspace // "") == $workspace and
   ($e.channel // "") == $channel) as $binding_ok |
  ((.round_trip.root_ts // "") != "" and (.round_trip.reply_ts // "") != "" and
   (.round_trip.reaction_seen // false) == true and
   (.round_trip.channel_delta_seen // false) == true and
   (.round_trip.thread_change_seen // false) == true and
   (.round_trip.thread_reply_seen // false) == true) as $round_trip_ok |
  {ok:true,closure_eligible:($binding_ok and $sender_ok and ($missing|length)==0 and $round_trip_ok),
   reason:(if ($sender == "") then "unverifiable_sender" elif ($binding_ok|not) then "binding_mismatch" elif ($sender_ok|not) then "sender_unverified" elif ($missing|length)>0 then "operations_unsatisfied" elif ($round_trip_ok|not) then "round_trip_unproved" else "" end),
   declared_digest:$digest,target:{workspace:$workspace,channel:$channel},sender_verified:$sender_ok,
   missing_operations:$missing,round_trip_verified:$round_trip_ok,
   incidents_unresolved:(if ($binding_ok and $sender_ok and ($missing|length)==0 and $round_trip_ok) then 0 else 11 end)}
' "$EVIDENCE"
