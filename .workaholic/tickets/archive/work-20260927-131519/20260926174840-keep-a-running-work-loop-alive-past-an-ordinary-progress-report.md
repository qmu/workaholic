---
created_at: 2026-09-26T17:48:40+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260926174713-a-running-work-loop-must-not-stop-after-an-ordinary-progress-report.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
merge_policy:
verification_handoff: 
claim: work-20260927-131519
---

# Keep a running work loop alive past an ordinary progress report

## Overview

The operator reports (issue #1267) that a native `workaholic:work` coordinator running as an
`interruptible_parent` persisted `control: running` with a future `next_due`, emitted an
ordinary progress response, and then the parent turn ended: no later tick happened until the
operator prompted it again. An ordinary progress report must be a yield inside the same active
loop, never its end — the next observation tick must be resumed or scheduled automatically while
the coordinator stays running, and termination reserved for an explicit stop, a completed
objective or a genuinely blocked state.

History read before writing this: `final-response-contract.sh` already refuses
`continuation_unproved` (#1262), `continuation_lapsed` and `routine_emits_no_final_response`
(#1266, merged 2026-09-21 before this ask). None of them catches the reported case: the named
continuation was `interruptible_parent`, its `next_due` was in the future, and the run did not
declare `intends_final_response`. The likely gap is that an `interruptible_parent` continuation
is accepted as proof even for a turn that is about to end — but it carries the loop only while
the parent turn stays open and waiting. Once the turn ends, only an armed same-chat schedule can
carry it.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — the running loop keeps serving and recovers without a human prompt

## Key Files

- `plugins/workaholic/skills/work/scripts/final-response-contract.sh` — the reader of the turn's facts; where a turn that ends on an `interruptible_parent` continuation would be refused
- `plugins/workaholic/skills/work/SKILL.md` — *Start* and the final-response / continuation paragraphs the parent follows
- `plugins/workaholic/skills/runtime/reference/native-loop.md` — the `continuation` shape
- `plugins/workaholic/skills/runtime/scripts/lib/coordinator.jq` — `resumed` derivation (`next_due < now` second call site)
- `plugins/workaholic/commands/infinite-development.md` — the command ceiling carrying the report contract
- `scripts/test-workflow-scripts.mjs` — the suite pinning the contract's words

## Implementation Steps

1. Reproduce first (diagnosis-first): feed `final-response-contract.sh` the reported facts —
   `interruption_kind: routine`, `control: running`, `continuation: {kind: interruptible_parent, id, next_due: <future>}`,
   `now`, no `intends_final_response` — and confirm it answers ok while the turn in fact ended.
   Also confirm from `work/SKILL.md` what the parent is told to do after an ordinary progress
   report (commentary, then wait again) and whether anything checks that it re-entered the wait.
2. Localize: decide from the reproduction whether the gap is the reader (accepting an
   `interruptible_parent` continuation for a turn that ends) or the skill text (a progress report
   treated as the turn's last act), and fix where it lives.
3. Make the ending-turn case explicit: a routine turn that is going to end must name a
   `same_chat_schedule` continuation armed before it ends; an `interruptible_parent` continuation
   is proof only while the parent keeps waiting. Refuse the other case by its own word in the
   same reader, without widening any existing closed set.
4. State in `work/SKILL.md` (and the pinned ceiling in `commands/infinite-development.md`) that an
   ordinary progress report is commentary followed by the next interruptible wait, and that a
   parent that cannot keep the turn open arms the same-chat schedule first.
5. Add hermetic cases to `scripts/test-workflow-scripts.mjs` for the reported facts and for the
   armed-schedule case; update `CLAUDE.md` *Continuation* in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The reported facts (routine turn, running, future-dated `interruptible_parent` continuation, turn ending) are refused by `final-response-contract.sh` with a named word.
- A routine turn that ends with an armed `same_chat_schedule` continuation, or that keeps waiting as the `interruptible_parent`, still passes.
- Existing refusals (`continuation_unproved`, `continuation_lapsed`, `routine_emits_no_final_response`, `unit_wait_is_not_global_hold`) are unchanged.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node --test scripts/tests/agentic-loop/*.test.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`

**Gate** — what must pass before approval:

- The local proof set (`branching/scripts/local-proof.sh`) reports `ok: true`.

## Considerations

- Hypothesis, not a design: the reporter's mechanism ("schedule or resume the next tick
  automatically") may be satisfied by the existing same-chat scheduler path once the reader
  refuses an ending turn that names only an `interruptible_parent`; step 1's reproduction decides.
- `/work` on Claude Code now runs the lightweight `workaholic:watch` loop, which does not end on a
  progress report by construction; this ticket concerns the `/infinite-development` coordinator.
- The reader cannot stop a run from emitting text; what it buys is an unambiguous refusal the run
  can ask for before ending, as #1266 already states.

## Final Report

Development completed as planned. Reproduction (step 1): the reported facts — `routine`,
`control: running`, `{kind: interruptible_parent, next_due: <future>}`, `now`, no
`intends_final_response` — answered `ok: true, path: resume, next_action: null`, so the reader
both passed a turn that ended and told the parent nothing about waiting again. The gap was the
reader, not only the skill text: nothing let a turn say it was ending. Fixed in
`final-response-contract.sh` with a new optional fact `turn_ends` (absent means false) and one new
refusal `continuation_ends_with_turn` (routine and task-wait turns naming `interruptible_parent`),
and a named `interruptible_parent` now answers `next_action: wait_interruptibly`. No closed set
widened; existing refusals unchanged. The rule is stated once more on the three surfaces that carry
the continuation contract and in `CLAUDE.md` *Continuation*.

### Discovered Insights

- **Insight**: `next_action` used to be derived only from the paused-host `native_parent` facts, so
  an `interruptible_parent` continuation named under an active host goal produced no instruction to
  wait at all.
  **Context**: A continuation that is the parent's own wait must always tell the parent to wait;
  otherwise naming it is indistinguishable from ending the turn.

## Archive delivery evidence

Implementation archived; delivery is pending verification. This is not a landed claim.

Pre-archive head: `faeca961b4411a8ec490089e84b31b071fcd7573`; observed base: `2361f8c3f577d7453d2921e9ef57f72421649914`.

Committed-tree assessment (does not cover uncommitted implementation):

```json
{"branch":"work-20260927-131519","head":"faeca961b4411a8ec490089e84b31b071fcd7573","base":"2361f8c3f577d7453d2921e9ef57f72421649914","state":"landed","reason":"tree_effect_present","tree":"b3b8baaf0c172c27e6de9986d8e8b9c90a324539","paths":[],"delivery_claim":"assessment_only_not_a_retirement_proof"}
```

Worktree/index paths at archival (including expected implementation):

```text
 D .workaholic/tickets/todo/20260926174840-keep-a-running-work-loop-alive-past-an-ordinary-progress-report.md
 M CLAUDE.md
 M plugins/workaholic/commands/infinite-development.md
 M plugins/workaholic/skills/runtime/reference/native-loop.md
 M plugins/workaholic/skills/work/SKILL.md
 M plugins/workaholic/skills/work/scripts/final-response-contract.sh
 M scripts/test-workflow-scripts.mjs
 M scripts/tests/agentic-loop/native-coordinator.test.mjs
?? .workaholic/tickets/archive/work-20260927-131519/
```
