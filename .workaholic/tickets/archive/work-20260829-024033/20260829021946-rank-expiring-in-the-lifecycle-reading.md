---
created_at: 2026-08-29T02:19:46+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: warn-a-direction-before-its-date-silences-the-loop
merge_policy:
verification_handoff: 
---

# Rank expiring in the lifecycle reading

## Overview

PROPOSED. `direction-state.sh` owns exactly one thing — the **precedence** — and
this ticket places `expiring` in it:

```
unreadable  >  arrived  >  overdue  >  expiring  >  dormant  >  live
```

and states why each neighbour sits where it does. `overdue` outranks `expiring`
because a date that has **gone** is a stronger fact than one approaching, and the
two ask for the same act with different urgency. `arrived` outranks both because
it asks for a **different** act — *your work is in, is this done?* rather than
*re-date or close* — which is the reasoning that block already records.
`expiring` outranks `dormant` because a direction near its date and silent is
about to be silenced by the date first, and the date is the fact with a deadline
on it.

The reader **derives no new term**: it projects `expiring` off the survey row
exactly as it projects `arrived` off `quiescent`.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/single-source-of-truth.md` — one reader owns the precedence and nothing else re-derives it

## Key Files

- `plugins/workaholic/skills/strategy/scripts/direction-state.sh` — the one
  lifecycle reader. Its header carries the fixed precedence and the `WHY
  arrived OUTRANKS overdue` block that this ticket extends.
- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — read only;
  the `expiring` term ticket 2 emits is the input.
- `scripts/test-workflow-scripts.mjs` — the precedence pin.

## Implementation Steps

1. Read `direction-state.sh` in full, especially the precedence header, the
   `WHY arrived OUTRANKS overdue` block and the `state:` expression that ranks
   the readings today.
2. Insert `expiring` into the `state:` expression between `overdue` and
   `dormant`. Add its `reason:` string in the voice the others use — the date is
   approaching, not gone.
3. Extend the precedence comment with **why `expiring` sits where it does**,
   against both neighbours, in the same prose register as the existing block. A
   precedence with an unexplained rung is what that header exists to prevent.
4. Add `expiring` to the `counts:` object beside `live`/`arrived`/`overdue`/
   `dormant`/`unreadable`.
5. Confirm the reader still **derives no date arithmetic of its own** — the term
   is read off the row, exactly as `arrived` is read off `quiescent`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A direction inside the window and otherwise healthy reads `expiring`.
- A direction past its date still reads `overdue`, never `expiring`.
- A direction that is both `quiescent` and inside the window reads `arrived`.
- A direction both `expiring` and `dormant` reads `expiring`.
- `counts` carries `expiring` and the other counts are unchanged.
- The reader performs no date arithmetic and reaches none of the strategy's
  three writers.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — one case per precedence pair above.

**Gate** — what must pass before approval:

- The precedence comment explains `expiring`'s rung against **both** neighbours,
  not just one.

## Considerations

- The survey's own lossiness is inherited and must not be papered over: `dormant`
  and `quiescent` require `owns == "mine"` upstream, so another identity's
  direction can only ever read `live`, `overdue` or `expiring` here. Say so in
  the header's limits list, where the same limit is already recorded.
- Adding a rung changes the shape of `counts`. Check every consumer of `counts`
  before assuming it is additive.

## Final Report

Development completed as planned. `direction-state.sh` places `expiring` between `overdue` and
`dormant`, projected off the survey row exactly as `arrived` is projected off `quiescent` — no
new term, no date arithmetic. Its `reason:` names the approaching date, `counts` carries the
new rung, and the header argues the rung against **both** neighbours: `overdue` above it
because a date that has gone is the stronger fact and the two ask for the same act, `dormant`
below it because a silent direction near its date is silenced by the date first.

### Discovered Insights

- **Insight**: `counts` has exactly one consumer outside the tests, and it reads named keys.
  **Context**: `step-direction-health.sh` reads `.counts.<name>` one key at a time, so adding a
  rung is additive there rather than shape-breaking. The `emit_unreadable` fallback prints its
  counts object as a literal, though, so a new rung has to be added in **two** places in this
  one file or a refused survey emits a differently shaped object from a successful one.
- **Insight**: the precedence pair that a severity ordering would get wrong is `arrived` over
  `expiring`.
  **Context**: `expiring` sounds more urgent than *its work is in*, and ranking by urgency would
  invert them. The rule is the act, not the severity: `arrived` asks *is this done?* and
  `expiring` asks *re-date or end it* — a finished direction near its date must ask the first.
