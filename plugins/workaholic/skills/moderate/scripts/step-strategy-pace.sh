#!/bin/sh -eu
# Step 10 — a direction that will not arrive, said to the person who owns it.
#
# WHY THIS STEP EXISTS, AND WHY HERE (2026-08-22, the Open Decision on ticket
# 20260822225204-order-the-tick-by-lateness-..., ruled while driving it).
# `propose/scripts/survey-strategies.sh` now reads each strategy's `pace` — whether
# anything landed over a period as long as the one that remains. Three surfaces could
# carry a `late` reading, and only one covers the case that actually starves:
#
#   (a) `/propose`'s own run report. Refused: an hourly routine's run report is read by
#       whoever opens the session, which on the day it matters is nobody. That is the
#       exact invisibility this step exists to end -- measured with `over_cap`, which
#       reported itself by name on every single tick and still hid a day of starvation.
#   (b) The proposal issue `/propose` opens. Refused: it says nothing when the direction
#       is late AND gated, and late-and-gated IS the starving case. A direction whose work
#       is in flight gets no proposal, so there is no issue to carry the reading.
#   (c) A question through this tick, addressed to the strategy's assignee. Chosen.
#
# THE COUPLING IS A READER, NOT A HANDOFF. `/propose` writes nothing into the tree, so it
# could not leave a finding here even if it wanted to. This step calls
# `survey-strategies.sh` itself -- a pure read, the same script, no stored state and no
# second derivation of pace. Two readers of one script is not two sources of truth.
#
# IT ASKS; IT NEVER PROPOSES AND NEVER LIFTS A GATE. A late direction that is
# `work_waiting` stays `work_waiting`: the answer to "the work is in flight but not
# moving" is a person, not another proposal. That refusal is stated in the propose skill
# and this step must not route around it.
#
# `unknown` IS NOT ASKED ABOUT. A pace that could not be read is reported in the step
# summary and nothing else -- asking a person about a reading that failed spends their
# attention on our own degradation.
#
# Usage: step-strategy-pace.sh --tick <id> [--root <repo-root>]
# Output: one JSON line
#   {"step","status","reason","summary","needs_agent":[...]}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROPOSE_SCRIPTS="${SCRIPT_DIR}/../../propose/scripts"

TICK=""
ROOT="."
while [ $# -gt 0 ]; do
    case "$1" in
        --tick) TICK="${2:-}"; shift 2 ;;
        --root) ROOT="${2:-.}"; shift 2 ;;
        *) shift ;;
    esac
done

# `event` is the POST-facing phrase, beside the LOG-facing `summary` and never instead of it
# (2026-08-23). Two audiences: the log is an audit trail a maintainer reads when the tick
# misbehaves and keeps every counter; the root is read by a person scanning a channel, who
# needs the repository's event. This step supplies it because it knows what its finding means.
# **Empty means nothing happened here** — the renderer then emits no line at all, independently
# of the change diff.
emit() {
    printf '{"step": "strategy-pace", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "event": "%s"}\n' \
        "$1" "$2" "$3" "${4:-}" "${5:-}"
    exit 0
}

survey="${PROPOSE_SCRIPTS}/survey-strategies.sh"
[ -f "$survey" ] || emit degraded no_survey_script "survey-strategies.sh is not present beside this skill"

out=$(sh "$survey" 2>/dev/null || true)
[ -n "$out" ] || emit degraded survey_unreadable "survey-strategies.sh produced no output"

ok=$(printf '%s' "$out" | jq -r '.ok // false' 2>/dev/null || echo false)
if [ "$ok" != "true" ]; then
    reason=$(printf '%s' "$out" | jq -r '.reason // "unparseable"' 2>/dev/null || echo unparseable)
    emit degraded "$reason" "the strategy survey refused: ${reason} — no pace could be read this tick"
fi

# Every surveyed row, eligible or refused, carries `pace`. The starving case is late AND
# refused, so both lists are read; reading only the eligible ones would miss it entirely.
late=$(printf '%s' "$out" | jq -c '[(.eligible // []), (.refused // [])] | flatten
    | map(select(.pace == "late"))
    | map({slug, title: (.title // .slug), assignees: (.assignees // ""),
           days_to_target: .days_to_target, refusal: (.reason // "")})' 2>/dev/null || echo '[]')
count=$(printf '%s' "$late" | jq 'length' 2>/dev/null || echo 0)
unknown=$(printf '%s' "$out" | jq '[(.eligible // []), (.refused // [])] | flatten | map(select(.pace == "unknown")) | length' 2>/dev/null || echo 0)

if [ "$count" -eq 0 ]; then
    emit ok "" "no direction is late; ${unknown} pace reading(s) could not be made"
fi

needs=$(printf '%s' "$late" | jq -c '{action: "ask_the_owner_whether_this_direction_will_arrive",
    bound: "one question per strategy, addressed to its assignee; never a proposal, and never a reason to lift a gate",
    late: .}' 2>/dev/null || echo '{}')
emit ok "" "${count} direction(s) will not arrive at this pace; ${unknown} reading(s) unknown" "$needs" \
    "${count} direction(s) will not arrive by their date at this pace"
