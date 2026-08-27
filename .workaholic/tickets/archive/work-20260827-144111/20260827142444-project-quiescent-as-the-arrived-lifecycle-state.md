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

# Project quiescent as the arrived lifecycle state

## Overview

PROPOSED. `direction-state.sh` is the one lifecycle reader and it **composes, never re-derives**:
every state it answers is a projection of a field the survey emitted, and the only thing it owns is
the precedence. Add **`arrived`**, projected from the previous ticket's `quiescent`, at precedence
`unreadable > arrived > overdue > dormant > live`.

`arrived` outranks `overdue` because a direction whose work is all in is the operator's to
**close**, whatever its date says — naming a success as a failure is the defect this mission exists
to remove. It is a **candidate**, never a verdict: a strategy's own "Reached when" is prose no
script reads, so the reading says *this looks finished* and the operator's answer decides.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/strategy/scripts/direction-state.sh` — the lifecycle reader; its
  header states the precedence and the reasons for it, and gains a row.
- `plugins/workaholic/skills/strategy/SKILL.md` — where the lifecycle states are recorded.

## Implementation Steps

1. Read `direction-state.sh` in full, including the header's precedence rationale and the
   `counts` object — both move together with the new state.
2. Add the `arrived` branch to the `state` expression, between `unreadable` and `overdue`,
   reading **only** the survey's `quiescent`. Derive nothing: no date arithmetic, no attribution
   walk, no second reading of `landed`.
3. Give it a `reason` string in the same voice as the others (`dormant`'s is "nothing landed in
   the window and nothing is waiting").
4. Add `arrived` to `counts` and to the `emit_unreadable` zero-object, so a degraded read reports
   the same shape.
5. Record in the header: why `arrived` outranks `overdue`, and that it is a candidate rather than
   a verdict, because "Reached when" is prose no script reads.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A `quiescent` row reads `arrived`, including one whose `target_date` has passed.
- A row that is both unreadable and quiescent reads `unreadable`.
- `dormant` and `live` rows are unchanged, and `counts` sums to the number of active strategies.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- Fixtures covering arrived, overdue-and-arrived, dormant, live and unreadable.

**Gate** — what must pass before approval:

- No date arithmetic and no attribution walk added to this script — it composes only.

## Considerations

- The precedence change is the one place a later reader might expect `overdue` to win. The header
  must say why it does not, or the next change will quietly reorder it.

## Final Report

Development completed as planned. `direction-state.sh` gains `arrived`, projected from the
survey's `quiescent` and from nothing else — no date arithmetic, no attribution walk, no second
reading of `landed`. The precedence is now `unreadable > arrived > overdue > dormant > live`,
with `reason: "its work has landed and nothing is waiting"`. `counts` and the `emit_unreadable`
zero-object both carry `arrived`, so a degraded read reports the same shape.

The header records why `arrived` outranks `overdue` — the two states ask a person for different
acts, and a finished direction is very often a late one, so ranking lateness first would make
the reading unreachable for the one case it exists to serve — and that it is a candidate rather
than a verdict, because "Reached when" is prose no script reads. `workaholic:strategy` records
the same.

Verified over a five-strategy git-backed fixture: `arrived`, an overdue-and-arrived direction
reading `arrived`, `dormant`, `overdue` and `live` each correct, `counts` summing to the number
of active strategies; a refused survey reads `readable: false` / `repository: "unreadable"` with
`arrived: 0`. `node scripts/test-workflow-scripts.mjs` — 4031 passed, 0 failed.

### Discovered Insights

- **Insight**: the survey's `eligible` rows keep every field the row was built with, while
  `refused` rows are an explicit `map({...})` projection.
  **Context**: any new reading a consumer must see on a refused row has to be added to that map
  by name. This is exactly where `overdue` and `quiescent` matter most, since a direction past
  its date is refused — a field added only to the row silently reaches half the consumers.
