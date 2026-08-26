#!/bin/sh -eu
# direction-health — a direction that has run out of date, or that nothing is answering, said
# to the person who owns it. It runs beside `strategy-pace` and before the check-in, which is
# what asks; `reference/workflow.md` states its contract.
#
# WHY THIS STEP EXISTS (2026-08-26, mission `say-when-the-loop-has-run-out-of-direction`).
# Three states of the direction layer were silent, and each was byte-identical to a healthy
# idle hour:
#
#   * a direction PAST ITS DATE — refused `past_target_date`, while `pace` reads `on_course`
#     because work did land; no proposal, no question, forever;
#   * a live direction NOTHING IS ANSWERING — `/propose` reports `no_evolutionary_move`, the
#     honest answer, into a run report that on the day it matters is read by nobody;
#   * a repository with NO LIVE DIRECTION at all — `no_strategies`, a no-op everywhere.
#
# THE SURFACE IS THE SAME ONE `strategy-pace` CHOSE, ON THE SAME GROUNDS. Read that step's
# header: `/propose`'s own run report is the invisibility this exists to end, and the proposal
# issue says nothing precisely when the direction is gated. A question through this tick,
# addressed to the strategy's assignee, is the only one of the three that reaches a person.
#
# THE COUPLING IS A READER, NOT A HANDOFF. `/propose` writes nothing into the tree, so it
# could not leave a finding here even if it wanted to. This step calls
# `strategy/scripts/direction-state.sh` itself — the one lifecycle reader, which composes the
# same survey and re-derives nothing. Two readers of one script is not two sources of truth.
#
# IT ASKS; IT NEVER CLOSES, NEVER PROPOSES AND NEVER LIFTS A GATE. The strategy artifact has
# exactly two writers (`create.sh` creates, `close.sh` ends) and this is neither. A dormant
# direction stays eligible; an overdue one stays refused. Ending a direction is announced by
# the operator and reaches `close.sh` through `/specificate`, never from here.
#
# `unreadable` IS NOT ASKED ABOUT. A reading that could not be made is counted in the summary
# and nothing else — spending a person's attention on our own degradation is the rule
# `strategy-pace` already applies to its own `unknown`.
#
# THE CHECK-IN'S MACHINERY APPLIES UNCHANGED: the working-day and quiet-hour holds, the
# per-tick cap of five and the daily bound of ten, the asked-once ledger, the three-state
# answer reader and the once-more re-ask. This step supplies subjects and their content keys;
# the gate, the ask and the ledger stay in `ask-question.sh` and `step-human-checkin.sh`.
#
# THE CAP IS A LATENCY COST HERE, NOT A LOSS, and it is worth stating rather than tuning: a
# repository with several expired directions could fill a tick's five questions and hold the
# other steps' questions to the next hour. Held is not dropped — that is the check-in's own
# contract — and no cap here has been measured, so none is invented.
#
# `direction-none` HAS NO ASSIGNEE TO ADDRESS. It is a repository-level reading, so it is asked
# without a mention token rather than aimed at whoever happens to run the tick.
#
# Usage: step-direction-health.sh --tick <id> [--root <repo-root>] [--open-proposals <file>]
# Output: one JSON line
#   {"step","status","reason","summary","needs_agent":[...],"event"}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
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

# `event` is the POST-facing phrase, beside the LOG-facing `summary` and never instead of it
# (2026-08-23). **Empty means nothing happened here** — the renderer then emits no line at all,
# independently of the change diff.
emit() {
    printf '{"step": "direction-health", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "event": "%s"}\n' \
        "$1" "$2" "$3" "${4:-}" "${5:-}"
    exit 0
}

reader="${STRATEGY_SCRIPTS}/direction-state.sh"
[ -f "$reader" ] || emit degraded no_reader_script "direction-state.sh is not present beside this skill"

WROOT="${ROOT%/}/.workaholic"
if [ -n "$OPEN" ]; then
    out=$(sh "$reader" --open-proposals "$OPEN" "14 days ago" "$WROOT" 2>/dev/null || true)
else
    out=$(sh "$reader" "14 days ago" "$WROOT" 2>/dev/null || true)
fi
[ -n "$out" ] || emit degraded reader_unreadable "direction-state.sh produced no output"

readable=$(printf '%s' "$out" | jq -r '.readable // false' 2>/dev/null || echo false)
if [ "$readable" != "true" ]; then
    reason=$(printf '%s' "$out" | jq -r '.reason // "unparseable"' 2>/dev/null || echo unparseable)
    emit degraded "$reason" "the direction reader refused: ${reason} — no lifecycle state could be read this tick"
fi

