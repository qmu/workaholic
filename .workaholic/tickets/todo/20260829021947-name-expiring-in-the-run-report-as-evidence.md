---
created_at: 2026-08-29T02:19:47+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: warn-a-direction-before-its-date-silences-the-loop
merge_policy:
verification_handoff: 
---

# Name expiring in the run report as evidence

## Overview

PROPOSED. `/propose` names `expiring` beside a proposal made against that
strategy, in the voice `pace` and `arrived` already use — **as evidence, never as
a gate**.

The distinction is the whole ticket. `pace` "changes order, never eligibility";
`arrived` "lifts and closes no gate"; and this is the same. A reading that a
direction is about to expire must not silence, reorder, hold or accelerate the
one routine that originates work: silencing origination on a machine's reading of
a date is precisely what `pace` already refuses, and the person who must act is
reached by ticket 5's question, not by this line.

So this ticket is one report line plus a **hermetic diff** proving nothing else
moved.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — evidence in the report, decisions to a person

## Key Files

- `plugins/workaholic/skills/propose/SKILL.md` — the run report's contract and
  the voice `pace`/`arrived` are named in.
- `plugins/workaholic/commands/propose.md` — the report line the command emits.
- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — read only;
  the term is already on the row after ticket 2.
- `scripts/test-workflow-scripts.mjs` — the byte-identical diff.

## Implementation Steps

1. Read how `pace` and `arrived` are named in the run report today, and match
   that voice exactly — a term beside the strategy, not a warning and not a
   sentence of advice.
2. Name `expiring` beside a proposal made against that strategy. A refused
   strategy's `expiring` is already on its row and needs no second surface here:
   the report names what the tick proposed against.
3. Write the **hermetic diff**: over a fixture that differs only in
   `days_to_target` (inside the window versus outside it), assert that
   `refusal`, `pace`, `overdue`, `dormant`, `quiescent`, the sort, `selected`
   and every token are **byte-identical**.
4. State in `workaholic:propose` that the reading gates nothing, and **why** —
   the `pace` refusal, restated for this term so a later reader does not have to
   reconstruct it.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The run report names `expiring` beside a proposal made against that strategy.
- `refusal`, `pace`, `overdue`, `dormant`, `quiescent`, the sort, `selected` and
  every token are byte-identical over an expiring row and a live one.
- No gate is added, lifted, reordered or bypassed by the reading.
- `workaholic:propose` states that the reading gates nothing and names the
  refusal it rests on.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the byte-identical diff over the
  two fixtures, plus the report-line assertion.

**Gate** — what must pass before approval:

- The diff is over fixtures differing in **exactly** `days_to_target`, so a
  passing diff cannot be explained by anything else.

## Considerations

- The obvious "improvement" — proposing more urgently against an expiring
  direction — is refused here by name. It sounds helpful and it makes the
  routine's output a function of a clock, which is the coupling `pace` was
  deliberately kept out of.
- Equally refused: skipping a proposal against an expiring direction to "leave
  the operator room to decide". That silences origination on a guess.
