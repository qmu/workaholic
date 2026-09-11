---
created_at: 2026-09-11T14:25:19+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260911142410-resume-the-native-work-loop-after-ordinary-mid-loop-comments.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
merge_policy:
verification_handoff: 
claim: work-20260911-143422
---

# Resume the native work loop after ordinary mid-loop comments

## Overview

The operator's ask (issue #1147, record
`20260911142410-resume-the-native-work-loop-after-ordinary-mid-loop-comments.md`): when a
human inserts an ordinary question, correction or follow-up while the native `/work` loop is
running, the coordinator handles that comment and then **returns automatically to the same
loop** — the same coordinator instance and the same startup anchor — instead of letting a
routine final response silently terminate observation. It stops for confirmation in exactly
one case: the agent's final comment carries information the human genuinely needs to review
before work can continue. In that case it asks 「ループを再開してよろしいですか？」 and
remains stopped until the answer arrives.

The contract already says most of this and the loop still ended. `skills/work/SKILL.md`
(*Children and reports*) reserves a final response for an explicit stop or a named inability
to continue; `commands/infinite-development.md` (*Observe*) says a mid-loop question or
correction preserves the objective and anchor; `runtime/reference/native-loop.md` says an
ordinary question is answered without discarding the anchor. What none of them states is the
**third event** the operator names — a review-required handoff — nor that the ordinary path
is a *resume of the same instance*, nor that the two paths are told apart by a stated
criterion. So a session that answered a comment with a final response was not violating any
sentence it could point to. This ticket adds the distinction to the conversation/final-response
contract and covers both paths with tests, as the ask states.

This is a failure report about an existing mechanism (`workaholic:discover`, *Diagnosis-First
Rule*): step 1 reproduces and localizes where the final response ends observation before any
contract text moves.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — the running loop's own control, recovery and truthful reporting
- `workaholic:implementation` / `policies/objective-documentation.md` — every gate line objective
  and verifiable; the two paths are pinned by tests, not by prose alone

## Key Files

- `plugins/workaholic/skills/work/SKILL.md` — *Children and reports*: the paragraph reserving a
  final response for an explicit stop or a named inability to continue, and *A correction does
  not reset the startup anchor*. The distinction lands here first.
- `plugins/workaholic/commands/infinite-development.md` — *Observe*: `hold` / `resume` / `stop`
  with `explicit:true`, and the line *A mid-loop question or correction preserves the objective
  and anchor; an explicit wait enters hold before dispatch*. The ceiling the tick executes.
- `plugins/workaholic/skills/runtime/reference/native-loop.md` — the event table and *The live
  conversation is the first inbound source*: an ordinary question is answered without
  discarding the anchor; `hold` preserves schedule and anchor; time never resumes a hold.
- `plugins/workaholic/skills/runtime/scripts/lib/coordinator.jq` — the reducer for `hold`,
  `resume` and `stop`; `anchor` is set once at `start` and carried, so the resume path must
  reuse the instance rather than emit a second `start`.
- `plugins/workaholic/hooks/guard-work-control.sh` — rejects dispatch while held/stopped and
  rejects `AskUserQuestion` while a native loop is registered; the review-required question
  must be posed in a way this guard permits.
- `plugins/workaholic/skills/work/scripts/acknowledgement-contract.sh` — the existing shape of a
  contract reader: the agent writes the sentence, a script owns the load-bearing facts. The
  final-response contract can take the same shape.
- `scripts/tests/agentic-loop/native-coordinator.test.mjs` — pins that a hold survives timer
  ticks and resumes only explicitly; the two new paths are pinned beside it.
- `scripts/tests/agentic-loop/runtime-dispatch.test.mjs` — pins that observation activity
  cannot advance the anchored work clock.
- `scripts/test-workflow-scripts.mjs` — the command-ceiling pins over `commands/*.md` and
  `skills/work/SKILL.md`; the contract wording is pinned there once it exists.

## Related History