repository=$(printf '%s' "$out" | jq -r '.repository // ""' 2>/dev/null || echo "")
n_overdue=$(printf '%s' "$out" | jq -r '.counts.overdue // 0' 2>/dev/null || echo 0)
n_dormant=$(printf '%s' "$out" | jq -r '.counts.dormant // 0' 2>/dev/null || echo 0)
n_unreadable=$(printf '%s' "$out" | jq -r '.counts.unreadable // 0' 2>/dev/null || echo 0)
n_live=$(printf '%s' "$out" | jq -r '.counts.live // 0' 2>/dev/null || echo 0)

# THE SUBJECTS. One per non-`live` reading, each carrying the content key `ask-question.sh`'s
# already-asked ledger keys on. `unreadable` rows are deliberately absent from this list.
#
# EACH SUBJECT CARRIES ITS OWN WORDING, IN THREE PARTS AND IN THIS ORDER: the READING (what is
# true of the direction), the SLUG it is about, and the OPERATOR'S OWN NEXT ACT. A question a
# person cannot answer without opening a skill is a question that waits, and the step is what
# supplies the wording because it is what knows what its reading means.
#
#   heading -> the `🙋 <@U…> - <…>` line's subject: the reading and the slug
#   body    -> one sentence, the operator's act, inside `workaholic:notify`'s 25-word bound
#
# THE ACT IS NAMED IN THE OPERATOR'S VOCABULARY, never in ours: *announce that it ended*, not
# *call `close.sh`* — the announcement is the sanctioned route (`/specificate` reaches the
# writer) and the script is not the operator's to run. Every body also says what the loop will
# NOT do, because "it still stands" must read as a complete answer that costs nothing further.
#
# IT DESCRIBES THE STATE, NEVER THE PERSON. A direction filed an hour ago reads `dormant`
# immediately and correctly; "nothing has answered it yet" is a fact about the direction, and
# an accusation would be a fact about nobody.
#
# NOTHING PARSES THE ANSWER. It is prose, recorded by `record-answer.sh` exactly as every other
# answer is; acting on it stays the next run's judgement. No button, no automation.
subjects=$(printf '%s' "$out" | jq -c --arg window "14 days" '
    [ .strategies[]
      | select(.state == "overdue" or .state == "dormant")
      | . as $s
      | {key: ("direction-" + .state + ":" + .slug),
         slug: .slug, title: .title, assignees: .assignees,
         reading: .state, days_to_target: .days_to_target,
         heading: (if .state == "overdue"
                   then "the direction `" + .slug + "` has run past its target date"
                        + (if (.days_to_target != null)
                           then " (" + ((-.days_to_target) | tostring) + " day(s) ago)" else "" end)
                   else "nothing has answered the direction `" + .slug + "` in the last " + $window
                   end),
         body: (if .state == "overdue"
                then "Announce that it ended, or say it still stands — the loop will not close or change it either way."
                else "File its next move, or say it still stands — the loop will not close or change it either way."
                end)} ]' 2>/dev/null || echo '[]')
n_subjects=$(printf '%s' "$subjects" | jq 'length' 2>/dev/null || echo 0)

if [ "$repository" = "none" ]; then
    # THE REPOSITORY-LEVEL READING. There is no strategy to name and nobody to address: the
    # loop has no direction at all, which is the one state where the question is about the
    # tree rather than about somebody's direction.
    subjects='[{"key": "direction-none", "slug": "", "title": "", "assignees": "", "reading": "none", "days_to_target": null, "heading": "this repository has no live direction", "body": "File the next one when there is one, or say the loop is deliberately idle — it will not file a direction for you."}]'
    n_subjects=1
fi

summary="${n_live} live, ${n_overdue} overdue, ${n_dormant} dormant, ${n_unreadable} unreadable; repository ${repository}; ${n_subjects} to ask"

if [ "$n_subjects" -eq 0 ]; then
    emit ok "" "$summary"
fi

needs=$(printf '%s' "$subjects" | jq -c '{action: "ask_the_owner_what_becomes_of_this_direction",
    bound: "one question per reading, addressed to the strategy'"'"'s assignee (direction-none is addressed to nobody), keyed on `key` so it is asked once; the tick asks and never closes a strategy, never proposes, and never lifts a gate",
    compose: "post `heading` as the 🙋 subject and `body` as the one sentence beneath it, per workaholic:notify; the three parts are already in that order and must not be re-invented here",
    directions: .}' 2>/dev/null || echo '{}')

event="${n_overdue} direction(s) past their date, ${n_dormant} with nothing answering them"
[ "$repository" = "none" ] && event="the repository has no live direction"

emit ok "" "$summary" "$needs" "$event"
