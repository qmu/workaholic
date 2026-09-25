#!/bin/sh -eu
# Decide which conversation path a native /work turn takes after a mid-loop comment.
# Usage: final-response-contract.sh --input <facts.json>
#
# The agent still writes the commentary or the final response; this reader owns the
# load-bearing facts of the turn, the way acknowledgement-contract.sh owns a receipt's.
# It reads a sentence nowhere and classifies nothing by content: `interruption_kind` is
# the judgement the run already wrote out (routine unless a human must read the final
# comment before work may continue), and the reader checks only that the facts around
# that judgement hold. It writes nothing, ever; a refusal is stdout JSON and exit 2.
#
# Facts:
#   interruption_kind  "routine" | "task_review" | "review_required"          (required)
#   instance_id        the loop's own instance ID, set once at `start`         (required)
#   anchor             the loop's startup anchor, epoch seconds                (required)
#   now                the moment of the turn, epoch seconds                   (see below)
#   control            the coordinator's current mode, "running" | "held"    (default running)
#   continue_on        {instance_id, anchor} the turn returns to              (default: the same)
#   continuation       {kind, id, next_due} what carries the loop after the turn ends
#                      (required on the `resume` path; not required on `review_handoff`):
#                        kind      "interruptible_parent" | "same_chat_schedule" (closed set)
#                        id        the parent's or the schedule's own identifier
#                        next_due  epoch seconds the continuation next fires
#   intends_final_response  whether the turn intends to emit one   (boolean, default false)
#   host_goal          "active" | "paused" (default active)
#   native_parent      {interruptible_wait,worker_results}; when the host goal is paused and
#                      both are true, the routine path must return to an interruptible parent
#                      rather than substituting worker liveness for observation
#   hold_persisted     whether `hold` (explicit:true) is already persisted    (default false)
#   question           the sentence the turn intends to ask, or null          (default null)
#   blocked_on         what is blocking ONE unit, from a closed set, or null   (default null):
#                        "merge_authority"      the pull request is green and merging it is
#                                               somebody else's act
#                        "pull_request_review"  a person is mid-review on it
#                        "verification_handoff" a declared verification cannot run here
#                      Any of the three is a PER-UNIT wait and may never become a global hold.
#   unit               the unit the wait belongs to, echoed back               (default null)
#
# Answers:
#   path             "resume"          a routine interruption: commentary, then the same loop --
#                                      same instance, same anchor, no second `start`, no final
#                                      response -- returning to a NAMED continuation, echoed
#                                      back as `continuation`. Under a standing hold the hold
#                                      STANDS (`hold_stands: true`): the answer is commentary and
#                                      no `resume` event is emitted -- time never resumes a hold
#                                      and neither does an ordinary question.
#                    "review_handoff"  a review-required handoff: `hold` is persisted first, the
#                                      final response's own text is exactly the one question, and
#                                      the loop stays held until the human's explicit `resume`.
#                                      A held loop is waiting on a person, so no continuation is
#                                      required; one that was named is echoed back.
#   final_response   false | true
#   question         null, or the one sentence
#   control          the mode the coordinator is left in: "running" or "held"
#   continuation     the continuation the turn returns to, or null
#   next_action      "wait_interruptibly" when the same native parent must observe again
#   collect_results  whether that parent must consume child terminal results
#   blocked_on       the per-unit blocker this wait belongs to, or null
#   unit             the unit it belongs to, or null
#
# Why a blocked merge is a TASK wait and never a global hold (2026-09-17, ticket
# `20260917141324`). Measured: a green pull request whose merge is another authority's act was
# classified `review_required` -- the criterion one section over says *a refusal that stops the
# work is review-required*, and a refused merge reads like one -- so the parent persisted `hold`,
# asked the one question and ended, with independent runnable work queued behind it. The refusal
# stops THAT UNIT, not the loop. `blocked_on` names the three per-unit blockers the loop actually
# has, and `review_required` beside any of them is refused `unit_wait_is_not_global_hold`: the
# same shape `task_wait_is_not_global_hold` already had, pointed at the classification rather than
# at the control mode. The reader still classifies nothing by content -- it reads no sentence and
# no refusal word; `blocked_on` is a fact the run writes out, like `interruption_kind` itself.
#
# And a task wait keeps the same parent observing. `task_wait` answered `next_action: null` and
# `collect_results: false` whatever the host goal was, so a paused-goal parent with interruptible
# wait available was told nothing about continuing and ended -- the other half of the same
# measured stop. The `$native_continue` derivation the routine path already made is now read on
# both paths, because a unit's wait is not a reason for the LOOP to stop observing.
#
# Why a NAMED continuation is not yet a LIVE one (2026-09-21, ticket
# `20260921180208`). The `continuation_unproved` rung below proved a routine turn had named
# something; nothing compared what it named against the clock, so a continuation whose deadline
# had already passed satisfied the contract, this reader answered `path: "resume",
# final_response: false`, and the turn yielded to nothing. Measured before the repair: a routine
# turn naming `next_due: 1758400060` answered `ok: true, path: "resume"` while
# runtime/scripts/lib/coordinator.jq, handed the same continuation, answered
# `resumed: false, resumed_reason: "continuation_lapsed"` -- the derivation existed and the
# gate that yields the turn did not consult it.
#
# `next_due < now` IS ONE RULE WITH TWO CALL SITES, and this is one of them. The other is
# `coordinator.jq`'s `$not_resumed` ladder, which spells the same comparison and emits the same
# word `continuation_lapsed`; that program is a full reducer body rather than a jq module, so it
# cannot be included here, and the two copies are kept in step by `scripts/test-workflow-scripts.mjs`
# rather than by a shared file. Neither spelling may drift from the other, and no third comparison
# of a continuation against a clock may be added anywhere.
#
# `now` is therefore REQUIRED on any input naming a continuation, and refused `invalid_facts`
# when absent or not epoch seconds -- a caller must not obtain a pass by omitting the clock,
# which is exactly the pass a defaulted `now` would hand it. An input naming NO continuation
# (a `review_handoff`) needs none and is byte-identical to before.
#
# And FAIL CLOSED here is a refusal, not a suppression. This reader writes nothing, ever, and
# cannot stop a run from emitting text: `intends_final_response` is the run's own declaration of
# what it means to emit, in the shape `interruption_kind` and `blocked_on` already have, and a
# `routine` turn that declares it is refused `routine_emits_no_final_response`. What the refusal
# buys is that a run which asks the contract gets an unambiguous *no* with a name, and a run that
# emits one anyway leaves a receipt saying the contract refused it. Absent means false, so every
# caller that declares nothing behaves exactly as it did.
#
# Why the continuation is a fact and not a sentence (2026-09-11, issue #1151): a native
# session reported that it had returned to the loop, emitted a final response and stopped
# observing while the coordinator record still read `running`. The classification above
# proved nothing about what carried the loop after the turn -- `resume` said
# `final_response: false` and the run was trusted to keep going. A routine turn is now
# `resume` only when a continuation is named and proved; the coordinator's own `resumed`
# reading (runtime/scripts/lib/coordinator.jq) distinguishes `running` (a control mode)
# from resumed (a control mode PLUS a live continuation).
#
# Refusals (exit 2, nothing written):
#   input_required, invalid_facts (including a `continuation` outside the closed set, and a
#   `continuation` named with no `now`),
#   hold_not_persisted (review_required without a persisted hold),
#   question_mismatch (a review-required question other than the one sentence, or a routine
#   turn that intends to ask one), anchor_moved (continue_on names another instance or anchor),
#   routine_emits_no_final_response (a routine turn declaring `intends_final_response`),
#   continuation_unproved (a routine turn naming no continuation),
#   continuation_lapsed (a routine turn whose named continuation's `next_due` has passed),
#   task_wait_is_not_global_hold (a task wait under a standing hold),
#   unit_wait_is_not_global_hold (`review_required` naming a per-unit `blocked_on`).
#
# The two new rungs are bounded to `routine` on purpose: it is the path this reader answers
# `final_response: false` on and lets the turn end, which is the act the ask names. No closed
# set widened -- `interruption_kind` keeps its three values, `continuation.kind` its two,
# `blocked_on` its three -- and `path` gains no fourth value.

