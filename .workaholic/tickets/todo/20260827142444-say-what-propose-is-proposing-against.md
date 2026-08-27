---
created_at: 2026-08-27T14:24:44+00:00
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
