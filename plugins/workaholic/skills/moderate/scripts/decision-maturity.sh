#!/bin/sh -eu
# decision-maturity — IS THE HUMAN DECISION BEHIND THIS BLOCKER MATURE ENOUGH TO ASK ABOUT?
# The one derivation of that verdict, for a direction-level blocker. Pure read: it writes
# nothing, commits nothing, asks nothing and posts nothing.
#
# WHY IT EXISTS (2026-09-08, mission `turn-quiescent-blockers-into-mature-decisions-and-resume-work`,
# from the operator's own instruction: *a question that is premature, cannot yet be answered,
# does not need an answer now, or is meaningless until its premises are examined must not
# become a gate merely because it exists*). Every reading in the direction layer is
# instantaneous and unconditional: `quiescent` says the work is all in, `dormant` says nothing
# is answering, and `/propose` reports `no_evolutionary_move` — and each of them became a
# question to a person the moment it fired, whatever state the direction was actually in. The
# loop had no way to say *this question cannot be answered yet* or *its premise is gone*, so
# the only two outcomes were ask, or end silently in a worker report nobody opens.
#
# WHAT IT ANSWERS, IN FOUR WORDS AND NO SCORE. The Considerations of the ticket that asked for
# it are the constraint: the outcome must stay *visible and arguable rather than hidden in a
# score*. So there is no weight, no threshold and no tunable constant — the verdict is a
# LADDER over fields the strategy survey already emits, every rung named, and `premises[]`
# carries each premise with whether it held and the evidence that decided it. A reader who
# disagrees with the verdict can see exactly which rung produced it.
#
#   retire        the assumption behind the question is GONE. The direction is closed, is not
#                 this identity's, or the operator declared it 観察中 — settled, the loop
#                 reactive only. Asking *what next* about any of those asserts a premise that
#                 no longer holds.
#   prerequisite  a premise the LOOP must build first. `no_feedback_refs`: the direction cites
#                 no record, so nothing can ever be attributed back to it and no answer can be
#                 seen to land. The planning work is named, not the question.
#   defer         the question cannot be answered NOW, or does not need to be. Work attributed
#                 to the direction is still in flight (the answer is *wait*), a proposal is
#                 already open (the next move exists), or nothing is blocked at all.
#   ask_now       currently necessary and supported by adequate premises. Only this verdict
#                 may become a question.
#
# THE ORDER IS FIXED AND IT IS NOT THE OPERATOR'S SENTENCE ORDER. The instruction reads
# *revisit or retire its assumptions, defer the question, or formulate the prerequisite
# planning work*; the ladder runs retire → prerequisite → defer, because the rungs are ordered
# by WHAT IS MISSING and a dead premise outranks a missing one, which outranks a premise that
# is merely not met yet. A closed direction whose work is also in flight is `retire`, and
# reporting it as `defer` would send a reader to wait for work on a direction nobody is
# pursuing.
#
# THE RESIDUE TERM IS DELIBERATELY ABSENT, and that absence is load-bearing. `quiescent` is
# already false when the residue read is degraded (`survey-strategies.sh`, the `quiescent`
# block), and `dormant` deliberately is NOT — *claiming a direction has ARRIVED on a blind
# read sends the operator to CLOSE it; every other reading only asks them to LOOK*. A
# `residue_unreadable` rung here would re-impose on `dormant` the exact term that decision
# refused, so there is none: this reader adds no completeness gate of its own.
#
# IT GATES NOTHING BY ITSELF. It is a reading. `survey-strategies.sh`'s refusal ladder,
# `direction-state.sh`'s precedence, `quiescent`, `dormant`, `pace` and every origination gate
# are byte-identical and are not consulted about the verdict. What a consumer may do with it
# is stated where the consumer lives (`step-direction-health.sh` withholds a question;
# `/propose` names it beside `no_evolutionary_move`) — never here.
#
# AND A DEGRADED READ IS NEVER A VERDICT. A survey that refused, a slug the survey never saw,
# or a row whose attribution walk did not complete answers `readable: false` with a named
# reason and NO verdict at all. The consumer's rule is the one this repository already holds
# for a degraded leaving: our own blindness must never silence a person's question, so a
# consumer treats an unreadable maturity reading as *ask anyway*, and says so.
#
# `readable` IS ABSENT ON A COMPLETED READING, the `merge_policy`/`status:` convention: absent
# means it completed. Every test is `readable == false`, never `readable // true`.
#
# ═══ THE ANSWER RIDES THE SAME READING, AND IT IS DERIVED ═══════════════════════════════
# (2026-09-08, the same mission's third ticket.) An answer a person wrote must not leave
# `quiescent` and `no_evolutionary_move` looking terminal on the next turn, and the ticket's
# own Considerations refuse the obvious mechanism: *prefer existing records and derived state
# over a new mutable reopen flag*. So there is NO flag, NO cursor and NO field on any
# artifact. `answer_state` is read from the tick log's own question ledger — the same lines
# `question-state.sh` reads — and `resumable` is the conjunction of two readings that already
# exist: an answer is recorded, and the direction still reads a blocker.
#
# WHY IT MATCHES THE KEY RATHER THAN CALLING `question-state.sh`. Since 2026-09-03
# `step-direction-health.sh` asks ONE question per reading naming every direction in it, so
# the key is `direction-<reading>:<slug>+<slug>` and a per-slug `question-state.sh --key`
# lookup answers `never_asked` for a direction that was asked about inside a group. This
# reader therefore matches the SLUG against the key's own slug list, which is the only place
# the membership is recorded. It composes `log-read.sh` — the log's one parser — and adds no
# second walker.
#
# `resumable` GATES NOTHING EITHER, and never lifts one. It does not make an ineligible
# direction eligible, does not re-ask an answered question (`ask-question.sh` answers
# `already_asked`/`answered` exactly as before), and does not touch `work_waiting`,
# `open_proposal` or any attribution gate. It says: *a person answered, and the direction has
# still not moved* — evidence for the next `/propose` turn's own judgement.
#
# Usage:
#   decision-maturity.sh --strategy <slug> [--root <repo-root>]
#                        [--survey <file>] [--open-proposals <file>] [window]
#   --survey <file>  an already-performed `survey-strategies.sh` read, so a caller judging
#                    several directions pays for the survey once. WITHOUT it this script
#                    composes the survey itself, which makes that script's one network read.
# Output: one JSON line
#   {"slug","verdict","verdict_reason","blocker","missing","assignees","stage",
#    "premises":[{"name","held","evidence"}],
#    "answer_state","answer","answered_tick","answer_key","resumable"}
#   {"slug","readable":false,"reason":"..."}

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/jq-guard.sh"
LOG_READ="${SCRIPT_DIR}/log-read.sh"
SURVEY="${SCRIPT_DIR}/../../propose/scripts/survey-strategies.sh"

