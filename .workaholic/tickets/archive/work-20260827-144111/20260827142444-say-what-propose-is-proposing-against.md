---
created_at: 2026-08-27T14:24:44+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260827142444-add-the-quiescent-reading-to-the-strategy-survey.md
mission: say-when-a-direction-has-arrived
merge_policy:
verification_handoff: 
---

# Say what propose is proposing against

## Overview

PROPOSED. `quiescent` **lifts and closes no gate**: an arrived direction stays eligible, `refusal`,
`pace`, `overdue`, `dormant`, the sort and `selected` are byte-identical, and `/propose` keeps
proposing against it. What changes is only that the run report **says** it is doing so.

Silencing the one routine that originates work on a machine's guess is the temptation `pace`
already refuses. The gate that eventually holds is `not_active`, after a person closes the
direction — which is the operator's act, not a reading's.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/propose/SKILL.md` — where the readings and the gates are recorded;
  gains the statement that `quiescent` changes no gate.
- `plugins/workaholic/skills/propose/reference/loop.md` — the run's own steps and its report
  contract.

## Implementation Steps

1. Read the run report's existing shape and where `pace` is named beside a proposed-against
   strategy — that is the precedent to follow.
2. Name `arrived` in the run report beside a strategy the tick proposed against, as evidence, in
   the same voice `pace` uses.
3. Record in `SKILL.md` that `quiescent` lifts and closes no gate: the direction stays eligible,
   every gate and the sort are unchanged, and the gate that eventually holds is the operator's
   close.
4. Record the reason, so a later change does not "helpfully" gate on it: a machine's reading of
   arrival is not a decision that the direction is done.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An arrived direction is still eligible and can still be `selected`.
- The run report names `arrived` for such a strategy.
- No refusal reason, no sort order and no `selected` value changes.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- A `/propose` run over an arrived fixture, showing the proposal still made and named.

**Gate** — what must pass before approval:

- The eligibility and sort demonstrated unchanged, not asserted.

## Considerations

- The obvious next request will be to gate on `arrived`. The recorded reason is what a future
  reader needs in order to refuse it deliberately rather than by accident.

## Final Report

Development completed as planned. `reference/loop.md` step 5 now says that a tick proposing
against a strategy whose row reads `quiescent: true` reports `arrived` beside it — as
**evidence**, in the same voice `pace` uses, never as a refusal. `workaholic:propose` gains
*Quiescent changes no gate*, recording that the direction stays eligible, that `refusal`,
`pace`, `overdue`, `dormant`, the sort and `selected` are byte-identical, and that the gate
which eventually holds is `not_active` — after a **person** closes the direction.

The reason is recorded so a later change refuses gating on it deliberately rather than by
accident: silencing the one routine that originates work on a machine's guess is what `pace`
already refuses, and `arrived` is a candidate rather than a verdict because "Reached when" is
prose no script reads.

Verified: over the arrived fixtures both arrived directions remain **eligible** and appear in
`selected`, and the before/after survey diff shows no refusal reason, no sort order and no
`selected` value moving. `node scripts/test-workflow-scripts.mjs` — 4031 passed, 0 failed.

### Discovered Insights

- **Insight**: `/propose`'s run report is agent-composed prose, not a script's output, so
  "name it in the run report" is implemented by writing the obligation into `reference/loop.md`
  where the run reads its own steps.
  **Context**: there is no report-rendering script to extend. The same is true of the
  three-part question rule in `workaholic:moderate` — both are prose contracts whose
  enforcement is that a report omitting the fact is visibly non-conformant.
