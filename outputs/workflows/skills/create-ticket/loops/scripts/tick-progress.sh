#!/bin/sh -eu
# One tick's progress readout: where the queue stands, per mission, and what the
# origination gate would answer next.
#
# Usage: tick-progress.sh [repo-root]
# Output: one JSON object, ALWAYS exit 0.
#   {"queue_total": N,
#    "missions": [{slug, checked, total, todo, archived, draining}
#                 | {slug, checked: null, total: null, todo: null, archived: null,
#                    draining: null, readable: false, reason: "<word>"}],
#    "gating_missions": N, "unreadable_missions": N,
#    "wip_limit": N|null, "propose_gate": "work_waiting"|"open"|"unreadable"}
#
# WHY IT EXISTS (2026-09-03, the developer's ask). The tick reported which loops it
# spawned and nothing about whether the work was moving. A person watching it could not
# tell a queue that is draining from one that is stuck, nor how close the origination
# gate is to opening — both of which are already derivable from readers this repository
# owns. It composes them; it derives nothing of its own, holds no state and writes
# nothing.
#
# `draining` is a FACT ABOUT THIS MISSION'S OWN ARCHIVE, not a trend: a mission with
# archived tickets has had work land. A trend needs two readings and this script keeps
# no cursor by design — the caller compares ticks.
#
# THE SIBLING READERS RESOLVE AGAINST THIS SCRIPT, NEVER AGAINST THE TREE BEING READ
# (2026-09-06, ticket `20260906193731`). `ROOT` is the repository whose `.workaholic/`
# tree is being *read*; the readers live wherever this *plugin* is installed, and on any
# repository that does not vendor the plugin those are different places. The old
# `S="$ROOT/plugins/workaholic/skills"` named a directory that did not exist there, both
# calls failed, `|| echo '{}'` swallowed it, and the `// null` defaults rendered "I could
# not run the reader" as data. MEASURED by the operator over eight consecutive readings,
# ~50 minutes, two active missions: every per-mission field `null`, `draining: false`
# against six archived tickets, `gating_missions: 0` against 2, `propose_gate: open`
# against `work_waiting`. `queue_total` was correct throughout — it reads the ticket
# directory directly and touches no sibling script, which is the control that made the
# defect easy to miss and the reason it is deliberately NOT folded into the reader path.
#
# AND THE ROOT IS PASSED TO `queue-size.sh`, WHICH ALREADY ACCEPTS ONE. Resolving the
# siblings alone is necessary and NOT sufficient: `queue-size.sh <slug> [workaholic-root]`
# falls back to `git rev-parse --show-toplevel` at the PROCESS CWD when the root is
# omitted, so with `$S` repaired and cwd pointed anywhere but `ROOT` the counts came back
# `todo: 0, archive: 0, draining: false, propose_gate: open` — plausible zeros where there
# had been visible nulls, which is a worse failure than the one being cured. The divergence
# between `ROOT` and cwd is the DESIGNED case, not an edge case: this script takes
# `[repo-root]` precisely so a caller can name a tree it is not standing in, and the loop's
# own subagents run in claim worktrees and publish trees. `ROOT` is absolutized once, where
# it is assigned, so `progress.sh` is handed an absolute mission path and `queue-size.sh` an
# absolute root regardless of how the argument arrived.
#
# A FAILED READ IS NAMED, NEVER RENDERED AS DATA. Both `// null` defaults and the
# `(.[1].archive // 0) > 0` in `draining` turned an unreadable row into two WRONG answers
# rather than absent ones: `draining` read *nothing has ever landed here*, and `gating`
# incremented only on `.todo > 0`, so a null todo could never gate and `gating_missions`
# was structurally pinned at 0. A row whose reader could not run now carries
# `readable: false`, a named reason and NULL counts — the shape `strategy/scripts/*` and
# `cadence-state.sh` already use, so this invents no third convention. `readable` is ABSENT
# on a completed row (the `merge_policy` / `status:` convention: absent means it completed),
# so a consumer tests `readable == false` and never `readable // true`. `draining` is `null`
# on such a row, never `false`. The four reasons name which half failed, because that is the
# whole diagnosis: `progress_reader_missing` / `queue_reader_missing` (the script is not
# there — what the measured failure above would have said, pointing straight at the
# resolution) and `progress_unreadable` / `queue_unreadable` (it ran and gave nothing
# usable). Progress is checked first, so a row failing both ways names one word rather than
# a compound — `claimable-units.sh`'s own rule.
#
# THE GUARDS ARE KEPT, NOT REMOVED. They exist so one unreadable mission does not abort the
# whole walk, and the walk still completes. The defect was never that failures are caught;
# it was that a caught failure was then rendered as a count.
#
# `propose_gate` IS THREE-VALUED, AND THAT IS THE CHOSEN SHAPE. A tick that could not read a
# mission row knows neither `work_waiting` nor `open`, and this repository's standing rule is
# that degradation is stated and never derived into a verdict — so the third state gets its
# own word rather than being folded into either, exactly as `cadence-state.sh`
# (`current`/`lapsed`/`unreadable`) and `direction-state.sh` (whose lifecycle carries
# `unreadable` beside its five real states) already answer. Precedence, and it is not
# symmetric: a READABLE row with queued work answers `work_waiting` even when another row is
# unreadable, because that is a positive fact an unreadable row cannot overturn — an
# unreadable row could only add more work, never remove it. Otherwise any unreadable row
# answers `unreadable`. Only a walk in which every row was read and none carries queued work
# answers `open`. An unreadable row can therefore NEVER produce `open`, which is the whole
# point: a caller acting on `open` originates new work against a queue that may not be
# draining, which is the exact state the gate exists to prevent.
#   COST, STATED: a caller that switches on two words sees an unfamiliar third. That is the
#   intended failure — such a caller falls through rather than originating, which is the safe
#   direction — and it is why the word was chosen over silently answering `work_waiting`,
#   which would have left a caller unable to tell "the gate is closed" from "I could not
#   look". `unreadable_missions` rides beside `gating_missions` so the skip is visible in the
#   counts too: `gating_missions` counts only rows that were READ and carry queued work, and
#   a row it could not read is counted there rather than silently omitted from both.

