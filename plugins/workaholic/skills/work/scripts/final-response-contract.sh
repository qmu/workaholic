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
#   interruption_kind  "routine" | "review_required"                          (required)
#   instance_id        the loop's own instance ID, set once at `start`         (required)
#   anchor             the loop's startup anchor, epoch seconds                (required)
#   control            the coordinator's current mode, "running" | "held"    (default running)
#   continue_on        {instance_id, anchor} the turn returns to              (default: the same)
#   continuation       {kind, id, next_due} what carries the loop after the turn ends
#                      (required on the `resume` path; not required on `review_handoff`):
#                        kind      "interruptible_parent" | "same_chat_schedule" (closed set)
#                        id        the parent's or the schedule's own identifier
#                        next_due  epoch seconds the continuation next fires
#   hold_persisted     whether `hold` (explicit:true) is already persisted    (default false)
#   question           the sentence the turn intends to ask, or null          (default null)
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
#   input_required, invalid_facts (including a `continuation` outside the closed set),
#   hold_not_persisted (review_required without a persisted hold),
#   question_mismatch (a review-required question other than the one sentence, or a routine
#   turn that intends to ask one), anchor_moved (continue_on names another instance or anchor),
#   continuation_unproved (a routine turn naming no continuation).

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
  (.interruption_kind == "routine" or .interruption_kind == "review_required") and
  (.instance_id | type == "string" and test("^[A-Za-z0-9][A-Za-z0-9._-]*$")) and
  (.anchor | type == "number" and floor == . and . >= 0) and
  ((.control == null) or .control == "running" or .control == "held") and
  ((.hold_persisted == null) or (.hold_persisted | type == "boolean")) and
  ((.question == null) or (.question | type == "string")) and
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
  elif .interruption_kind == "review_required" and ($held | not) then "hold_not_persisted"
  elif .interruption_kind == "review_required" and $question != $q then "question_mismatch"
  elif .interruption_kind == "routine" and $question != "" then "question_mismatch"
  elif .interruption_kind == "routine" and .continuation == null then "continuation_unproved"
  else "" end
' "$INPUT")

if [ -n "$reason" ]; then
  printf '{"ok":false,"reason":"%s"}\n' "$reason"
  exit 2
fi

jq -c --arg q "$QUESTION" '
  (.control // "running") as $control |
  (.continuation // null) as $continuation |
  if .interruption_kind == "review_required" then
    {ok:true, path:"review_handoff", final_response:true, question:$q,
     instance_id:.instance_id, anchor:.anchor, control:"held", hold_stands:true,
     second_start:false, continuation:$continuation, reason:""}
  else
    {ok:true, path:"resume", final_response:false, question:null,
     instance_id:.instance_id, anchor:.anchor, control:$control,
     hold_stands:($control == "held"), second_start:false,
     continuation:$continuation, reason:""}
  end
' "$INPUT"
