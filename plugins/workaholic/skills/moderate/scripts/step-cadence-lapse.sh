#!/bin/sh -eu
# Step — a declared cadence whose newest artifact is older than its period allows.
#
# WHY THIS STEP EXISTS (2026-08-31, mission
# `notice-a-periodic-artifact-that-stopped-being-produced`). Every other step of this tick is
# driven by an object that EXISTS — an open pull request, a commit, a claim, a ticket, a
# record — so a producer that dies produces nothing and no step has anything to find. Measured:
# a daily record stopped for four days while hourly ticks ran throughout, and not one of them
# reported it. `/implement` may not ask and a run report is read by nobody on the day it
# matters, so without this step there is no path from *something stopped being produced* to *a
# person is told*.
#
# IT COMPOSES THE ONE READER AND DERIVES NOTHING. `cadence-state.sh` owns the declaration's
# parse, the age and the three states; this step reads its answer and decides only who hears
# about it. A second parse of `WORKAHOLIC_CADENCES` here is exactly how the offer and the
# reading would start disagreeing.
#
# THE FINDING IS ABOUT THE REPOSITORY, so the running identity is never consulted — the
# `step-undrivable-units.sh` axis. A lapsed cadence is lapsed for every account, and an hourly
# repository-scoped question that answered differently per container would be asked once per
# runner rather than once per repository.
#
# IT IS ADDRESSED TO NOBODY, AND THAT IS THE DECLARATION'S SHAPE RATHER THAN AN OVERSIGHT. The
# declaration carries a name, a pattern and a period and nothing else (`workaholic:moderate`,
# *Where a cadence is declared, and what it says*), so there is no assignee to name and this
# step will not stamp one nothing verified — `step-base-health.sh`'s rule, where an unmapped
# login leaves the question addressed to nobody. The question is still visible on the root,
# which is where a person scanning the channel meets it.
#
# IT CARRIES NO QUESTION-LEDGER AGE, deliberately. The four steps that read
# `condition-age.sh` do so because their own readings are instantaneous — each says WHAT is
# stuck and none says HOW LONG — and the reader answers the age of the QUESTION, a lower bound
# on the age of the condition. This reading already answers the condition's own age directly,
# off the newest commit that produced the artifact, which is the stronger fact; attaching the
# ledger age beside it would put two numbers for one question in front of a person and would
# add a fifth consumer to a table pinned at four (`drive/reference/claims.md`, *Which question
# reads which age*).
#
# AN UNREADABLE CADENCE IS NAMED AND ASKED ABOUT BY NOBODY. A pattern that resolves to nothing
# and a malformed entry are OUR degradation, not a lapse, and spending a person's attention on
# a reading we could not make is what `strategy-pace` already refuses. The step reports
# `degraded` by its own reason so the impairment clause on the root names it
# (`name-the-steps-a-tick-could-not-read`), and it still hands over any cadence that DID read
# `lapsed`: losing a question because a different cadence was unreadable is the silently
# dropped finding this tick exists to prevent.
#
# A REPOSITORY THAT DECLARES NOTHING IS `skipped`, NOT `degraded`. It is a step declining to
# run for a stated, healthy reason — the `no_log_source` split `step-workload-logs.sh` draws —
# and `skipped` is deliberately not impairment, so such a repository is byte-identical to what
# it was before this step existed.
#
# THE SUMMARY CARRIES NO AGE AND NO TIMESTAMP, a correctness requirement rather than a
# preference (`step-stalled-units.sh`'s header records the measurement): the root calls a step
# changed when its summary differs from the same step's an hour ago, and an age increments
# every tick, which would mark this step changed hourly by construction — the retired
# `📦 Release Preparation` shape.
#
# IT ASKS AND NOTHING ELSE. It never re-runs a routine, never writes an artifact to satisfy a
# cadence, never edits or repairs the declaration, never touches a claim, never reaches
# `plan-units.sh` (that survey stages what its living migrations converge), and writes nothing
# anywhere but its own tick-log line, which `run.sh` writes.
#
# Usage: step-cadence-lapse.sh --tick <id> [--root <repo-root>]
# Output: one JSON line
#   {"step","status","reason","summary","needs_agent":[...],"event"}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/jq-guard.sh"
READER="${SCRIPT_DIR}/cadence-state.sh"

