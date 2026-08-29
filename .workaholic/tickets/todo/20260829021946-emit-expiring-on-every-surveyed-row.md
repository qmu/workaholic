---
created_at: 2026-08-29T02:19:46+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: warn-a-direction-before-its-date-silences-the-loop
merge_policy:
verification_handoff: 
---

# Emit expiring on every surveyed row

## Overview

PROPOSED. `survey-strategies.sh` emits **`expiring`** on every surveyed row,
eligible and refused alike, `true` exactly when
`days_to_target != null and 0 <= days_to_target <= $window_days`.

It introduces **no new threshold**: both terms are already on the row and already
justified there. `$window_days` (`WINDOW_DAYS`, derived from the same `$WINDOW`
`pace` is derived against) is the evidence window the judgment is made against;
the remaining days are the strategy's own date. So the reading means *less runway
remains than the window the judgment can see* — precisely the point at which
`pace` stops being able to tell whether the direction will arrive.

It is **its own field, never a fourth `pace` value**, for the reason `overdue`
already records in that script: one field answering two questions is how the two
drift.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/testable-domain-logic.md` — a derived reading, provable over a fixture

## Key Files

- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — the one
  writer of the row. `overdue`'s block is the template: computed **before**
  `refusal`, emitted on eligible and refused rows alike, with its reasoning in
  the block's own comment.
- `scripts/test-workflow-scripts.mjs` — ticket 1's failing case, which this
  turns green.

## Implementation Steps

1. Read `survey-strategies.sh`'s header and the `pace` / `overdue` / `dormant` /
   `quiescent` blocks in full. They are the precedent for where the term is
   computed, how it is documented, and why it is its own field.
2. Add the `expiring` block **beside `overdue`, computed before `refusal`**, so
   no gate, no `pace` value, no sort and no `selected` can read it.
3. Define it exactly: `true` when `days_to_target != null` and
   `0 <= days_to_target <= $window_days`. A `null` `days_to_target` is never
   `expiring` (malformed is not near), and a direction already past its date is
   never `expiring` either — `days_to_target < 0` is `overdue`'s answer, not
   this one. A direction expiring **today** reads `0` and **is** `expiring`.
4. Carry it onto the `refused[]` projection beside `overdue`, `dormant`,
   `quiescent` and `landed_count` — the refused case is the point, since a
   direction refused for another reason still has a date coming.
5. Write the block's own comment in the voice the neighbouring blocks use: what
   it answers, why it is not a `pace` value, why the window is the survey's own
   and not a new constant, and where the boundary sits.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `expiring` appears on every row of both `eligible[]` and `refused[]`.
- It is `true` exactly on `0 <= days_to_target <= $window_days`, `false` at
  `days_to_target: -1`, and `false` when `days_to_target` is `null`.
- No new constant, no new counter, no field on any artifact, and no fourth
  `pace` value.
- `refusal`, `pace`, `overdue`, `dormant`, `quiescent`, the sort and `selected`
  are byte-identical over a row that reads `expiring` and one that does not.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — ticket 1's case now passes on the
  reading, plus a byte-identical diff of the other terms across the boundary.

**Gate** — what must pass before approval:

- The window term in the code is the survey's own `$window_days`, not a literal
  and not a new environment variable.

## Considerations

- The boundary at `0` is deliberate and must be stated in the comment: a
  direction whose date is **today** is expiring, not overdue — `overdue` starts
  at `< 0`, so the two are exhaustive and disjoint with no gap and no overlap.
- `expiring` and `dormant` can both be true (a silent direction near its date).
  That is fine here; the precedence between them is ticket 3's question, not
  this one's.