SLUG=""
ROOT="."
SURVEY_FILE=""
OPEN=""
WINDOW=""
while [ $# -gt 0 ]; do
    case "$1" in
        --strategy) SLUG="${2:-}"; shift 2 ;;
        --root) ROOT="${2:-.}"; shift 2 ;;
        --survey) SURVEY_FILE="${2:-}"; shift 2 ;;
        --open-proposals) OPEN="${2:-}"; shift 2 ;;
        *) WINDOW="$1"; shift ;;
    esac
done

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g'
}

degraded() {
    printf '{"slug": "%s", "readable": false, "reason": "%s"}\n' \
        "$(json_escape "$SLUG")" "$1"
    exit 0
}

[ -n "$SLUG" ] || degraded no_slug

# ═══ THE ROW ═══════════════════════════════════════════════════════════════════════════
# One row, from the survey the caller supplied or from the survey this script runs. Both
# lists are searched: a REFUSED row is the one that matters most here, because the states
# this reader exists to judge (`not_active`, `observing`, `no_feedback_refs`, `work_waiting`,
# `open_proposal`) are refusals by construction, and a consumer reading only `eligible[]`
# would find nothing for exactly the direction it is asking about.
if [ -n "$SURVEY_FILE" ]; then
    [ -f "$SURVEY_FILE" ] || degraded survey_file_missing
    survey=$(cat "$SURVEY_FILE" 2>/dev/null || true)
else
    [ -f "$SURVEY" ] || degraded no_survey_script
    if [ -n "$OPEN" ]; then
        survey=$( ( cd "$ROOT" && sh "$SURVEY" --open-proposals "$OPEN" ${WINDOW:+"$WINDOW"} ) 2>/dev/null || true )
    else
        survey=$( ( cd "$ROOT" && sh "$SURVEY" ${WINDOW:+"$WINDOW"} ) 2>/dev/null || true )
    fi
fi

[ -n "$survey" ] || degraded survey_unreadable

