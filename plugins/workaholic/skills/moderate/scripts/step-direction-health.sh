#!/bin/sh -eu
# direction-health — a direction that has run out of date, that nothing is answering, or whose
# work is all in, said to the person who owns it. It runs beside `strategy-pace` and before the
# check-in, which is what asks; `reference/workflow.md` states its contract.
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
# A FOURTH READING SINCE 2026-08-27 (mission `say-when-a-direction-has-arrived`): a direction
# whose work is ALL IN. Every reading above answers *is this direction in trouble*; none
# answered *has it arrived*, so a finished direction looked exactly like one still running —
# and once its date passed, the loop reported that SUCCESS as an hourly `direction-overdue`
# question. `arrived` outranks `overdue` in the reader's precedence for that reason, and the
# question keyed `direction-arrived:<slug>` is what reaches the one person who can rule on it.
#
# THE `arrived` BODY IS A DESCRIPTION OF THE READING, NEVER AN ASSERTION THAT THE DIRECTION IS
# FINISHED. A strategy's "Reached when" is prose no script reads, so the reading is a CANDIDATE:
# it says everything attributed has landed and nothing is waiting, and asks. The same discipline
# `dormant` is held to — describe the state, never the person, and never claim more than the
# reading supports.
#
# AND SINCE 2026-08-28 THE `arrived` QUESTION NAMES WHAT THE READING COULD NOT SEE (mission
# `say-what-the-direction-could-not-see-before-calling-it-arrived`): the unattributed active
# missions, BY SLUG, with their queued-ticket counts. "Everything attributed has landed" was
# true and partial, and the operator had no way to see which half they were being asked to
# rule on — measured, a strategy read `quiescent: true` with 125 landed items while four
# active missions and ten queued tickets belonged to no direction at all.
#
# THE RESIDUE IS THE REASON TO CHECK, NOT EVIDENCE THAT THEY SHOULD NOT. The register does not
# move: the question still says *this looks finished, and here is what I could not see*, never
# *this is finished*. Nothing else about the step moves either — the key
# (`direction-arrived:<slug>`), the asked-once gate, the addressee and the per-tick cap are
# exactly what they were, and changing a body does not re-ask a question, since the ledger keys
# on the step id derived from `key` rather than on the text.
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
# IT ASKS; IT NEVER CLOSES, NEVER PROPOSES, NEVER AMENDS AND NEVER LIFTS A GATE. The strategy
# artifact has three writers (`create.sh` creates, `amend.sh` revises the three revisable parts,
# `close.sh` ends) and this is none of them. A dormant direction stays eligible; an overdue one
# stays refused. Ending or revising a direction is announced by the operator and reaches
# `close.sh` or `amend.sh` through `/specificate`, never from here — the pin in
# `test-workflow-scripts.mjs` holds exactly that separation, and conflating a READING with a
# WRITE is what it exists to catch.
#
# THE `overdue` BODY NAMES THREE ACTS SINCE 2026-08-27, and the `dormant` body deliberately
# names two. Re-dating became something the operator can do THROUGH the loop, so the question
# about an expired direction must offer it. A direction nothing is answering is not thereby
# mis-dated, so widening `dormant` by reflex would name an act its reading gives no reason to
# take. The closing clause is restated rather than dropped: the loop carries the revision the
# operator announces and decides none, which is what "it will not change it either way" always
# meant. Changing a body does NOT re-ask the question — the ledger keys on the step id derived
# from `key`, not on the text, so an operator already asked about an overdue direction will not
# see the new wording for that direction.
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
n_arrived=$(printf '%s' "$out" | jq -r '.counts.arrived // 0' 2>/dev/null || echo 0)
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
      | select(.state == "overdue" or .state == "dormant" or .state == "arrived")
      | . as $s
      # THE RESIDUE, RENDERED FOR THE ARRIVAL QUESTION (2026-08-28, mission
      # `say-what-the-direction-could-not-see-before-calling-it-arrived`). A count alone costs
      # the operator the same hand-read it costs them today — they learn the answer is partial
      # and still cannot see what was missing — so each unattributed mission is named BY SLUG
      # with its queued-ticket count.
      #
      # BOUNDED, AND WHAT IS CUT IS COUNTED. A tree with many unattributed missions must not
      # produce an unreadable question; three names then "and N more", never a silent
      # truncation -- the same shape the link list on the root already uses.
      #
      # CARRIED, NEVER RE-READ. `.residue` is the single read the survey made, projected
      # through `direction-state.sh`; this step must not call `unattributed-work.sh` itself,
      # or two readings of one fact will drift.
      #
      # A DEGRADED RESIDUE READ NEVER REACHES HERE: it makes `quiescent` false upstream, so
      # there is no `arrived` reading and therefore no question. The empty branch below is the
      # honest fallback for a row that carried no residue at all, not a second policy.
      | ((.residue // {}) | if ((.readable // false) and (((.missions // []) | length) > 0))
           then ((.missions | map(.slug + " (" + (((.queued // 0)) | tostring) + " queued)")) as $n
                 | " — not attributed to any direction: "
                   + (if (($n | length) > 3)
                      then (($n[0:3] | join(", ")) + ", and " + ((($n | length) - 3) | tostring) + " more")
                      else ($n | join(", ")) end))
           else "" end) as $residue_phrase
      | {key: ("direction-" + .state + ":" + .slug),
         slug: .slug, title: .title, assignees: .assignees,
         reading: .state, days_to_target: .days_to_target,
         residue: (.residue // {}),
         heading: (if .state == "overdue"
                   then "the direction `" + .slug + "` has run past its target date"
                        + (if (.days_to_target != null)
                           then " (" + ((-.days_to_target) | tostring) + " day(s) ago)" else "" end)
                   elif .state == "arrived"
                   then "the direction `" + .slug + "` has its work in"
                        + (if ((.landed // 0) > 0)
                           then " (" + ((.landed) | tostring) + " item(s) landed" +
                                (if (.target_date != "") then ", dated " + .target_date else "" end) + ")"
                           else "" end)
                        + $residue_phrase
                   else "nothing has answered the direction `" + .slug + "` in the last " + $window
                   end),
         body: (if .state == "overdue"
                then "Re-date it, announce that it ended, or say it still stands — the loop carries what you announce and never decides either for you."
                elif .state == "arrived"
                then "Everything attributed to it has landed and nothing is waiting. Announce that it ended, or say it still stands — the loop closes nothing."
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

summary="${n_live} live, ${n_arrived} arrived, ${n_overdue} overdue, ${n_dormant} dormant, ${n_unreadable} unreadable; repository ${repository}; ${n_subjects} to ask"

if [ "$n_subjects" -eq 0 ]; then
    emit ok "" "$summary"
fi

needs=$(printf '%s' "$subjects" | jq -c '{action: "ask_the_owner_what_becomes_of_this_direction",
    bound: "one question per reading, addressed to the strategy'"'"'s assignee (direction-none is addressed to nobody), keyed on `key` so it is asked once; the tick asks and never closes a strategy, never proposes, and never lifts a gate",
    compose: "post `heading` as the 🙋 subject and `body` as the one sentence beneath it, per workaholic:notify; the three parts are already in that order and must not be re-invented here",
    directions: .}' 2>/dev/null || echo '{}')

# THE EVENT NAMES A REPOSITORY EVENT, NOT A COUNTER OF WHAT THE STEP EXAMINED (2026-08-23's
# rule, applied here). `0 overdue, 0 dormant` is the tick's bookkeeping and belongs in the log;
# what the root carries is *a direction has run past its date*. The step supplies it because it
# knows what its reading means, and the renderer does not.
#
# AN ALL-`live` TICK SUPPLIES THE EMPTY STRING and therefore renders no line — the early
# `emit ok "" "$summary"` above, which is the independent guard against a "nothing happened"
# line reaching the root even when the change diff calls this step changed.
#
# AND SO DOES A TICK WHOSE ONLY NON-`live` READING IS `unreadable`. That is our own degradation,
# not something that happened to the repository, and it is the same reason `unreadable` is never
# asked about; it stays in the log-facing summary, which keeps every count.
#
# `arrived` LEADS THE PHRASE, in the reader's own precedence order. *A direction's work is all
# in* is a repository event in the fullest sense — something finished — and reading it after a
# lateness clause about a different direction is how a success gets read as a failure, which is
# the defect this reading exists to remove.
phrase=""
if [ "$n_arrived" -gt 0 ]; then
    if [ "$n_arrived" -eq 1 ]; then phrase="a direction has its work in"
    else phrase="${n_arrived} directions have their work in"; fi
fi
if [ "$n_overdue" -gt 0 ]; then
    if [ "$n_overdue" -eq 1 ]; then ophrase="a direction has run past its date"
    else ophrase="${n_overdue} directions have run past their date"; fi
    phrase="${phrase:+${phrase}; }${ophrase}"
fi
if [ "$n_dormant" -gt 0 ]; then
    if [ "$n_dormant" -eq 1 ]; then dphrase="a direction has nothing answering it"
    else dphrase="${n_dormant} directions have nothing answering them"; fi
    phrase="${phrase:+${phrase}; }${dphrase}"
fi

# EVERY ROOT LINE LINKS ITS ITEM, so a person following the direction reaches the artifact
# rather than the tick. The base URL is derived from the local remote — no network call — and
# an absent remote degrades to the repo-relative path rather than to a broken link.
remote=$(git config --get remote.origin.url 2>/dev/null || true)
case "$remote" in
    git@*:*) base="https://github.com/$(printf '%s' "$remote" | sed 's/^git@[^:]*://; s/\.git$//')" ;;
    https://*) base=$(printf '%s' "$remote" | sed 's/\.git$//') ;;
    *) base="" ;;
esac
links=$(printf '%s' "$subjects" | jq -r --arg base "$base" '
    [ .[] | select(.slug != "")
      | if $base == "" then ".workaholic/strategies/" + .slug + ".md"
        else "<" + $base + "/blob/main/.workaholic/strategies/" + .slug + ".md|" + .slug + ">" end ]
    | (if (length > 3) then (.[0:3] + ["and " + ((length - 3) | tostring) + " more"]) else . end)
    | join(", ")' 2>/dev/null || echo "")

event="${phrase}${links:+ — ${links}}"
# The repository-level reading has no strategy to link: there is none, which is the finding.
[ "$repository" = "none" ] && event="the repository has no live direction"

emit ok "" "$summary" "$needs" "$event"