set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
PROGRESS="${SCRIPT_DIR}/../../mission/scripts/progress.sh"
QUEUE_SIZE="${SCRIPT_DIR}/../../mission/scripts/queue-size.sh"

ROOT="${1:-}"
if [ -z "$ROOT" ]; then
  ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
fi
# Absolutized ONCE, here, rather than at each use: `progress.sh` is handed a mission path
# built from it and `queue-size.sh` an explicit root, and neither may depend on the cwd this
# script happens to be run from.
if [ -d "$ROOT" ]; then
  ROOT=$(CDPATH='' cd -- "$ROOT" && pwd)
fi

WORKAHOLIC="$ROOT/.workaholic"
ACTIVE="$WORKAHOLIC/missions/active"

queue_total=$(find "$WORKAHOLIC/tickets/todo" -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ')
rows=''
gating=0
unreadable=0

if [ -d "$ACTIVE" ]; then
  for slug in $(find "$ACTIVE" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort); do
    reason=''

    if [ ! -f "$PROGRESS" ]; then
      reason=progress_reader_missing
    else
      prog=$(sh "$PROGRESS" "$ACTIVE/$slug/mission.md" 2>/dev/null) || prog=''
      if [ -z "$prog" ] || ! printf '%s' "$prog" | jq -e 'has("checked") and has("total")' >/dev/null 2>&1; then
        reason=progress_unreadable
      fi
    fi

    if [ -z "$reason" ]; then
      if [ ! -f "$QUEUE_SIZE" ]; then
        reason=queue_reader_missing
      else
        q=$(sh "$QUEUE_SIZE" "$slug" "$WORKAHOLIC" 2>/dev/null) || q=''
        if [ -z "$q" ] || ! printf '%s' "$q" | jq -e 'has("todo") and has("archive")' >/dev/null 2>&1; then
          reason=queue_unreadable
        fi
      fi
    fi

    if [ -n "$reason" ]; then
      row=$(jq -n -c --arg slug "$slug" --arg reason "$reason" \
        '{slug: $slug, checked: null, total: null, todo: null, archived: null,
          draining: null, readable: false, reason: $reason}')
      unreadable=$((unreadable + 1))
    else
      row=$(printf '%s\n%s\n' "$prog" "$q" | jq -s -c --arg slug "$slug" '
        {slug: $slug,
         checked: .[0].checked, total: .[0].total,
         todo: .[1].todo, archived: .[1].archive,
         draining: (.[1].archive > 0)}')
      if [ "$(printf '%s' "$row" | jq -r '.todo')" -gt 0 ]; then
        gating=$((gating + 1))
      fi
    fi

    rows="$rows$row"
  done
fi

limit="${WORKAHOLIC_WIP_LIMIT:-}"

# A readable row carrying queued work outranks an unreadable one; otherwise an unreadable
# row forbids `open`. See the header — an unreadable row can never produce `open`.
if [ "$gating" -gt 0 ]; then
  gate=work_waiting
elif [ "$unreadable" -gt 0 ]; then
  gate=unreadable
else
  gate=open
fi

printf '%s' "$rows" | jq -s \
  --argjson queue "$queue_total" \
  --argjson gating "$gating" \
  --argjson unreadable "$unreadable" \
  --arg limit "$limit" \
  --arg gate "$gate" \
  '{queue_total: $queue, missions: ., gating_missions: $gating,
    unreadable_missions: $unreadable,
    wip_limit: (if $limit == "" then null else ($limit | tonumber) end),
    propose_gate: $gate}'