survey_ok=$(printf '%s' "$survey" | jq -r '.ok // false' 2>/dev/null || echo unparseable)
case "$survey_ok" in
    true) ;;
    false)
        reason=$(printf '%s' "$survey" | jq -r '.reason // "unknown"' 2>/dev/null || echo unknown)
        degraded "survey_refused:${reason}" ;;
    *) degraded survey_unparseable ;;
esac

# `eligible` rows carry no `reason` — they passed every gate — so one is projected with an
# empty one. Nothing else about either row is rewritten: the verdict is read off the fields
# the survey already emitted.
row=$(printf '%s' "$survey" | jq -c --arg slug "$SLUG" '
    ( ((.eligible // []) | map(. + {reason: ""})) + (.refused // []) )
    | map(select(.slug == $slug)) | first // null' 2>/dev/null || true)

[ -n "$row" ] || degraded row_underivable
[ "$row" != "null" ] || degraded no_such_strategy

row_reason=$(printf '%s' "$row" | jq -r '.reason // ""' 2>/dev/null || echo "")
[ "$row_reason" != "attribution_unreadable" ] || degraded attribution_unreadable

# ═══ THE ANSWER LEDGER ═════════════════════════════════════════════════════════════════
# The question ledger, matched on the KEY's own slug list. An absent log is an ordinary
# `never_asked` — a repository with no tick history has asked nothing — while a log that
# exists and refused is `unreadable`, named rather than rendered as *nobody answered*.
answer_state=unreadable
answer=""
answered_tick=""
answer_key=""
if [ -f "$LOG_READ" ]; then
    asked=$(sh "$LOG_READ" --root "$ROOT" --step-prefix human-checkin-ask- 2>/dev/null || true)
    reasked=$(sh "$LOG_READ" --root "$ROOT" --step-prefix human-checkin-reasked- 2>/dev/null || true)
    answered=$(sh "$LOG_READ" --root "$ROOT" --step-prefix human-checkin-answered- 2>/dev/null || true)
    log_ok=$(printf '%s' "$asked" | jq -r '.read // false' 2>/dev/null || echo unparseable)
    log_reason=$(printf '%s' "$asked" | jq -r '.reason // ""' 2>/dev/null || echo "")
    if [ "$log_ok" = "false" ] && [ "$log_reason" = "no_log_area" ]; then
        answer_state=never_asked
    elif [ "$log_ok" = "true" ]; then
        # A key is `direction-<reading>:<slug>[+<slug>...]`; the slug list after the first
        # colon is the only record of which directions a grouped question named.
        ledger=$(printf '%s\n%s\n%s' "$asked" "$reasked" "$answered" | jq -sc --arg slug "$SLUG" '
            def entries(f): [ .[]? | select(.read? != null) | .entries[]?
                              | select((.step // "") | startswith(f))
                              | . + {key: ((.summary // "") | [scan(" key:.*$")] | (first // "") | ltrimstr(" key:"))} ];
            def mine: select((.key | index(":")) != null)
                      | select(((.key | split(":") | .[1:] | join(":")) | split("+")) | index($slug) != null);
            ( [ entries("human-checkin-answered-")[] | mine ] | sort_by(.tick) | last ) as $a
            | ( [ (entries("human-checkin-ask-")[] | mine), (entries("human-checkin-reasked-")[] | mine) ]
                | sort_by(.tick) | last ) as $q
            | if $a != null
              then {state: "answered", answer: ($a.summary // ""), tick: ($a.tick // ""), key: ($a.key // "")}
              elif $q != null
              then {state: "asked", answer: "", tick: ($q.tick // ""), key: ($q.key // "")}
              else {state: "never_asked", answer: "", tick: "", key: ""} end' 2>/dev/null || true)
        if [ -n "$ledger" ]; then
            answer_state=$(printf '%s' "$ledger" | jq -r '.state' 2>/dev/null || echo unreadable)
            answer=$(printf '%s' "$ledger" | jq -r '.answer' 2>/dev/null || echo "")
            answered_tick=$(printf '%s' "$ledger" | jq -r '.tick' 2>/dev/null || echo "")
            answer_key=$(printf '%s' "$ledger" | jq -r '.key' 2>/dev/null || echo "")
        fi
    fi
fi

# The answer's own words carry whatever a person typed, so it is fed in as an argument
# rather than interpolated into the program.
printf '%s' "$row" | jq -c \
    --arg slug "$SLUG" \
    --arg answer_state "$answer_state" \
    --arg answer "$answer" \
    --arg answered_tick "$answered_tick" \
    --arg answer_key "$answer_key" '
    . as $r
    | (($r.reason // "")) as $reason
    | (($r.stage // "")) as $stage
    | (($r.waiting_missions // 0) + (($r.waiting_count // 0))) as $waiting
    # WHICH READING MADE THIS A BLOCKER. `quiescent` first, on `direction-state.sh`'"'"'s own
    # precedence — a direction whose work is all in is a different question from one nothing
    # is answering, and reading the second over the first is how a success gets asked about
    # as a failure.
    | (if ($r.quiescent // false) then "quiescent"
       elif ($r.dormant // false) then "dormant"
       else "" end) as $blocker
    | [ {name: "direction_is_still_pursued",
         held: ($reason != "not_active" and $reason != "not_mine" and $reason != "observing"),
         evidence: (if $reason == "not_active" then "the direction is closed"
                    elif $reason == "not_mine" then "the direction is not this identity'"'"'s"
                    elif $reason == "observing" then "the operator declared it 観察中"
                    else "active, this identity'"'"'s, and not declared 観察中" end)},
        {name: "answers_can_be_seen_to_land",
         held: ($reason != "no_feedback_refs"),
         evidence: (if $reason == "no_feedback_refs"
                    then "the direction cites no feedback record, so nothing can be attributed back to it"
                    else "the direction cites feedback records" end)},
        {name: "nothing_is_already_in_flight",
         held: ($waiting == 0 and $reason != "work_waiting" and $reason != "open_proposal"),
         evidence: (if ($reason == "open_proposal") then "a proposal for this direction is already open"
                    elif ($waiting > 0 or $reason == "work_waiting")
                    then "attributed work is still in flight: "
                         + (($r.waiting_missions // 0) | tostring) + " mission(s), "
                         + (($r.waiting_count // 0) | tostring) + " ticket(s)"
                    else "nothing attributed to this direction is waiting" end)},
        {name: "a_decision_is_actually_blocked",
         held: ($blocker != ""),
         evidence: (if $blocker == "quiescent" then "its work is all in and nothing is waiting"
                    elif $blocker == "dormant" then "nothing has answered it inside the window"
                    else "neither quiescent nor dormant: no human decision is blocking it" end)} ] as $premises
    | (if ($reason == "not_active") then {verdict: "retire", verdict_reason: "direction_closed",
            missing: "the direction is closed; the question is about something nobody is pursuing"}
       elif ($reason == "not_mine") then {verdict: "retire", verdict_reason: "direction_not_mine",
            missing: "the direction belongs to another identity; this loop has no decision to ask for"}
       elif ($reason == "observing") then {verdict: "retire", verdict_reason: "direction_observing",
            missing: "the operator already declared it 観察中; asking what comes next asserts a premise they retired"}
       elif ($reason == "no_feedback_refs") then {verdict: "prerequisite", verdict_reason: "no_feedback_refs",
            missing: "cite the feedback records this direction answers, so work can be attributed back to it before anyone is asked whether it moved"}
       elif ($reason == "open_proposal") then {verdict: "defer", verdict_reason: "proposal_open",
            missing: "a proposal is already open; the next move exists and needs no decision yet"}
       elif ($waiting > 0 or $reason == "work_waiting") then {verdict: "defer", verdict_reason: "work_in_flight",
            missing: "attributed work has not landed; the answer now would be to wait for it"}
       elif ($blocker == "") then {verdict: "defer", verdict_reason: "no_blocker",
            missing: "no human decision is blocking this direction"}
       else {verdict: "ask_now", verdict_reason: "", missing: ""} end) as $v
    | {slug: $slug,
       verdict: $v.verdict, verdict_reason: $v.verdict_reason,
       blocker: $blocker, missing: $v.missing,
       assignees: ($r.assignees // ""), stage: $stage,
       premises: $premises,
       answer_state: $answer_state, answer: $answer,
       answered_tick: $answered_tick, answer_key: $answer_key,
       # RESUMABLE — a person answered, and the direction has still not moved. Two readings
       # that already exist, conjoined; no flag, no cursor, no date arithmetic. It gates
       # nothing and lifts nothing: it is evidence for the next `/propose` turn.
       resumable: ($answer_state == "answered" and $blocker != "")}' \
    2>/dev/null || degraded verdict_underivable
