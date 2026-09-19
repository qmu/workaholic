#!/bin/sh -eu
# Is EVERY accepted request from one human thread in, verified and delivered?
#
# WHY IT EXISTS (2026-09-19, ticket `20260919100142`, issue #1146). A completion mention went
# out when one unit merged while sorting, pagination, forms and identifiers from the same
# continuing thread were still queued. Most of the reconciliation already existed and the gap
# was the GRAIN: `feedback-outcome.sh` answers one state per FEEDBACK ITEM, and
# `delivery-ledger.sh` folds one item's PULL REQUESTS with `every`. Both fold WITHIN one item.
# Nothing folded ACROSS the items of one human thread, which is the unit a person means by
# *done*.
#
# WHAT IT DOES NOT DO: re-derive an item's state. `feedback-outcome.sh` stays the one
# derivation of that question and `delivery-ledger.sh` stays the one fold over an item's pull
# requests; this script CALLS the ledger once with the whole set and folds its rows. Every
# per-item word it reports -- `state`, `missing`, `delivered` -- is passed through VERBATIM.
#
# THE ACCEPTED SET, stated so the boundary is arguable rather than implied.
#
#   IN   every request captured from one human thread and from the continuations that thread
#        explicitly links, each with its own feedback item, whatever its state.
#   OUT  a request captured from ANOTHER thread -- the key is a coordinate, and a coordinate
#        from elsewhere is a different set, including one from another repository.
#   OUT  a request a person EXPLICITLY deferred or cancelled (`human_scope`), named in
#        `excluded[]` so the narrowing is visible rather than silent.
#
# ONLY AN EXPLICIT HUMAN DEFER OR CANCEL NARROWS THE SET. A worker's judgement that a request
# is obsolete, a merged pull request, a closed issue and this run's own reading never do. The
# rule is stated once in `workaholic:notify`, *Three acts: a worker receipt, scoped progress,
# and a completion mention*, and cited here rather than restated; `human_scope` carries only
# what that rule admits, and any other value (including an absent one) leaves the item IN.
#
# THE KEY IS THE THREAD'S OWN COORDINATE AND NEEDS NO NEW RELATION OR FIELD. `thread_key` is
# `<channel>:<thread-root ts>` -- the shape `file-inbound-ask.sh` already stamps as
# `slack-ref:` and `list-unannounced-closed-asks.sh` already returns as `slack_ref`. A root
# message's own coordinate IS its thread key (Slack gives a root `thread_ts == ts`), so for
# the ordinary ask the stamped marker is the key unchanged; a request written as a reply
# carries its root's coordinate, which the observation already knows. This script resolves
# NOTHING from Slack and reads no channel: it groups on the key the caller hands it.
#
# NEVER A SIMILARITY, RECENCY OR TITLE MATCH. Grouping is exact string equality on the
# coordinate, which is the standing prohibition `workaholic:notify` places on every
# notification path -- a guess here is a completion mention about the wrong conversation.
#
# AN ITEM WITH NO THREAD KEY IS ITS OWN ANSWER, never a silent drop and never folded into some
# other thread: it is named in `keyless[]` with `thread_key_unresolvable`, the shape
# `list-unannounced-closed-asks.sh` already uses for its mirror case (`stems_unresolvable`).
#
# UNREADABLE WITHHOLDS, AND THE ASYMMETRY IS THE POINT. A set whose membership could not be
# established (`membership_readable: false`), or any member whose own state is unreadable,
# answers `unreadable` with NULL counts and never `complete`. Issue #1132 records that thread
# discovery can be incomplete, and this repository's standing rule is that an absence of a
# reading is never a proof: INCOMPLETE DISCOVERY IS NEVER EVIDENCE OF COMPLETENESS. The
# converse -- completing a set because nothing said otherwise -- is exactly the failure
# measured above, so the direction is deliberately not symmetric.
#
# ONE SEAM CONSUMES THE VERDICT: `/infinite-development`'s *Announce landed asks*, which may
# compose a completion mention only on `complete`. Every other verdict takes the scoped
# progress path. Do not add a second call site.
#
# Usage: thread-completion.sh --input FILE
# Input:  {items:[{thread_key, human_scope?, membership_readable?, …delivery-ledger item…}]}
# Output: one runtime result, data =
#   {threads:[{thread_key, verdict, reason, total, delivered, members:[…],
#              holding:[{feedback,held_by}], excluded:[{feedback,scope}]}],
#    keyless:[{feedback, reason}], complete, incomplete, unreadable}
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/../../runtime/scripts/lib/result.sh"
[ "$#" -eq 2 ] && [ "$1" = --input ] || runtime_usage "usage: thread-completion.sh --input FILE"
runtime_require_json_file "$2"
jq -e '(.items|type)=="array"' "$2" >/dev/null 2>&1 || runtime_usage "items required"

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT HUP INT TERM

