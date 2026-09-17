---
created_at: 2026-09-11T18:04:01+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: keep-the-native-loop-alive-preserve-slack-input-and-stop-direct-commits-to-main
merge_policy:
verification_handoff: 
---

# Prove a continuation before a mid-loop turn ends

## Overview

Issue #1151, first repair. A native `/work` session reported that it had returned to the loop,
then emitted a final response and stopped observing while the coordinator record still read
`running`. Pull request #1150 (issue #1147) added `work/scripts/final-response-contract.sh`,
which classifies the turn (`resume` versus `review_handoff`) but proves nothing about what
carries the loop after the turn: the `resume` answer says `final_response: false` and the run
is trusted to keep going. The operator's rule, verbatim: *An ordinary mid-loop comment must
return to an interruptible parent or establish a same-chat scheduled continuation before any
response ends the turn. A `running` state alone must never be called a resumed loop.*

This ticket makes the continuation a **fact the contract reads**, not a sentence the run
writes: a routine interruption is `resume` only when a continuation is named and proved, and
the coordinator's own reading distinguishes `running` (a control mode) from `resumed` (a
control mode **plus** a live continuation).

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/objective-documentation.md` — every reported state names the evidence it rests on

## Key Files

- `plugins/workaholic/skills/work/scripts/final-response-contract.sh` - the reader of the turn's facts; gains the `continuation` fact and the `continuation_unproved` refusal
- `plugins/workaholic/skills/runtime/scripts/coordinator.sh` - the reducer; records the continuation and derives `resumed`
- `plugins/workaholic/skills/runtime/scripts/lib/coordinator.jq` - where `control: running` is written today
- `plugins/workaholic/skills/runtime/reference/native-loop.md` - the native loop protocol; the event table gains the continuation fields
- `plugins/workaholic/skills/work/SKILL.md` - *State the selected clock, where reports appear, and any missing continuation mechanism* — the sentence this ticket turns into a gate
- `plugins/workaholic/commands/infinite-development.md` - the tick's report contract
- `plugins/workaholic/commands/work.md` - the command that starts the native loop
- `plugins/workaholic/hooks/guard-work-control.sh` - the launch guard keyed on the same instance record
- `scripts/tests/agentic-loop/native-coordinator.test.mjs` - the reducer's contract tests
- `scripts/test-workflow-scripts.mjs` - pins the contract wording across the three surfaces

## Related History

The final-response contract shipped one day earlier for the same symptom and stopped at
classification; this ticket is the second half the operator named.

- [20260911142410-resume-the-native-work-loop-after-ordinary-mid-loop-comments.md](.workaholic/feedbacks/20260911142410-resume-the-native-work-loop-after-ordinary-mid-loop-comments.md) - the ask that produced #1150 (routine resumes, review handoff asks and waits)

## Implementation Steps

1. **Reproduce and localize** (diagnosis first). Feed `final-response-contract.sh` routine facts
   with no continuation and show it answers `path: resume` with nothing about what continues the
   loop. Feed `coordinator.sh` a `start` then a `tick` and show the reading carries
   `control: running` and no liveness term. Record both outputs in the story as the measured
   shape; the operator's session is the third reading (`running` reported as resumed with no
   continuation at all).
2. **Name the continuation as a fact.** Add `continuation` to the contract's input:
   `{kind: "interruptible_parent" | "same_chat_schedule", id: <string>, next_due: <epoch>}`.
   The `resume` path requires it and refuses **`continuation_unproved`** (exit 2, nothing
   written) without it; `review_handoff` does not require it, because a held loop is waiting on a
   person. `kind` is a closed set; anything else is `invalid_facts`.
3. **Record it in the reducer.** Let `start` and `resume` carry the same `continuation` object,
   and add a `continued` event for a turn that re-establishes one. `tick` derives
   **`resumed`**: `true` only when `control == running` **and** a recorded continuation exists
   whose `next_due` is not in the past; otherwise `false` with `reason: continuation_unproved`
   or `continuation_lapsed`. `running` alone is never `resumed`. No fourth control mode.
4. **Make the report contract read it.** In `work/SKILL.md`, `native-loop.md` and
   `commands/infinite-development.md`, one wording: a turn that handled a mid-loop comment
   names the continuation it returns to (`kind` and `id`) **before** the response ends, and a
   report that calls the loop resumed while `resumed` is `false` is non-conformant on its face.
   The sentence *any missing continuation mechanism* becomes a refusal to say *resumed*.
5. **Wire the Claude Code host.** In `commands/work.md`, state which continuation the native
   session uses (the same-chat scheduled tick already selected at `start`, or the parent's own
   interruptible wait) and that the turn re-derives it through the contract before ending.
6. **Tests.** `native-coordinator.test.mjs`: `start` without continuation then `tick` reads
   `resumed: false, reason: continuation_unproved`; with a `same_chat_schedule` whose `next_due`
   is ahead, `resumed: true`; with one whose `next_due` has passed, `continuation_lapsed`;
   `review_handoff` still needs no continuation. `test-workflow-scripts.mjs`: the contract
   refuses routine facts without a continuation, accepts them with one, and the three surfaces
   carry the wording byte-identically.
7. Update `CLAUDE.md` (Architecture Policy, the native parent's final-response paragraph) in
   the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `final-response-contract.sh` answers `continuation_unproved` for routine facts that name no continuation, and `resume` with the continuation echoed when they do
- `coordinator.sh` `tick` emits `resumed` as its own field, `false` whenever no live continuation is recorded, whatever `control` says
- the review-handoff path is byte-identical in behaviour (hold persisted, the one question, no continuation required)

**Verification method** — the commands/tests/probes that prove them:

- `node --test scripts/tests/agentic-loop/native-coordinator.test.mjs` with the new cases green
- `node scripts/test-workflow-scripts.mjs` green, including the wording pin across the three surfaces
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` with no diff in `outputs/`

