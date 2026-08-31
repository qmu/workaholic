#!/bin/sh -eu
# Step — a unit two runs are driving at the same time, and who must decide which one keeps going.
#
# WHY THIS STEP EXISTS (2026-08-30, mission `stop-two-runs-from-claiming-and-driving-one-unit`).
# Nothing named a claim race to anybody. `ambiguous_claim` is reported by every writer that meets
# it and asked about by nobody, so two runs drove one unit for over an hour on 2026-08-30
# (`work-20260830-055314` and `work-20260830-055318`, four seconds apart, the same four tickets)
# and the duplicated hour reached no person at all. `/implement` may not ask, so the run that
# meets a race reports it and this step is the surface that reaches somebody.
#
# WHICH SIBLING IT FOLLOWS, ON EACH AXIS:
#
#   whose question           `stalled-units`'. The claim HOLDERS drove this unit and are the
#                            people who can decide which branch keeps going. Both claims'
#                            `author` values are the addressees.
#   running identity         `undrivable-units`'. Never consulted. A race is a fact about the
#                            unit, not about the container that noticed it, and an hourly
#                            question that answered differently per account would be asked
#                            once per runner rather than once per unit.
#   what it may read         `undrivable-units`'. `list-claims.sh` is a pure read, composed here
#                            through `drive/scripts/list-raced-units.sh`; `plan-units.sh` is
#                            REFUSED, because the survey reaches the mission readers, which
#                            carry the living migrations and STAGE what they converge. A step
#                            whose contract is *writes nothing* may not reach it through
#                            something that writes — the reason `closable-missions` records.
#
# THIS STEP OWNS THE RACED UNIT'S QUESTION, AND THREE SIBLINGS FILTER IT AND COUNT IT. That is
# the `handoff-units`/`stalled-units` precedent — one step asks and the others filter, and either
# half alone is a defect — and the four candidates are settled explicitly rather than left to
# whichever step runs first:
#
#   `stalled-units`      filters and counts. "A claimed unit has not moved for a day or more"
#                        sends a person to look at one claim; the honest question is that two
#                        are driving it.
#   `undelivered-units`  filters and counts. A raced loser's refused merge is the race's
#                        CONSEQUENCE, and asking about the consequence hides the cause.
#   `catchup-blocked`    filters and counts. Catching one of two racing branches up onto the
#                        base is not the act a person needs, and the branch to keep is exactly
#                        what has not been decided yet.
#   `retire-claims`      needs no change and gets none. Its candidates are `superseded` rows,
#                        and a unit resolving `ambiguous` has none BY DEFINITION (every one of
#                        its claims is live), so the two sets are disjoint by construction.
#                        `retire-claim.sh` refuses `ambiguous_claim` on its own besides.
#
# THE QUESTION NAMES BOTH BRANCHES AND PICKS BETWEEN NEITHER. That is `ambiguous_claim`'s
# standing everywhere else in the protocol: choosing one of two live claims silently is how a
# runner would discard work another run is still driving, and the reading here is a JUDGEMENT
# (`drive/reference/claims.md`, *Whether a unit is being driven twice*), so the tick may only
# report or ask.
#
# THE SUMMARY CARRIES NO AGE AND NO TIMESTAMP, for the correctness reason
# `step-stalled-units.sh`'s header records: the root calls a step changed when its summary
# differs from the same step's an hour ago, and an age increments every tick, which would make
# this step changed HOURLY by construction.
#
# IT ASKS AND NOTHING ELSE. No claim released, no branch deleted, no pull request merged or
# closed, no worktree touched, no gate lifted, and nothing written anywhere but the tick log
# line `run.sh` writes.
#
# Usage: step-raced-units.sh --tick <tick-id> [--root <repo-root>]
# Output: one JSON line — {step, status, reason, summary, needs_agent, event}

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/jq-guard.sh"
. "${SCRIPT_DIR}/lib/read-age.sh"
DRIVE_SCRIPTS="${SCRIPT_DIR}/../../drive/scripts/"

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