QUESTION='ループを再開してよろしいですか？'
INPUT=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --input) INPUT=${2:-}; shift 2 ;;
    *) printf '{"ok":false,"reason":"unknown_argument"}\n'; exit 2 ;;
  esac
done

[ -n "$INPUT" ] && [ -s "$INPUT" ] || {
  printf '{"ok":false,"reason":"input_required"}\n'
  exit 2
}

if ! jq -e '
  type == "object" and
  (.interruption_kind == "routine" or .interruption_kind == "task_review" or .interruption_kind == "review_required") and
  (.instance_id | type == "string" and test("^[A-Za-z0-9][A-Za-z0-9._-]*$")) and
  (.anchor | type == "number" and floor == . and . >= 0) and
  ((.now == null) or (.now | type == "number" and floor == . and . >= 0)) and
  ((.continuation == null) or (.now != null)) and
  ((.control == null) or .control == "running" or .control == "held") and
  ((.hold_persisted == null) or (.hold_persisted | type == "boolean")) and
  ((.intends_final_response == null) or (.intends_final_response | type == "boolean")) and
  ((.question == null) or (.question | type == "string")) and
  ((.blocked_on == null) or .blocked_on == "merge_authority" or
   .blocked_on == "pull_request_review" or .blocked_on == "verification_handoff") and
  ((.unit == null) or (.unit | type == "string" and length > 0)) and
  ((.host_goal == null) or .host_goal == "active" or .host_goal == "paused") and
  ((.native_parent == null) or
    ((.native_parent | type == "object") and
     (.native_parent.interruptible_wait | type == "boolean") and
     (.native_parent.worker_results | type == "boolean"))) and
  ((.continue_on == null) or
    ((.continue_on | type == "object") and
     (.continue_on.instance_id | type == "string") and
     (.continue_on.anchor | type == "number" and floor == . and . >= 0))) and
  ((.continuation == null) or
    ((.continuation | type == "object") and
     (.continuation.kind == "interruptible_parent" or .continuation.kind == "same_chat_schedule") and
     (.continuation.id | type == "string" and length > 0) and
     (.continuation.next_due | type == "number" and floor == . and . >= 0)))
