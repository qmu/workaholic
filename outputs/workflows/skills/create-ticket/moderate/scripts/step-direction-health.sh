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
# AND SINCE 2026-08-28 THE `arrived` AND `overdue` QUESTIONS BOTH NAME THE WHOLE LEAVING
# (mission `make-a-direction-s-end-a-turn-of-the-loop-not-its-stop`): what it never reached
# beside what no direction claimed. The residue was half of it, and the half that is about the
# REPOSITORY rather than about this direction — a person asked to close a direction also needs
# to see the work of ITS OWN that never landed, and `overdue` had neither half.
#
# ASKING BEFORE THE DECISION IS THE WHOLE POINT. After the close it is a post-mortem; here it
# is evidence, in the one place a person is being asked to rule.
#
# A FIFTH READING SINCE 2026-08-29 (mission `warn-a-direction-before-its-date-silences-the-loop`):
# a direction whose date is APPROACHING, keyed `direction-expiring:<slug>`. Every reading above
# answers backwards — has the date gone, is anything answering it, has its work come in — so a
# live, in-date, `on_course` direction one day from its `target_date` produced NO question at
# all, and the day after, `past_target_date` silenced origination with the only signal being
# `direction-overdue`, asked in ARREARS. The precedent is `direction-last:<slug>`, which names
# the last live direction to its owner WHILE THEY CAN STILL ACT rather than announcing silence
# afterwards to nobody; expiry is that same event by a different cause.
#
# ITS HEADING NAMES THE DATE AND THE DAYS LEFT, because a warning that does not say how long
# somebody has is not a warning, and the leaving rides it exactly as it rides `arrived` and
# `overdue`. Its body names the same act `overdue` names, offered while it can still be taken,
# and names the successor besides — ending the LAST direction leaves the loop originating
# nothing.
#
# EVERY GATE APPLIES UNCHANGED: the asked-once ledger, the per-tick cap, the quiet hours, the
# working-day hold. It is NOT suppressed by an open ruling either, for `overdue`'s own reason —
# a ruling answers which direction a mission belongs to, and answers nothing about a date.
#
# CARRIED, NEVER COMPOSED HERE. `direction-state.sh --with-leaving` attaches
# `closing-residue.sh`'s composition to the row; this step reads that field and calls none of
# the three readers itself. It costs no extra read of the tree and no extra network call,
# because the composer takes all three facts off the row the survey already produced.
#
# THE DETAIL IS IN THE HEADING AND ONLY THE SIZE IS IN THE BODY. `workaholic:notify` bounds the
# body to one sentence of 25 words and reserves it for THE OPERATOR'S ACT, so the named slugs
# and counts ride the heading — where the residue already rode — and the body gains one short
# clause saying how much is at stake. Bounded the same way: three names, then "and N more",
# never a silent truncation.
#
# A DEGRADED LEAVING RENDERS NOTHING AND SUPPRESSES NOTHING. The question is asked without the
# evidence and the degradation is counted in the log-facing summary — our own blindness never
# silences a person's question, and is never dressed up as an empty leaving.
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
# AND `direction-last:<slug>` IS THE READING ONE STEP EARLIER (2026-08-28, mission
# `make-a-direction-s-end-a-turn-of-the-loop-not-its-stop`). `direction-none` fires only once
# every direction is ALREADY closed and is addressed to NOBODY — the loop announcing its own
# silence after the fact, to no one. The last LIVE direction is named to the person who owns
# it, while they can still act, and the body says what closing it means: the loop originates
# nothing after it. Derived from `active_count`, which the reader already emits — no new
# counter and no field on any artifact. Silent with more than one live direction, and silent
# for a direction that already has a non-`live` question this tick, because one direction
# drawing two questions is the doubling `handoff-units` and `stalled-units` were split to
# avoid. `direction-none` is byte-identical.
#
# Usage: step-direction-health.sh --tick <id> [--root <repo-root>] [--open-proposals <file>]
# Output: one JSON line
#   {"step","status","reason","summary","needs_agent":[...],"event"}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/jq-guard.sh"
STRATEGY_SCRIPTS="${SCRIPT_DIR}/../../strategy/scripts/"

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
# `--with-leaving` asks the ONE lifecycle reader to attach `closing-residue.sh`'s composition
# to every row. THE STEP NEVER READS THAT COMPOSER ITSELF, and never reads
# `attributed-work.sh` or `unattributed-work.sh` either: two readings of one fact drift, which
# is the rule the residue already established here. It costs no extra read — the composer
# carries all three facts off the row the survey already produced.
if [ -n "$OPEN" ]; then
    out=$(sh "$reader" --with-leaving --open-proposals "$OPEN" "14 days ago" "$WROOT" 2>/dev/null || true)