# The ledger is called with the WHOLE set in one call, so its own composition of
# `feedback-outcome.sh` stays one call too and every item's state is derived exactly once.
# `thread_key`, `human_scope` and `membership_readable` are this script's own fields and are
# not forwarded: the ledger has no use for them and a reader that ignores a field it is handed
# is a reader whose input shape nobody can check.
jq -c '{items:[.items[] | del(.thread_key, .human_scope, .membership_readable)]}' "$2" \
    >"$tmp/ledger-input.json" 2>/dev/null || runtime_usage "invalid thread input"

ledger=$(sh "$SCRIPT_DIR/delivery-ledger.sh" --input "$tmp/ledger-input.json" 2>/dev/null || printf '')
printf '%s' "$ledger" | jq -e '(.data.ledger|type) == "array"' >/dev/null 2>&1 \
    || runtime_usage "delivery ledger refused"
printf '%s' "$ledger" | jq -c '.data.ledger' >"$tmp/ledger.json"

jq -c --slurpfile ledger "$tmp/ledger.json" '
  ($ledger[0] // []) as $rows |
  # `has`, never `// true`: `rules/shell.md`, *`//` is not a default when `false` is a real
  # answer*. An explicit `membership_readable: false` must not read as *nobody said*.
  [.items[] | . as $i |
    ($rows[] | select(.feedback == $i.feedback)) as $r |
    {feedback:$i.feedback,
     thread_key:(($i.thread_key // "") | if type == "string" then . else "" end),
     scope:(($i.human_scope // "") | if type == "string" then . else "" end),
     membership_readable:(if ($i | has("membership_readable")) then ($i.membership_readable != false) else true end),
     state:($r.state // "unreadable"),
     missing:($r.missing // "unreadable"),
     delivered:($r.delivered == true),
     row_readable:(($r | type) == "object" and ($r.readable != false))}] as $members |

  # A request a person explicitly deferred or cancelled leaves the set, and NOTHING ELSE does.
  ([$members[] | select(.thread_key != "") |
    . + {excluded:(.scope == "deferred" or .scope == "cancelled"),
         # The state that HOLDS this member, in the words the readers already emit: the
         # implementation state when that is short, otherwise the first absent stage.
         held_by:(if .state != "implemented_and_verified" then .state
                  elif .missing != "" then ("missing:" + .missing)
                  else "" end)}]) as $keyed |

  ([$members[] | select(.thread_key == "") |
    {feedback:.feedback, reason:"thread_key_unresolvable"}]) as $keyless |

  ([$keyed | group_by(.thread_key)[] | . as $g |
    ([$g[] | select(.excluded | not)]) as $acc |
    (($g | any((.membership_readable | not))) or ($acc | any(.row_readable | not)) or
     ($acc | any(.state == "unreadable"))) as $unreadable |
    (if ($g | any((.membership_readable | not))) then "membership_unreadable"
     elif $unreadable then "member_unreadable"
     elif ($acc | length) == 0 then "no_accepted_members"
     elif ($acc | all(.delivered)) then ""
     else "member_not_delivered" end) as $reason |
    {thread_key:$g[0].thread_key,
     verdict:(if $unreadable then "unreadable"
              elif ($acc | length) > 0 and ($acc | all(.delivered)) then "complete"
              else "incomplete" end),
     reason:$reason,
     # NULL counts on an unreadable reading, never 0: `0` reads as *counted, found none*.
     total:(if $unreadable then null else ($acc | length) end),
     delivered:(if $unreadable then null else ([$acc[] | select(.delivered)] | length) end),
     members:[$g[] | {feedback, state, missing, delivered, held_by,
                      excluded, readable:(.membership_readable and .row_readable)}],
     holding:[$acc[] | select(.delivered | not) | {feedback, held_by:(if .held_by == "" then "unreadable" else .held_by end)}],
     excluded:[$g[] | select(.excluded) | {feedback, scope}]}]) as $threads |

  {threads:$threads, keyless:$keyless,
   complete:([$threads[] | select(.verdict == "complete")] | length),
   incomplete:([$threads[] | select(.verdict == "incomplete")] | length),
   unreadable:([$threads[] | select(.verdict == "unreadable")] | length)}
' "$2" >"$tmp/threads.json" 2>/dev/null || runtime_usage "invalid thread reading"

runtime_json_result ok "" thread-completion "$(cat "$tmp/threads.json")"