' "$INPUT" >/dev/null 2>&1; then
  printf '{"ok":false,"reason":"invalid_facts"}\n'
  exit 2
fi

reason=$(jq -r --arg q "$QUESTION" '
  (.control // "running") as $control |
  (.hold_persisted // false) as $held |
  (.question // "") as $question |
  if .continue_on != null and
     (.continue_on.instance_id != .instance_id or .continue_on.anchor != .anchor) then "anchor_moved"
  elif .interruption_kind == "task_review" and $control == "held" then "task_wait_is_not_global_hold"
  elif .interruption_kind == "task_review" and .continuation == null then "continuation_unproved"
  elif .interruption_kind == "review_required" and .blocked_on != null then "unit_wait_is_not_global_hold"
  elif .interruption_kind == "review_required" and ($held | not) then "hold_not_persisted"
  elif .interruption_kind == "review_required" and $question != $q then "question_mismatch"
  elif .interruption_kind == "routine" and $question != "" then "question_mismatch"
  elif .interruption_kind == "routine" and (.intends_final_response // false)
    then "routine_emits_no_final_response"
  elif .interruption_kind == "routine" and .continuation == null then "continuation_unproved"
  # `next_due < now` -- one rule, two call sites; the other is the `$not_resumed` ladder in
  # runtime/scripts/lib/coordinator.jq. Neither spelling may drift from the other.
  elif .interruption_kind == "routine" and .continuation.next_due < .now then "continuation_lapsed"
  elif .interruption_kind == "routine" and (.host_goal // "active") == "paused" and
       (.native_parent.interruptible_wait // false) and (.native_parent.worker_results // false) and
       .continuation.kind != "interruptible_parent" then "native_parent_not_continued"
  else "" end
' "$INPUT")

if [ -n "$reason" ]; then
  printf '{"ok":false,"reason":"%s"}\n' "$reason"
  exit 2
fi

jq -c --arg q "$QUESTION" '
  (.control // "running") as $control |
  (.continuation // null) as $continuation |
  (((.host_goal // "active") == "paused") and
   (.native_parent.interruptible_wait // false) and
   (.native_parent.worker_results // false)) as $native_continue |
  if .interruption_kind == "review_required" then
    {ok:true, path:"review_handoff", final_response:true, question:$q,
     instance_id:.instance_id, anchor:.anchor, control:"held", hold_stands:true,
     second_start:false, continuation:$continuation, next_action:null,
     collect_results:false, blocked_on:null, unit:(.unit // null), reason:""}
  elif .interruption_kind == "task_review" then
    {ok:true, path:"task_wait", final_response:false, question:null,
     instance_id:.instance_id, anchor:.anchor, control:"running", hold_stands:false,
     second_start:false, continuation:$continuation,
     next_action:(if $native_continue then "wait_interruptibly" else null end),
     collect_results:$native_continue,
     blocked_on:(.blocked_on // null), unit:(.unit // null), reason:""}
  else
    {ok:true, path:"resume", final_response:false, question:null,
     instance_id:.instance_id, anchor:.anchor, control:$control,
     hold_stands:($control == "held"), second_start:false,
     continuation:$continuation,
     next_action:(if $native_continue then "wait_interruptibly" else null end),
     collect_results:$native_continue,
     blocked_on:(.blocked_on // null), unit:(.unit // null), reason:""}
  end
' "$INPUT"