else
    out=$(sh "$reader" --with-leaving "14 days ago" "$WROOT" 2>/dev/null || true)
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
n_expiring=$(printf '%s' "$out" | jq -r '.counts.expiring // 0' 2>/dev/null || echo 0)
n_dormant=$(printf '%s' "$out" | jq -r '.counts.dormant // 0' 2>/dev/null || echo 0)
n_unreadable=$(printf '%s' "$out" | jq -r '.counts.unreadable // 0' 2>/dev/null || echo 0)
n_live=$(printf '%s' "$out" | jq -r '.counts.live // 0' 2>/dev/null || echo 0)

# THE QUESTION A RULING DIFF ALREADY CARRIES IS HELD (2026-08-28, mission
# `put-the-loop-s-standing-rulings-on-one-pull-request`). The `arrived` question exists to name
# the residue the reading could not see; once an open ruling pull request names EVERY mission
# in that residue, the diff already carries the whole ask and the question would send the
# operator to do by hand what they are being asked to merge.
#
# ALL OF IT OR NONE OF IT, and that bound is the safety property: a ruling naming ONE mission
# must not silence a question about a DIFFERENT one, so a partially covered residue still asks,
# with its full residue named and the partial cover said in words. An `overdue` or `dormant`
# reading is never held — those are about the DATE and the SILENCE, which no ruling answers.
# An UNREADABLE read holds nothing (`ci-retirement-turn.sh`'s discipline), and the suppression
# is DERIVED: merging or closing the ruling makes the question reachable again with no state.
held_missions='[]'
any_ruling_open=false
SUPPRESSION="${SCRIPT_DIR}/ruling-suppression.sh"
if [ -f "$SUPPRESSION" ]; then
    supp=$( ( cd "$ROOT" && sh "$SUPPRESSION" ) 2>/dev/null || true )
    if [ -n "$supp" ] && printf '%s' "$supp" | jq -e '.readable // false' >/dev/null 2>&1; then
        held_missions=$(printf '%s' "$supp" | jq -c '.held.attribution // []' 2>/dev/null || printf '[]')
        any_ruling_open=$(printf '%s' "$supp" | jq -r '.any_open // false' 2>/dev/null || printf false)
    fi