**Gate** — what must pass before approval:

- the suite is green, `hooks/posix-lint.sh` conforming, and the story quotes the measured pre-change readings from step 1

## Considerations

- The reducer must not grow a fourth control mode; `resumed` is derived from `control` and the recorded continuation, never stored as a mode (`plugins/workaholic/skills/runtime/scripts/lib/coordinator.jq`)
- A same-chat scheduled tick on Claude Code is the host's clock; the contract reads its identifier and next due time, it never creates one (`plugins/workaholic/skills/work/SKILL.md` lines 30-47)
- Reporter-proposed mechanism recorded as a hypothesis, not as the design: *return to an interruptible parent or establish a same-chat scheduled continuation* — step 1 decides which of the two the native host can actually prove

## Final Report

Development completed as planned.

Measured before the change (step 1): `final-response-contract.sh` fed routine facts with no
continuation answered `path: resume, final_response: false` and nothing about what carries the
loop; `coordinator.sh` fed `start` then `tick` answered `control: running` with data keys
`anchor, cancel_children, cancel_schedule, cancelled, completed, completion_log, control, due,
live` and no liveness term. The operator's session was the third reading.

### Discovered Insights

- **Insight**: `resumed` is derived at every event from `control` and the recorded continuation, never stored, so a state written before this change (no `continuation` key) reads `continuation_unproved` with no migration.
  **Context**: the reducer's tail derivation is the one place liveness is computed; a mode would have been a second store of the same fact.
- **Insight**: the review-handoff path takes no continuation because a held loop is waiting on a person, so the `hold` itself is what carries it; the contract refuses `continuation_unproved` only on the `resume` path, after every other refusal, so existing refusal rows keep their names.
  **Context**: ordering the new refusal last keeps `anchor_moved` / `hold_not_persisted` / `question_mismatch` byte-identical for facts that name no continuation.