# `event` is the POST-facing phrase, beside the LOG-facing `summary` and never instead of it.
# Empty means nothing happened here, and the renderer then emits no line at all.
emit() {
    printf '{"step": "raced-units", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "event": "%s"}\n' \
        "$1" "$2" "$3" "${4:-}" "${5:-}"
    exit 0
}

reader="${DRIVE_SCRIPTS}/list-raced-units.sh"
[ -f "$reader" ] || emit degraded no_raced_reader "list-raced-units.sh is not present beside this skill"

out=$( ( cd "$ROOT" && sh "$reader" ) 2>/dev/null || true )
[ -n "$out" ] || emit degraded raced_unreadable "list-raced-units.sh produced no output"

printf '%s' "$out" | jq -e . >/dev/null 2>&1 \
    || emit degraded raced_unparseable "list-raced-units.sh produced output this step could not parse"

ok=$(printf '%s' "$out" | jq -r '.ok // false')
# A degraded scan has not found "no unit is being driven twice" — it has found nothing at all,
# and rendering that as quiet is exactly the collapse the reader's null counts exist to prevent.
[ "$ok" = "true" ] || emit degraded "$(printf '%s' "$out" | jq -r '.reason // "unknown"')" \
    "the claim scan could not be read this tick; whether a unit is being driven twice is unknown"

n=$(printf '%s' "$out" | jq '.count // 0')
summary="${n} unit(s) held by two or more live claims"

if [ "$n" -eq 0 ]; then
    emit ok "" "$summary"
fi

# HOW LONG THIS UNIT HAS BEEN ASKED ABOUT (2026-08-30, mission `say-how-long-the-loop-has-been-stuck`).
# Keyed on the `raced-unit:<unit>` key composed here, so one derivation of the key feeds the
# question, the ledger and the age alike.
rows=$(
    printf '%s' "$out" | jq -c '.raced[]?' 2>/dev/null | while IFS= read -r row; do
        [ -n "$row" ] || continue
        unit=$(printf '%s' "$row" | jq -r '.unit // ""' 2>/dev/null || printf '')
        [ -n "$unit" ] || continue
        key="raced-unit:${unit}"
        age=$(read_age "$key" "$ROOT")
        printf '%s' "$row" | jq -c --arg k "$key" --argjson a "$age" '. + {key: $k, age: $a}' \
            2>/dev/null || printf '%s' "$row"
    done | jq -sc '.' 2>/dev/null || printf '[]'
)
[ -n "$rows" ] || rows='[]'
asked=$(printf '%s' "$rows" | jq 'length' 2>/dev/null || echo 0)

[ "$asked" -eq 0 ] && emit ok "" "$summary"

needs=$(printf '%s' "$rows" | jq -c '{action: "ask_the_claim_holders_which_branch_keeps_driving_this_unit",
    bound: "one question per unit, addressed to the claim holders in `owners`, keyed on `key` so it is asked once; the tick asks and never releases a claim, picks between the branches, deletes a branch, closes a pull request or merges anything",
    compose: "say the unit is held by two live claims at once and name BOTH branches from `branches` with their verdicts, never one of them — choosing silently is how work another run is still driving gets discarded. Say the answer is given in this session, through the link on the question. `age` is how long the unit has been ASKED ABOUT (`age.ticks` ticks since `age.first_seen`, `at least` that when `age.first_seen_is_floor`); say nothing about it when `age.first_seen` is null and the reading is readable — that is the first time anybody is being asked — and when `age.readable` is false name it as an age we could not read, by its `age.reason`, never as a race that just started.",
    raced: .}' 2>/dev/null || echo '{}')

if [ "$asked" -eq 1 ]; then
    event="a unit is being driven by two claims at once"
else
    event="${asked} units are being driven by two claims at once"
fi

emit ok "" "$summary" "$needs" "$event"
