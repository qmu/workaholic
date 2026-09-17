#!/bin/sh -eu
# What is the delivery state of an ACCEPTED REQUEST whose implementation is spread over several
# pull requests, and which requests are held by one and the same gate?
#
# WHY IT EXISTS (2026-09-17, ticket `20260917122912`). `feedback-outcome.sh` owns *is this one
# feedback item delivered*, and it reads ONE `implementation_pr`. A request answered by three
# pull requests therefore had no reading at all: a caller had to pick one of them, and whichever
# it picked the answer was wrong -- the two it dropped were invisible, so a request with one
# merged part and two open ones read exactly like a finished one. And when those parts were all
# held by the same external gate, each was reported on its own, so the report named the gate as
# many times as there were pull requests and never named the scope it was holding.
#
# WHAT IT DOES NOT DO: re-derive the delivery vocabulary. `feedback-outcome.sh` is called once
# with the whole item set and its `state` / `notification` / `deployment` words are passed through
# VERBATIM -- one derivation of that question, and a word this script spelled itself would drift
# from the one every other consumer reads. What this adds is the arithmetic over the pull-request
# SET and the grouping by blocker, neither of which that reader can see.
#
# A REQUEST IS DELIVERED WHEN EVERY PART OF IT IS. `merged` is folded with `every`, never `any`:
# a conversation is satisfied when the whole of it landed, and *one part merged* is precisely the
# state this reader exists to stop reporting as done. `verified` likewise. PR CREATION IS NOT
# COMPLETION and neither is a merge: the stages are distinct and `missing` names the first one
# that is absent -- `merge`, then `deployment`, then `public_verification` -- so a request whose
# pull requests all merged while the deployment failed reads `deployment`, never delivered.
#
# THE INTEGRATION UNIT IS BOUNDED AND ORDERED. `next[]` offers only the open pull requests whose
# every `depends_on` is already merged, in the order the graph allows, capped by
# `WORKAHOLIC_INTEGRATION_MAX` (default 3). A dependency cycle, or a `depends_on` naming a pull
# request outside the item, is `order_unresolved` with the names: a guessed order is worse than
# no offer, because integrating out of order is what leaves a half-applied change on the base.
#
# ONE GATE IS ONE BLOCKER. `blockers[]` has one entry per distinct blocker word, naming every
# feedback item and pull request it holds, so a shared external gate is reported once with its
# whole affected scope. It is EVIDENCE: nothing here clears a gate, claims it was lifted, merges,
# deploys or verifies anything. `independent[]` names the open pull requests no blocker holds --
# the work that must keep going while the gate stands.
#
# DEGRADATION IS STATED. An item whose queue could not be read keeps `feedback-outcome.sh`'s own
# `unreadable`, and an item carrying no readable pull-request list answers
# `pull_requests_unreadable` with NULL counts and a NULL `next`, never an empty array -- an empty
# array reads as *nothing left to integrate*, which is the opposite.
#
# Usage: delivery-ledger.sh --input FILE
# Input:  {items:[{feedback, expected_surface, verified_surface, evidence[], queue_readable,
#                  queued, deployment, public_verification, thread:{status,complete},
#                  pull_requests:[{number, merged, verified, blocker, depends_on[]}]}]}
# Output: one JSON line, {ledger:[…], blockers:[…], independent:[…]}
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/../../runtime/scripts/lib/result.sh"
[ "$#" -eq 2 ] && [ "$1" = --input ] || runtime_usage "usage: delivery-ledger.sh --input FILE"
runtime_require_json_file "$2"
jq -e '(.items|type)=="array"' "$2" >/dev/null 2>&1 || runtime_usage "items required"

MAX=${WORKAHOLIC_INTEGRATION_MAX:-3}
case "$MAX" in ''|*[!0-9]*|0) MAX=3 ;; esac

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT HUP INT TERM