TICK=""
ROOT="."
while [ $# -gt 0 ]; do
    case "$1" in
        --tick) TICK="${2:-}"; shift 2 ;;
        --root) ROOT="${2:-.}"; shift 2 ;;
        *) shift ;;
    esac
done
: "${TICK:?}"

emit() {
    printf '{"step": "cadence-lapse", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "event": "%s"}\n' \
        "$1" "$2" "$3" "${4:-}" "${5:-}"
    exit 0
}

[ -f "$READER" ] || emit degraded reader_missing "cadence-state.sh is not present beside this skill"

state=$(sh "$READER" --root "$ROOT" 2>/dev/null || true)
if [ -z "$state" ] || ! printf '%s' "$state" | jq -e . >/dev/null 2>&1; then
    emit degraded cadence_unreadable "the cadence reader returned nothing this tick could parse"
fi

if printf '%s' "$state" | jq -e '.readable == false' >/dev/null 2>&1; then
    why=$(printf '%s' "$state" | jq -r '.reason // "unreadable"' 2>/dev/null || printf unreadable)
    emit degraded "$why" "the declared cadences could not be read: ${why}"
fi

empty_reason=$(printf '%s' "$state" | jq -r '.empty_reason // ""' 2>/dev/null || true)
if [ -n "$empty_reason" ]; then
    emit skipped "$empty_reason" "this repository declares no cadence; nothing is expected to keep being produced"
fi

total=$(printf '%s' "$state" | jq -r '.count // 0' 2>/dev/null || printf 0)
n_current=$(printf '%s' "$state" | jq -r '[.cadences[]? | select(.state == "current")] | length' 2>/dev/null || printf 0)
n_lapsed=$(printf '%s' "$state" | jq -r '[.cadences[]? | select(.state == "lapsed")] | length' 2>/dev/null || printf 0)
n_unreadable=$(printf '%s' "$state" | jq -r '[.cadences[]? | select(.state == "unreadable")] | length' 2>/dev/null || printf 0)

summary="${total} declared cadence(s): ${n_current} current, ${n_lapsed} lapsed, ${n_unreadable} unreadable"

needs=''
if [ "$n_lapsed" -gt 0 ]; then
    needs=$(printf '%s' "$state" | jq -c '{action: "ask_about_a_cadence_that_stopped",
        bound: "one question per cadence, keyed on `key` so one lapse costs one question however many ticks see it. It is ADDRESSED TO NOBODY: the declaration names a cadence, a pattern and a period and no person, and this step will not stamp an identity nothing verified. The step asks and nothing else — it re-runs no routine, writes no artifact to satisfy a cadence, repairs no declaration and touches no claim.",
        compose: "name the cadence and what it declared (its pattern and its period), say when its newest artifact was last produced (`last_produced`) and how long ago (`age_hours` hours against a `period_hours`-hour period), and say plainly that the loop can see the artifact stopped and CANNOT see why — the producer may be a routine that is switched off, a credential that expired, or a declaration that is now wrong, and which of those it is needs a person. The age is the condition'"'"'s own, read off the newest commit that produced it, so it may be asserted directly rather than hedged as an age of the question.",
        lapsed: [.cadences[] | select(.state == "lapsed") | {name, pattern, period, period_hours, age_hours, last_produced, key: ("cadence-lapsed:" + .name)}]}' 2>/dev/null || echo '{}')
fi

if [ "$n_lapsed" -eq 1 ]; then
    event="a declared cadence has stopped being produced"
elif [ "$n_lapsed" -gt 1 ]; then
    event="${n_lapsed} declared cadences have stopped being produced"
else
    event=""
fi

if [ "$n_unreadable" -gt 0 ]; then
    # OUR degradation, not a lapse — named so the root's impairment clause carries it, with the
    # lapsed candidates still handed over beside it.
    emit degraded cadence_unreadable "$summary" "$needs" "$event"
fi

emit ok "" "$summary" "$needs" "$event"