fi

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
subjects=$(printf '%s' "$out" | jq -c --arg window "14 days" \
    --argjson held "$held_missions" --arg anyruling "$any_ruling_open" '
    [ .strategies[]
      | select(.state == "overdue" or .state == "expiring" or .state == "dormant" or .state == "arrived")
      # HELD: an `arrived` reading whose whole residue an open ruling already names.
      | select((.state != "arrived")
               or (((.residue // {}) | (.readable // false)) | not)
               or (((.residue.missions // []) | length) == 0)
               or (((.residue.missions // []) | map(.slug) | map(. as $m | $held | index($m)) | any(. == null))))
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
      # WHAT IT NEVER REACHED, the other half of the leaving (2026-08-28, mission
      # `make-a-direction-s-end-a-turn-of-the-loop-not-its-stop`). Carried off `.leaving`,
      # which `direction-state.sh` attached from `closing-residue.sh` — this step composes
      # nothing and reads none of the three readers itself.
      #
      # A DEGRADED LEAVING RENDERS NOTHING AND SUPPRESSES NOTHING. The question that would
      # have been asked is asked, without the evidence, and the degradation is named in the
      # log-facing summary: our own blindness must never silence a question somebody needs, and
      # must never be dressed up as an empty leaving either.
      | ((.leaving // {}) | if ((.readable // false) and (((.waiting.count // 0) + (.waiting.missions // 0)) > 0))
           then " — never reached: " + ((.waiting.missions // 0) | tostring) + " mission(s), "
                + ((.waiting.count // 0) | tostring) + " ticket(s) still queued"
           else "" end) as $waiting_phrase
      # THE BODY CARRIES COUNTS ONLY. `workaholic:notify` bounds the body to one
      # sentence of 25 words and reserves it for THE ACT THE OPERATOR MUST TAKE, so the named detail
      # stays in the heading above and the body carries only the size of what is at stake.
      | ((.leaving // {}) | if ((.readable // false)
                                and (((.waiting.count // 0) + (.waiting.missions // 0)
                                      + (.residue.mission_count // 0)) > 0))
           then "It would leave " + (((.waiting.count // 0) + (.waiting.missions // 0)) | tostring)
                + " unreached and " + ((.residue.mission_count // 0) | tostring) + " unclaimed. "
           else "" end) as $leaving_clause
      # WHY THIS ONE STILL ASKS while a ruling is open: some of its residue the loop could not
      # judge, and an unjudged subject is exactly the one that most needs a person.
      | (if ($anyruling == "true" and .state == "arrived"
             and (((.residue // {}) | (.readable // false)))
             and (((.residue.missions // []) | length) > 0))
         then " — a ruling pull request is open for some of these; the rest the loop could not judge"
         else "" end) as $ruling_phrase
      # THE DECLARED STAGE, NAMED IN THE HEADING (2026-08-29, mission
      # `make-a-direction-s-lifecycle-a-declared-stage`). Every one of these questions names a
      # READING (`arrived`, `overdue`, `expiring`, `dormant`) and none of them named the phase
      # the operator declared, so the person was asked about a direction without being told
      # which phase they had put it in. It rides the HEADING and not the body, where the
      # residue and the leaving already ride, because `workaholic:notify` bounds the body to
      # one sentence of 25 words reserved for the act the operator must take.
      #
      # An UNREADABLE stage renders as unreadable rather than as 進行中 — the rule the
      # explicit `no strategy` rendering already holds one surface over: a default that hides
      # a failed read is worse than saying nothing. It changes NO key, so no question is
      # re-asked by this: the ledger matches the step id, never the body or the heading.
      # The generic phrase is suppressed for the two transition readings below, whose own
      # sentences already name the stage: saying it twice in one heading is noise on a line a
      # person scans.
      | (if ((.stage // "") == "") then " — stage unreadable"
         elif (.stage_declared != true) then " — no stage declared"
         elif (.state == "arrived" and .stage == "進行中") then ""
         elif (.state == "dormant" and .stage == "改良中") then ""
         else " — declared " + .stage end) as $stage_phrase
      # THE TWO TRANSITION READINGS (2026-08-29, mission
      # `make-a-direction-s-lifecycle-a-declared-stage`). The ask: stage transitions are the
      # moments worth telling a person about — THIS DIRECTION CAN NOW CUT OVER (1 to 2) and
      # THIS DIRECTION HAS SETTLED INTO OBSERVATION (2 to 3) — rather than only the backwards
      # alarms.
      #
      # THEY REFINE AN EXISTING QUESTION RATHER THAN ADDING ONE, and that is forced rather
      # than chosen. `direction-state.sh` projects `quiescent` to `arrived` and `dormant` to
      # `dormant` in a fixed precedence, so a 進行中 direction whose work is all in ALWAYS
      # reads `arrived` and a quiet 改良中 one ALWAYS reads `dormant`. A transition question
      # added beside those would either double-ask one direction — the doubling `handoff-units`
      # and `stalled-units` were split to avoid — or never fire at all. So the STAGE decides
      # WHICH question the same evidence draws:
      #
      #   arrived + 進行中  ->  cutover   your work is in; can this be cut over now?
      #   dormant + 改良中  ->  settled   improving has gone quiet; is this observation now?
      #
      # Every other combination is byte-identical, and the precedence in `direction-state.sh`
      # is untouched — this is the STEP choosing its wording, not a sixth lifecycle value.
      #
      # THE COST IS STATED: the key changes for those two combinations, so a direction already
      # asked `direction-arrived` may be asked `direction-cutover` once. That is one extra
      # question ever, and it is the better-aimed one — which is the whole ask.
      #
      # THE STAGE IS NEVER INFERRED FROM STUCKNESS. Both candidate sets are built only from
      # readings that describe WORK LANDING (`quiescent`, `dormant` — attribution terms), and
      # never from a handoff, a block, a stale claim, an undelivered unit or a queue that will
      # not drain: those occur in ANY phase, so none of them is evidence about a stage.
      #
      # AND IT IS A CANDIDATE, NEVER A VERDICT — `arrived`s own standing rule. Whether a
      # toggle can be flipped is a fact no script can see, so the question describes the
      # evidence and asks; the operator announcement is what moves the field, and this tick
      # moves nothing.
      # ONLY A DECLARED STAGE REFINES A QUESTION. `absent means 進行中` is the right reading
      # everywhere, and the wrong thing to QUOTE BACK: a heading saying "still declared 進行中"
      # of a direction nobody staged asserts a declaration that does not exist, which is the
      # same class of error as rendering an unreadable stage as the default. So a repository
      # that has not adopted the vocabulary keeps every question it had, byte for byte, and the
      # refinement arrives only once an operator has actually declared a phase.
      | (if (.stage_declared != true) then .state
         elif (.state == "arrived" and .stage == "進行中") then "cutover"
         elif (.state == "dormant" and .stage == "改良中") then "settled"
         else .state end) as $reading
      | {key: ("direction-" + $reading + ":" + .slug),
         slug: .slug, title: .title, assignees: .assignees,
         reading: $reading, days_to_target: .days_to_target,
         residue: (.residue // {}),
         leaving: (.leaving // {}),
         heading: ((if $reading == "cutover"
                   then "the direction `" + .slug + "` has its work in and is still declared 進行中"
                        + (if ((.landed // 0) > 0)
                           then " (" + ((.landed) | tostring) + " item(s) landed)" else "" end)
                        + $waiting_phrase + $residue_phrase
                   elif $reading == "settled"
                   then "the direction `" + .slug + "` has been quiet for " + $window
                        + " while declared 改良中"
                        + $waiting_phrase + $residue_phrase
                   elif .state == "overdue"
                   then "the direction `" + .slug + "` has run past its target date"
                        + (if (.days_to_target != null)
                           then " (" + ((-.days_to_target) | tostring) + " day(s) ago)" else "" end)
                        + $waiting_phrase + $residue_phrase
                   # EXPIRING (2026-08-29). The heading names the DATE and the DAYS LEFT, because
                   # the whole point of asking early is that the person can still act, and a
                   # warning that does not say how long they have is not a warning. The leaving
                   # rides it exactly as it rides the other two.
                   elif .state == "expiring"
                   then "the direction `" + .slug + "` reaches its target date"
                        + (if (.days_to_target != null)
                           then (if (.days_to_target == 0) then " today"
                                 else " in " + ((.days_to_target) | tostring) + " day(s)" end)
                           else "" end)
                        + (if (.target_date != "") then " (" + .target_date + ")" else "" end)
                        + $waiting_phrase + $residue_phrase
                   elif .state == "arrived"
                   then "the direction `" + .slug + "` has its work in"
                        + (if ((.landed // 0) > 0)
                           then " (" + ((.landed) | tostring) + " item(s) landed" +
                                (if (.target_date != "") then ", dated " + .target_date else "" end) + ")"
                           else "" end)
                        + $waiting_phrase + $residue_phrase + $ruling_phrase
                   else "nothing has answered the direction `" + .slug + "` in the last " + $window
                   end) + $stage_phrase),
         body: (if $reading == "cutover"
                then $leaving_clause + "The evidence cannot see whether it can be cut over — only you can. Move it to 改良中, or say it still stands."
                elif $reading == "settled"
                then $leaving_clause + "Improving looks finished. Move it to 観察中 and the loop stops originating for it, or say it still stands."
                elif .state == "overdue"
                then $leaving_clause + "Re-date it, announce that it ended, or say it still stands — the loop carries what you announce and never decides either for you."
                # The act is the same one `overdue` names, offered while it can still be taken —
                # and the successor is named because ending the LAST direction leaves the loop
                # originating nothing, which is what `direction-last` says one reading earlier.
                elif .state == "expiring"
                then $leaving_clause + "Re-date it, announce a successor when you end it, or say it still stands — the loop carries what you announce and decides nothing."
                elif .state == "arrived"
                then $leaving_clause + "Everything attributed to it has landed. Announce that it ended, or say it still stands — the loop closes nothing."
                else "File its next move, or say it still stands — the loop will not close or change it either way."
                end)} ]' 2>/dev/null || echo '[]')
n_subjects=$(printf '%s' "$subjects" | jq 'length' 2>/dev/null || echo 0)

# ═══ THE LAST LIVE DIRECTION, SAID BEFORE THE SILENCE (2026-08-28, mission
# `make-a-direction-s-end-a-turn-of-the-loop-not-its-stop`) ═════════════════════════════
#
# `direction-none` fires only once EVERY direction is already closed, and it is addressed to
# NOBODY: the loop announces its own silence after the fact, to no one. The reading that
# matters is one step earlier — the LAST live direction, named to the person who owns it,
# while they can still act on it.
#
# DERIVED, NOT COUNTED. `active_count` is already on the lifecycle reader's output; there is
# no new counter here and no field on any artifact.
#
# WITH MORE THAN ONE LIVE DIRECTION IT IS SILENT. A general "how many directions" report is
# the status line addressed to nobody this repository has twice retired.
#
# ONE DIRECTION NEVER DRAWS TWO QUESTIONS. When that single direction already has a
# non-`live` reading, the question for THAT reading is asked and this one is not: `arrived`,
# `overdue` and `dormant` already put the same direction, the same leaving and a sharper act
# in front of the same person, and a second question beside it is the doubling
# `handoff-units` and `stalled-units` were split to avoid.
#
# IT ASKS AND NOTHING ELSE. Nothing is closed, proposed or lifted, and `direction-none` is
# exactly what it was — it still fires when every direction is closed, still addressed to
# nobody.
active_count=$(printf '%s' "$out" | jq -r '.active_count // 0' 2>/dev/null || echo 0)
if [ "$repository" != "none" ] && [ "$active_count" -eq 1 ]; then
    subjects=$(printf '%s' "$out" | jq -c --argjson subjects "$subjects" '
        (.strategies | first) as $s
        | if ($s == null) or ([$subjects[] | select(.slug == $s.slug)] | length > 0)
          then $subjects
          else $subjects + [
            ($s | ((.leaving // {}) | if ((.readable // false)
                                         and (((.waiting.count // 0) + (.waiting.missions // 0)
                                               + (.residue.mission_count // 0)) > 0))
                     then " — it would leave " + (((.waiting.count // 0) + (.waiting.missions // 0)) | tostring)
                          + " unreached and " + ((.residue.mission_count // 0) | tostring) + " unclaimed"
                     else "" end) as $leaving_phrase
               | {key: ("direction-last:" + .slug),
                  slug: .slug, title: .title, assignees: .assignees,
                  reading: "last_live", days_to_target: .days_to_target,
                  residue: (.residue // {}), leaving: (.leaving // {}),
                  # The declared stage rides this heading too (2026-08-29) — it names a
                  # direction, so it names the phase the operator put that direction in, on
                  # the same terms as every other heading in this step.
                  heading: ("`" + .slug + "` is the only live direction left" + $leaving_phrase
                            + (if ((.stage // "") == "") then " — stage unreadable"
                               elif (.stage_declared != true) then " — no stage declared"
                               else " — declared " + .stage end)),
                  body: "Once no live direction remains the loop originates nothing. Announce a successor when you end it, or say it still stands."}) ]
          end' 2>/dev/null || printf '%s' "$subjects")
    n_subjects=$(printf '%s' "$subjects" | jq 'length' 2>/dev/null || echo 0)
fi

if [ "$repository" = "none" ]; then
    # THE REPOSITORY-LEVEL READING. There is no strategy to name and nobody to address: the
    # loop has no direction at all, which is the one state where the question is about the
    # tree rather than about somebody's direction.
    subjects='[{"key": "direction-none", "slug": "", "title": "", "assignees": "", "reading": "none", "days_to_target": null, "heading": "this repository has no live direction", "body": "File the next one when there is one, or say the loop is deliberately idle — it will not file a direction for you."}]'
    n_subjects=1
fi

# A LEAVING WE COULD NOT COMPOSE IS NAMED IN THE LOG, and nowhere else. It asks nothing extra
# and silences nothing: the question stands, without its evidence, and the count says so to
# whoever diagnoses the tick. Our own degradation never becomes a person's question — the rule
# `unreadable` already holds here.
n_leaving_degraded=$(printf '%s' "$subjects" | jq '[.[] | select(has("leaving")) | select((.leaving.readable // false) | not)] | length' 2>/dev/null || echo 0)

n_last_live=$(printf '%s' "$subjects" | jq '[.[] | select(.reading == "last_live")] | length' 2>/dev/null || echo 0)

summary="${n_live} live, ${n_arrived} arrived, ${n_overdue} overdue, ${n_expiring} expiring, ${n_dormant} dormant, ${n_unreadable} unreadable; repository ${repository}; ${n_last_live} last-live; ${n_subjects} to ask; ${n_leaving_degraded} leaving unreadable"

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
# EXPIRING FOLLOWS `overdue` IN THE PHRASE, in the reader's own precedence order: a date that
# has gone is read before one that is coming, so a reader meets the two facts in the order the
# lifecycle ranks them.
if [ "$n_expiring" -gt 0 ]; then
    if [ "$n_expiring" -eq 1 ]; then ephrase="a direction is about to reach its date"
    else ephrase="${n_expiring} directions are about to reach their dates"; fi
    phrase="${phrase:+${phrase}; }${ephrase}"
fi
if [ "$n_dormant" -gt 0 ]; then
    if [ "$n_dormant" -eq 1 ]; then dphrase="a direction has nothing answering it"
    else dphrase="${n_dormant} directions have nothing answering them"; fi
    phrase="${phrase:+${phrase}; }${dphrase}"
fi
# THE LAST LIVE DIRECTION IS A REPOSITORY EVENT in the fullest sense — the loop is one close
# away from originating nothing — so it earns its own line, and it must not be silent just
# because none of the three trouble readings fired.
if [ "$n_last_live" -gt 0 ]; then
    phrase="${phrase:+${phrase}; }only one live direction is left"
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