# Fold each item's pull-request SET into the one `implementation_pr` the delivery reader takes,
# then hand the whole set over in a single call so that reader stays the one derivation.
jq -c '
  {items:[.items[] | . as $i |
    ((.pull_requests // null) | if type == "array" then . else null end) as $prs |
    (if $prs == null then null
     elif ($prs | length) == 0 then false
     else ($prs | all(.merged == true)) end) as $merged |
    (if $prs == null then null
     elif ($prs | length) == 0 then false
     else ($prs | all(.verified == true)) end) as $verified |
    {feedback:.feedback, expected_surface:.expected_surface, verified_surface:.verified_surface,
     evidence:.evidence, deployment:.deployment, thread:.thread,
     # A pull-request list we could not read must not become a readable-but-empty one: it is
     # handed over as an unreadable QUEUE so the delivery reader answers `unreadable` rather
     # than inventing a verdict, and this script names the real reason beside it.
     queue_readable:(if $prs == null then false else .queue_readable end),
     queued:.queued,
     implementation_pr:{merged:($merged // false), verified:($verified // false)}}]}
' "$2" >"$tmp/outcome-input.json" 2>/dev/null || runtime_usage "invalid ledger input"

# `feedback-outcome.sh` answers a BARE `{items:[...]}`, not the runtime envelope -- read it where
# it answers rather than where a sibling script would.
outcome=$(sh "$SCRIPT_DIR/feedback-outcome.sh" --input "$tmp/outcome-input.json" 2>/dev/null || printf '')
printf '%s' "$outcome" | jq -e '(.items|type) == "array"' >/dev/null 2>&1 || runtime_usage "delivery reader refused"
printf '%s' "$outcome" | jq -c '.items' >"$tmp/outcome.json"

jq -c --slurpfile outcome "$tmp/outcome.json" --argjson max "$MAX" '
  ($outcome[0] // []) as $states |
  [.items[] | . as $i |
    ((.pull_requests // null) | if type == "array" then . else null end) as $prs |
    ($states[] | select(.feedback == $i.feedback)) as $s |
    (if $prs == null then null else [$prs[] | select(.merged == true) | .number] end) as $merged |
    (if $prs == null then null else [$prs[] | select(.merged != true) | .number] end) as $open |
    (if $prs == null then null
     else [$prs[] | select(.merged != true and ((.blocker // "") != "")) |
             {number, blocker}] end) as $blocked |
    # The first absent stage, named. Merge, then deployment, then public verification: they are
    # distinct acts and a report that collapses them cannot say which one is owed.
    (if $prs == null then "pull_requests_unreadable"
     elif ($prs | length) == 0 then "implementation"
     elif ($prs | any(.merged != true)) then "merge"
     elif ($i.deployment // "unreadable") == "unreadable" then "deployment_unreadable"
     elif ($i.deployment != "ok") then "deployment"
     # `has`, never `// null`: `rules/shell.md`, *`//` is not a default when `false` is a real
     # answer*. An explicit *not verified* must not read as *nobody looked*.
     elif ($i | has("public_verification") | not) then "public_verification_unreadable"
     elif ($i.public_verification == null) then "public_verification_unreadable"
     elif ($i.public_verification != true) then "public_verification"
     else "" end) as $missing |
    # The bounded, ordered integration unit: open pull requests whose every dependency already
    # merged. A dependency naming something outside this item, or a cycle, refuses the offer.
    (if $prs == null then {order:null, reason:"pull_requests_unreadable"}
     else
       ([$prs[].number]) as $known |
       ([$prs[] | select(.merged != true) |
          {number:.number,
           deps:[(.depends_on // [])[]],
           # Bind the element before asking: `rules/shell.md`, *`<array> | index(.)` tests the
           # array against itself*.
           unknown:[(.depends_on // [])[] | . as $d | select(any($known[]; . == $d) | not)]}]) as $rows |
       (if ($rows | any((.unknown | length) > 0))
        then {order:null, reason:("depends_on_outside_item:" +
               ([$rows[] | select((.unknown|length) > 0) | .unknown[]] | unique | join(",")))}
        else
          ([$prs[] | select(.merged == true) | .number]) as $done |
          # One relaxation pass per open pull request is enough to settle any acyclic graph over
          # this set; whatever is still unsettled afterwards is in a cycle, and is named.
          (reduce range(0; ($rows | length)) as $_ ({settled:$done, rows:$rows};
             .settled as $st |
             {settled:($st + [.rows[] | select([.deps[] | . as $d | select(any($st[]; . == $d) | not)] | length == 0) | .number] | unique),
              rows:.rows}) | .settled) as $settled |
          ([$rows[] | . as $r | select(any($settled[]; . == $r.number) | not) | .number]) as $cyclic |
          (if ($cyclic | length) > 0
           then {order:null, reason:("order_unresolved:" + ($cyclic | map(tostring) | join(",")))}
           else {order:[$rows[] | select([.deps[] | . as $d | select(any($done[]; . == $d) | not)] | length == 0) | .number][0:$max],
                 reason:""} end)
        end)
     end) as $integration |
    {feedback:$i.feedback,
     state:($s.state // "unreadable"),
     notification:($s.notification // "held"),
     deployment:($s.deployment // "unreadable"),
     evidence:($s.evidence // []),
     missing:$missing,
     # `state` answers the implementation and `missing` answers the stages, and NEITHER alone is
     # delivery: a request whose every pull request merged and verified while the deployment
     # failed reads `implemented_and_verified` with `missing: deployment`. Conjoining them here
     # rather than at each call site is the point -- a consumer that read one field would report
     # a failed deployment as a finished request, which is the error measured on this repository.
     delivered:(($s.state // "") == "implemented_and_verified" and $missing == ""),
     pull_requests:{total:(if $prs == null then null else ($prs|length) end),
                    merged:$merged, open:$open, blocked:$blocked},
     next:$integration.order}
    + (if $integration.reason == "" then {} else {next_reason:$integration.reason} end)
    + (if $prs == null then {readable:false, reason:"pull_requests_unreadable"} else {} end)
  ] as $ledger |
  # ONE GATE, ONE ENTRY, WITH ITS WHOLE SCOPE. Grouped by the blocker word the caller supplied --
  # never by similarity, and never renamed -- so a shared external gate is named once and a
  # reader sees every request it is holding.
  ([$ledger[] | select(.readable != false) | . as $l |
     (.pull_requests.blocked // [])[] | {blocker:.blocker, feedback:$l.feedback, number:.number}]
   | group_by(.blocker)
   | map({blocker:.[0].blocker,
          feedbacks:([.[].feedback] | unique),
          pull_requests:([.[].number] | unique),
          scope:length})) as $blockers |
  ([$ledger[] | select(.readable != false) | . as $l |
     (.pull_requests.blocked // []) as $held |
     (.pull_requests.open // [])[] | . as $n |
     select(any($held[]; .number == $n) | not) |
     {feedback:$l.feedback, number:$n}]) as $independent |
  {ledger:$ledger, blockers:$blockers, independent:$independent,
   held_requests:([$blockers[].feedbacks[]] | unique | length),
   delivered:([$ledger[] | select(.state == "implemented_and_verified" and .missing == "")] | length)}
' "$2" >"$tmp/ledger.json" 2>/dev/null || runtime_usage "invalid ledger reading"

runtime_json_result ok "" delivery-ledger "$(cat "$tmp/ledger.json")"
