#!/bin/sh -eu
# date-will-not-hold — a direction whose arithmetic does not clear, said to the person who
# owns it, BEFORE the date rather than after it. It runs beside `strategy-pace` and
# `direction-health`; `reference/workflow.md` states its contract.
#
# WHY THIS STEP EXISTS (2026-09-01, ticket
# `20260901123357-escalate-a-date-that-will-not-hold-never-re-date-it`). Two date questions
# already exist and BOTH fire at or after the date: `direction-health` asks `direction-overdue`
# once the date has GONE and `direction-expiring` once it is inside the survey window. Nothing
# asked *before*, on the arithmetic — measured 2026-09-01, three directions dated the same day,
# six days out, 30 queued tickets between them, every reading healthy and nobody told.
#
# THE ASK'S "RE-DATE" IS REFUSED HERE, ON A STANDING RULE, AND THE REFUSAL IS THE POINT.
# The ask was that the loop "re-date or escalate what the arithmetic says cannot land". A
# strategy is the operator's RESOLVED direction; `amend.sh` carries only a revision the
# operator announced by explicit slug, and A RUN NEVER AMENDS ON ITS OWN READING
# (`workaholic:strategy`). A loop that moves its own deadlines when it misses them is a loop
# whose dates mean nothing — a worse failure than the one being fixed. So this step builds the
# escalation and writes NOTHING: no `amend.sh` call, no `target_date` touched, no stage moved,
# no mission closed, no work held. The one act is the question.
#
# AND THE QUESTION NAMES THE ACT THE ADDRESSEE CAN ACTUALLY TAKE. How the operator re-dates is
# already one message: announce the change naming the slug, and `/specificate`'s step 9d carries
# it through `amend.sh`. A question that named a state and no act would be a status line.
#
# IT DOES NOT ASK TWICE ABOUT THE SAME THING, AND THE BOUNDARY IS READ RATHER THAN RE-DERIVED.
# A candidate must read `live` in `direction-state.sh` — the ONE lifecycle reader, whose own
# precedence is `unreadable > arrived > overdue > expiring > dormant > live`. So every direction
# `direction-health` asks about in this tick is excluded BY THAT STEP'S OWN READING rather than
# by a second copy of the expiring boundary here: `overdue` and `expiring` keep their cases,
# `arrived` and `dormant` keep theirs, and this one gets what is left — a live, in-date direction
# whose board will not clear. A new threshold here would be a number nobody could defend, and a
# second derivation of `expiring` is how two boundaries drift. A lifecycle read that REFUSED is
# `degraded` BY NAME rather than an empty live set quietly asking nobody: without the filter this
# step has not found *nothing to escalate*, it has found nothing at all. It takes the same
# optional `--open-proposals` file `direction-health` does, so both read one lifecycle answer.
#
# `strategy-pace` IS A DIFFERENT QUESTION AND IS NOT FILTERED AGAINST. `pace: late` asks whether
# anything has LANDED over a period as long as the one that remains; this asks whether what
# REMAINS fits in the days left. A direction can be `on_course` and still not clear — that is
# precisely the measured case — so filtering one against the other would drop the finding this
# step exists for.
#
# A DIRECTION WITH NO DATE IS NEVER A CANDIDATE — there is nothing to escalate — and a DEGRADED
# reading yields no candidate and is COUNTED, never guessed at: asking a person about a reading
# that failed spends their attention on our own degradation, which is `strategy-pace`'s own rule
# for `unknown` and this step's for `unreadable`.
#
# WHAT IT COSTS, STATED RATHER THAN DISCOVERED. Both readings walk attribution, and on this
# repository they measured 110s (`landing-arithmetic.sh`, whose cost is `digest.sh`'s own — a
# `git log` per corpus file for the honesty line) and 36s (`direction-state.sh`). The first is a
# cost the tick ALREADY pays, in `strategy-digest`; the second is one `direction-health` already
# pays. Re-composing either reading here to make this step cheaper would put a second
# composition of the same board in the tree, which is how two answers to one question drift —
# so the duplicate read is taken deliberately and named here. A tick that runs out of clock
# reports this step `skipped` with reason `budget`, BY NAME, which is the existing seam for it.
#
# Usage: step-date-will-not-hold.sh --tick <id> [--root <repo-root>] [--open-proposals <file>]
# Output: one JSON line
#   {"step","status","reason","summary","needs_agent":[...],"event"}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/jq-guard.sh"
. "${SCRIPT_DIR}/lib/read-age.sh"
STRATEGY_SCRIPTS="${SCRIPT_DIR}/../../strategy/scripts"