The native parent has been repaired three times on this exact seam, each time on one half of
the conversation contract: first the final response was reserved for a stop or a refusal
(2026-09-06), then the hold was made to survive timer ticks and resume only explicitly
(2026-09-09, #1126 / #1128), then the anchor was carried across a correction. What has never
been written is the *positive* rule for the ordinary case — resume the same instance — nor the
one criterion that separates it from a handoff that must wait.

- [20260906022855-reserve-the-final-response-for-a-stop-or-a-refusal.md](.workaholic/tickets/archive/work-20260906-023953/20260906022855-reserve-the-final-response-for-a-stop-or-a-refusal.md) - reserved the final response for an explicit stop or a named inability to continue (same seam)
- [20260906022855-run-the-tick-as-a-native-parent-that-keeps-its-turn.md](.workaholic/tickets/archive/work-20260906-023953/20260906022855-run-the-tick-as-a-native-parent-that-keeps-its-turn.md) - the native parent keeps its turn between ticks (the mechanism a final response ends)
- [20260906022855-carry-the-loop-state-across-context-compaction.md](.workaholic/tickets/archive/work-20260906-023953/20260906022855-carry-the-loop-state-across-context-compaction.md) - the instance ID is reused after compaction (the same reuse a resume needs)
- `.workaholic/feedbacks/20260909125918-repair-the-native-work-loop-s-control-delivery-and-truthful-reporting.md` - the operator's prior instruction (#1126): a hold suspends dispatch and preserves the schedule; elapsed time never stands in for permission to resume. This ticket must not weaken it.

## Implementation Steps

1. **Reproduce and localize the failure first** (`diagnosis_first: true`). On the native
   parent branch, walk the turn that follows an ordinary mid-loop comment and find the exact
   point at which the session emits a final response rather than commentary: whether the
   contract in `skills/work/SKILL.md` and `commands/infinite-development.md` is silent on the
   ordinary path (no sentence says *resume the same instance and anchor*), or whether the
   sentence exists and the harness ends the turn regardless. Record the finding in the ticket's
   final report; the rest of the steps assume the first and must be revisited if it is the
   second.
2. **State the two paths in the contract, in one wording, on the surfaces that carry it**
   (`skills/work/SKILL.md` *Children and reports*, `commands/infinite-development.md` *Observe*,
   `runtime/reference/native-loop.md`). A **routine interruption** — an ordinary question,
   correction or follow-up — is handled in commentary and the coordinator **returns to the same
   loop**: the same instance ID, the same startup anchor, the same schedule, no second `start`
   event, no final response. A **review-required handoff** — the agent's final comment carries
   information the human genuinely needs to review before work can continue — persists `hold`
   (`explicit:true`) first, then asks exactly 「ループを再開してよろしいですか？」 and stays held
   until the human answers; the answer is an explicit `resume`, and time never resumes it
   (`native-loop.md`, unchanged). The final response is thereby reserved for **three** events:
   an explicit stop, a named inability to continue, and a review-required handoff.
3. **State the criterion that tells the two apart, as a judgement the run writes out**, not as
   a detector: the question is *does the human need to read this before work may continue?* —
   a decision the loop cannot take on its own (a fork that reaches the operator's ruling), a
   result that contradicts what the human just asked for, or a refusal that stops the work.
   An ordinary answer, a confirmation, or a status the human did not ask to gate on is routine.
   The default when the run is unsure is **routine**: a needless stop is the failure #1126
   measured (nine unattended ticks lost to a wait), and a needless resume is corrected by the
   human's next message, which is itself an ordinary interruption.
4. **Give the contract a reader, modelled on `work/scripts/acknowledgement-contract.sh`**, so
   both paths are testable rather than prose-only: `work/scripts/final-response-contract.sh
   --input <facts.json>` takes the facts of a conversation turn (`interruption_kind:
   routine|review_required`, `hold_persisted`, `instance_id`, `anchor`, the intended `question`)
   and answers `{path: resume|review_handoff, final_response: false|true, question, ok, reason}`.
   It refuses `review_handoff` without a persisted hold (`hold_not_persisted`), refuses a
   question other than the one Japanese sentence (`question_mismatch`), and refuses a resume
   that names a different instance or anchor (`anchor_moved`). The agent still writes the
   sentence; the script owns the load-bearing facts.
5. **Pose the question where the guard permits it.** `guard-work-control.sh` rejects
   `AskUserQuestion` while a native loop is registered; the review-required question is the
   final response's own text after `hold` is persisted, never an `AskUserQuestion` call. State
   this beside the guard's description so nobody routes the handoff through the tool the guard
   refuses.
6. **Cover both paths with tests.** In `scripts/tests/agentic-loop/native-coordinator.test.mjs`
   (or a sibling): a routine interruption leaves `mode: running`, the instance ID and `anchor`
   byte-identical, and produces no final response; a review-required handoff persists `held`
   before the question, the question is the exact sentence, nine timer ticks do not resume it,
   and an explicit `resume` does. In `scripts/test-workflow-scripts.mjs`, pin the contract
   wording on the surfaces step 2 touched, byte-identical across them, as the ceilings are
   already pinned.
7. **Regenerate and document**: `node scripts/build-plugins/build.mjs` (the `work` skill ships
   in the bundle), then `CLAUDE.md`'s *Architecture Policy* paragraph on the native coordinator
   gains one sentence naming the three final-response events and the resume rule.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- After an ordinary mid-loop comment is handled, the coordinator continues on the same instance
  ID and the same startup anchor with no second `start` event and no final response.
- A review-required handoff persists `hold` before asking, asks exactly
  「ループを再開してよろしいですか？」, and stays held across timer ticks until an explicit
  `resume` arrives.
- The final response is reserved for exactly three events — explicit stop, named inability to
  continue, review-required handoff — and the same wording appears on every surface that
  carries the contract.
- `final-response-contract.sh` refuses `hold_not_persisted`, `question_mismatch` and
  `anchor_moved` by name, with exit non-zero and nothing else written.

**Verification method** — the commands/tests/probes that prove them:

- `node --test scripts/tests/agentic-loop/*.test.mjs` — the two new path tests are green and
  the existing hold test (`native hold survives nine timer ticks…`) is unchanged.
- `node scripts/test-workflow-scripts.mjs` — the contract-wording pins pass.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- Both suites green; no post shape is added to or removed from
  `commands/infinite-development.md`'s ceiling; the #1126 hold rule (time never resumes a hold)
  is byte-identical in `native-loop.md`.

## Considerations

- The distinction is a judgement the run states, not a classifier: nothing in the tree can read
  a sentence and decide whether a human must review it, so step 3 fixes the default and step 4
  fixes only the facts around it. Do not grow the reader toward content matching
  (`plugins/workaholic/skills/work/scripts/acknowledgement-contract.sh` is the precedent).
- A review-required handoff is a `hold`, not a `stop`: the schedule, claims and children are
  preserved exactly as #1126 requires, and the human's answer is the existing explicit `resume`
  event (`plugins/workaholic/skills/runtime/scripts/lib/coordinator.jq`). Do not add a fourth
  mode.
- The routine-resume path must not become a way to resume a *hold*: a human who said "wait"
  and then asks an ordinary question is still holding; the question is answered in commentary
  and the hold stands (`plugins/workaholic/skills/runtime/reference/native-loop.md`).
- The operator's sentence is fixed and Japanese; it is a GitHub-side and channel-side surface at
  once, so it is carried verbatim and never translated or paraphrased
  (`plugins/workaholic/rules/interaction.md`).
- Only the native-parent branch has this failure; under an external clock or a scheduled task
  a final response is correct and the clock re-invokes the tick. Keep the wording per branch as
  the 2026-09-06 ticket did.

## Final Report

Development completed as planned.

Step 1 (diagnosis first) found the **first** case: the contract was silent on the ordinary
path. `skills/work/SKILL.md` reserved the final response for two events and said a correction
does not reset the anchor; `commands/infinite-development.md` said a mid-loop question
preserves the objective and anchor; `native-loop.md` said an ordinary question is answered
without discarding it. No sentence on any of the three said *return to the same instance, same
anchor, no second `start`, no final response*, and none named the review-required handoff or
the criterion. The reducer (`coordinator.jq`) already carries `anchor` from `start` and
answers `already_started` to a second start, so no reducer change was needed — the two paths
are stated on the surfaces and pinned by tests, and the reader owns only the facts.

### Discovered Insights

- **Insight**: `guard-work-control.sh` refuses `AskUserQuestion` while a native loop is
  registered, so the review-required question can only be the final response's own text
  after `hold` is persisted; a reader that answers `path: review_handoff` with
  `final_response: true` is the contract's way of making that the only shape.
  **Context**: anyone routing the handoff through the tool would hit the guard's
  `unattended_question` refusal mid-run; the header of the guard and the CLAUDE.md hooks
  entry now say so beside the refusal.
- **Insight**: a routine comment under a standing hold answers `path: resume` with
  `control: held` and `hold_stands: true` — the reader carries the coordinator's mode through
  and never changes it, so the ordinary path cannot become a way to resume a hold.
  **Context**: the #1126 rule (time never resumes a hold) is byte-identical in
  `native-loop.md`'s table and is pinned by the suite; the routine path adds a second thing
  that never resumes it, an ordinary question.
