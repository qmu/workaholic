#!/bin/sh -eu
# May a completion mention be composed, given the reread that was just made of its own thread?
#
# WHY IT EXISTS (2026-09-19, ticket `20260919100143`, issue #1146). *Announce landed asks*
# already resolved the exact `fb:<stem>` thread and already read it -- but that read answers
# HAVE WE ALREADY POSTED, not HAS ANYTHING NEW ARRIVED. A request written while the work ran was
# therefore outside the mention's scope, and the person was told the batch was done while their
# newest ask was unseen.
#
# IT IS A PURE READER AND WRITES NO OBSERVATION STATE. The reread itself is
# `transport/scripts/observe-channel.sh` -- the existing bounded thread read, composed and never
# rebuilt -- and the cursor and `unproved_since` stay that script's, written only in its own
# revision-checked update through `transport/scripts/capture-inbox.sh`. A mention-time reread
# NEVER advances the cursor on its own: a second advancing path is a page the next ordinary
# observation skips, which is the one failure worse than the one this repairs. This script
# touches no file, no ref and no transport; it reads the numbers that read already reported.
#
# WITHHOLD ON ANYTHING SHORT OF A COMPLETE READ, and the direction is deliberately asymmetric:
# an absence of a reading is never a proof, so a truncated page, an unproved read, a fanout
# bound reached or an unreadable continuation WITHHOLDS the mention rather than permitting it.
# The terms are `observe-channel.sh`'s own -- `observation_proved`, `observation_settled` and
# `unsettled[]` (`channel_delta_incomplete`, `thread_coverage_partial`, `thread_fanout_truncated`,
# `sender_identity_unverified`) -- passed through VERBATIM, because a normalised word sends a
# reader to a string no script printed.
#
# A NEW REQUEST FOUND IS THE ORDINARY GOOD CASE, NOT AN ERROR PATH. It is captured through the
# one capture, the mention is withheld, and scoped progress goes out instead (`workaholic:notify`,
# *Three acts: a worker receipt, scoped progress, and a completion mention*). `new_request_found`
# is named as its own reason so a reader can tell *the thread moved* from *the read failed*.
#
# A CONTINUATION IS FOLLOWED ONLY WHERE THE THREAD EXPLICITLY LINKS IT -- a link a person wrote.
# Never a similar thread and never a recent one: `workaholic:notify`'s prohibition on similarity
# and recency matching applies in full, and this script does no resolution of its own, so a
# continuation reaches it only because the caller read an explicit link.
#
# NO READ AT ALL IS `no_reread`, never `allow`. A mention composed without a reread is exactly
# the state before this existed.
#
# Usage: mention-reread.sh --input FILE
# Input:  {reads:[{thread_key, role:"thread"|"continuation", observation_proved,
#                  observation_settled, unsettled:[…], new_human_messages, captured,
#                  capture_readable}]}
# Output: one runtime result, data =
#   {verdict:"allow"|"withhold", reason, holds:[{thread_key, role, reason}], reads:<n>}
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/../../runtime/scripts/lib/result.sh"
[ "$#" -eq 2 ] && [ "$1" = --input ] || runtime_usage "usage: mention-reread.sh --input FILE"
runtime_require_json_file "$2"
jq -e '(.reads|type)=="array"' "$2" >/dev/null 2>&1 || runtime_usage "reads required"

# A pure reader writes nothing into the caller's checkout, so the one intermediate lives in a
# temp directory this script removes on every exit path.
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT HUP INT TERM

jq -c '
  # `has` and `!= false`, never `// true`: `rules/shell.md`, *`//` is not a default when `false`
  # is a real answer*. An explicit `observation_proved: false` must never read as *nobody said*,
  # which is the direction that would let an unread thread complete a set.
  [.reads[] | . as $r |
    {thread_key:(($r.thread_key // "") | if type == "string" then . else "" end),
     role:(($r.role // "thread") | if type == "string" then . else "thread" end),
     reason:(
       if ($r.observation_proved != true) then "observation_unreadable"
       elif ($r.observation_settled != true)
         then (($r.unsettled // []) | if (type == "array" and length > 0)
                                      then (.[0] | tostring) else "observation_unsettled" end)
       elif ($r.capture_readable != true) then "capture_unreadable"
       elif (($r.new_human_messages // null) | type) != "number" then "capture_unreadable"
       elif (($r.captured // null) | type) != "number" then "capture_unreadable"
       elif ($r.captured < $r.new_human_messages) then "capture_incomplete"
       # The good case: the thread moved, the new request is filed, and the set re-opens.
       elif ($r.new_human_messages > 0) then "new_request_found"
       else "" end)}] as $rows |
  ([$rows[] | select(.reason != "")]) as $holds |
  {verdict:(if ($rows | length) == 0 then "withhold"
            elif ($holds | length) > 0 then "withhold" else "allow" end),
   reason:(if ($rows | length) == 0 then "no_reread"
           elif ($holds | length) > 0 then $holds[0].reason else "" end),
   holds:$holds,
   reads:($rows | length)}
' "$2" >"$tmp/verdict.json" 2>/dev/null || runtime_usage "invalid reread reading"

runtime_json_result ok "" mention-reread "$(cat "$tmp/verdict.json")"