TICK=""
ROOT="."
OPEN=""
while [ $# -gt 0 ]; do
    case "$1" in
        --tick) TICK="${2:-}"; shift 2 ;;
        --root) ROOT="${2:-.}"; shift 2 ;;
        --open-proposals) OPEN="${2:-}"; shift 2 ;;
        *) shift ;;
    esac
done
: "${TICK:?}"

# `event` is the POST-facing phrase, beside the LOG-facing `summary` and never instead of it.
# **Empty means nothing happened here** — the renderer then emits no line at all, independently
# of the change diff.
emit() {
    printf '{"step": "date-will-not-hold", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "event": "%s"}\n' \
        "$1" "$2" "$3" "${4:-}" "${5:-}"
    exit 0
}

arith="${STRATEGY_SCRIPTS}/landing-arithmetic.sh"
[ -f "$arith" ] || emit degraded no_arithmetic_script "landing-arithmetic.sh is not present beside this skill"
lifecycle="${STRATEGY_SCRIPTS}/direction-state.sh"
[ -f "$lifecycle" ] || emit degraded no_lifecycle_script "direction-state.sh is not present beside this skill"

out=$( ( cd "$ROOT" && sh "$arith" ) 2>/dev/null || true )
[ -n "$out" ] || emit degraded arithmetic_unreadable "landing-arithmetic.sh produced no output"
printf '%s' "$out" | jq -e . >/dev/null 2>&1 \
    || emit degraded arithmetic_unparseable "landing-arithmetic.sh produced output this step could not parse"

# `readable` is ABSENT on a completed read, so the test is `== false` and never `// true`.
if [ "$(printf '%s' "$out" | jq -r '.readable == false')" = "true" ]; then
    reason=$(printf '%s' "$out" | jq -r '.reason // "unparseable"')
    emit degraded "$reason" "the landing arithmetic refused: ${reason} — no direction's board could be read this tick"
fi

# The same window and the same optional open-proposals file `direction-health` passes, so the
# two steps read one lifecycle answer rather than two.
WROOT="${ROOT%/}/.workaholic"
if [ -n "$OPEN" ]; then
    state=$(sh "$lifecycle" --open-proposals "$OPEN" "14 days ago" "$WROOT" 2>/dev/null || true)
else
    state=$(sh "$lifecycle" "14 days ago" "$WROOT" 2>/dev/null || true)
fi
[ -n "$state" ] || emit degraded lifecycle_unreadable "direction-state.sh produced no output"
printf '%s' "$state" | jq -e . >/dev/null 2>&1 \
    || emit degraded lifecycle_unparseable "direction-state.sh produced output this step could not parse"

# THE LIVE SET IS THE SIBLING STEP'S OWN ANSWER, carried rather than recomputed — and a
# lifecycle read that REFUSED is `degraded` by name rather than an empty live set quietly
# asking nobody. The filter is what keeps this step and `direction-health` off one person in
# one tick, so a tick without it has not found "nothing to escalate"; it has found nothing at
# all. `direction-health` reports its own refusal exactly this way.
readable=$(printf '%s' "$state" | jq -r '.readable // false' 2>/dev/null || echo false)
if [ "$readable" != "true" ]; then
    reason=$(printf '%s' "$state" | jq -r '.reason // "unparseable"' 2>/dev/null || echo unparseable)
    emit degraded "$reason" "the direction reader refused: ${reason} — which directions another date question already owns could not be read this tick"
fi

live=$(printf '%s' "$state" | jq -c '[.strategies[]? | select(.state == "live") | .slug]' 2>/dev/null || printf '[]')
[ -n "$live" ] || live='[]'

total=$(printf '%s' "$out" | jq '.directions | length' 2>/dev/null || echo 0)
unreadable=$(printf '%s' "$out" | jq '[.directions[] | select(.verdict == "unreadable")] | length' 2>/dev/null || echo 0)
dateless=$(printf '%s' "$out" | jq '[.directions[] | select(.verdict == "no_target_date")] | length' 2>/dev/null || echo 0)
failing=$(printf '%s' "$out" | jq -c '[.directions[] | select(.verdict == "does_not_clear")]' 2>/dev/null || printf '[]')
n_failing=$(printf '%s' "$failing" | jq 'length' 2>/dev/null || echo 0)

# Every direction the sibling date questions already own is dropped here BY ITS OWN READING.
candidates=$(printf '%s' "$failing" | jq -c --argjson live "$live" '
    [ .[] | select(.slug as $s | $live | index($s))
      | {slug, title, assignees, target_date, days_to_target,
         remaining_queued: .remaining.queued,
         remaining_unchecked_acceptance: .remaining.unchecked_acceptance,
         landed_in_window: .observed.landed, window_days: .observed.window_days,
         per_day: .observed.per_day, needed_days: .needed_days,
         key: ("date-will-not-hold:" + .slug)} ]' 2>/dev/null || printf '[]')
[ -n "$candidates" ] || candidates='[]'
count=$(printf '%s' "$candidates" | jq 'length' 2>/dev/null || echo 0)
elsewhere=$((n_failing - count))
[ "$elsewhere" -ge 0 ] || elsewhere=0

summary="${total} direction(s) read; ${n_failing} will not clear at the observed rate, ${elsewhere} of them already asked about by another date question; ${dateless} have no date, ${unreadable} could not be read"

if [ "$count" -eq 0 ]; then
    emit ok "" "$summary"
fi

# HOW LONG THIS DIRECTION HAS BEEN ASKED ABOUT, beside the arithmetic's own numbers — the same
# sibling reading `stalled-unit`, `undelivered-unit`, `undrivable-unit` and `retire-blocked`
# carry, keyed on the key the row already composes. TWO KINDS OF NUMBER, NEVER BLENDED: the
# arithmetic answers *what remains against how long is left*, the ledger answers *how long have
# we been asking*. `drive/reference/claims.md` records which question reads which age, and the
# rule it exists for — NOTHING DERIVES AN AGE TWICE.
candidates=$(
    printf '%s' "$candidates" | jq -c '.[]?' 2>/dev/null | while IFS= read -r row; do
        [ -n "$row" ] || continue
        key=$(printf '%s' "$row" | jq -r '.key // ""' 2>/dev/null || printf '')
        age=$(read_age "$key" "$ROOT")
        printf '%s' "$row" | jq -c --argjson a "$age" '. + {age: $a}' 2>/dev/null || printf '%s' "$row"
    done | jq -sc '.' 2>/dev/null || printf '%s' "$candidates"
)

needs=$(printf '%s' "$candidates" | jq -c '{action: "ask_the_assignee_whether_this_direction_s_date_still_holds",
    bound: "one question per direction, addressed to its assignee, keyed on `key` so it is asked once. The tick WRITES NOTHING: it never calls amend.sh, never moves a target_date or a stage, never closes a mission and never holds work. The question is the only act.",
    compose: "Lead with what happened in words a reader outside the repository understands — what is left, how long is left, and that at the rate this direction has actually been moving it does not fit — then the slug. Name ONE act: the operator either re-dates the direction by announcing the change with its slug (which /specificate carries through amend.sh) or accepts the date and cuts what is queued. Never say the loop will re-date it; it may not. `remaining_queued` and `remaining_unchecked_acceptance` are TWO GRAINS and are not the same unit — say what was counted rather than adding them. `age` is how long this has been ASKED ABOUT (`age.ticks` ticks since `age.first_seen`, `at least` that when `age.first_seen_is_floor`); say nothing about it when `age.first_seen` is null and the reading is readable — that is the first time anybody is being asked — and when `age.readable` is false name it as an age we could not read, by its `age.reason`, never as a condition that just started.",
    directions: .}' 2>/dev/null || echo '{}')

if [ "$count" -eq 1 ]; then
    event="a direction will not finish what it has queued before its date"
else
    event="${count} directions will not finish what they have queued before their dates"
fi

emit ok "" "$summary" "$needs" "$event"
