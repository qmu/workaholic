---
created_at: 2026-08-26T11:00:16+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-when-the-loop-has-run-out-of-direction
merge_policy:
verification_handoff: 
---

# Add the overdue reading to the strategy survey

## Overview

`survey-strategies.sh` refuses a strategy whose date has passed with `past_target_date`
and stops. `pace` cannot carry that state: `late` requires `(.landed | length) == 0`, so a
direction that sailed past its date **while producing work** reads `on_course`. The row is
therefore refused for a correct reason and reads as healthy, and no consumer can tell the
two apart. Add `overdue` as a **third reading beside `pace`**, derived from
`days_to_target < 0` on every surveyed row — eligible and refused alike.

It changes **no gate and no eligibility**: `past_target_date` still refuses exactly as it
does today. This is the reading half only; the asking half is ticket 4.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/observability.md` — a degraded read is named, never rendered as a healthy one

## Key Files

- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — the one surveyor;
  `days_to_target` is already computed by its `days($t)` helper and read only by
  `past_target_date`. The new field goes beside `pace` in the same `jq` row builder.
- `plugins/workaholic/skills/propose/SKILL.md` — records what each reading means.
- `CLAUDE.md` — the `/propose` row states the survey's readings.

## Implementation Steps

1. Read `survey-strategies.sh`'s header and its `pace` derivation in full — the header
   states why `pace` needs no threshold, and `overdue` must be written to the same standard.
2. Add `overdue` to the row builder beside `pace`: `true` when `days_to_target != null` and
   `days_to_target < 0`, `false` when the date resolves and has not passed, and a distinct
   `unknown`-equivalent when `days_to_target` is `null` or the row is `unreadable`. It must
   never collapse into `late`, `on_course` or `unknown`.
3. Emit it on **every** row — inside `eligible[]` and inside `refused[]` — because the
   whole point is a direction refused `past_target_date`, which only ever appears in
   `refused[]`.
4. Leave the `refusal` ladder, the sort and `selected[]` byte-identical. Assert this.
5. Update `SKILL.md` and `CLAUDE.md` in the same commit.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every surveyed row carries `overdue`, eligible and refused alike
- A row whose `days_to_target` is negative reads `overdue: true` regardless of its `pace`
- A row with no resolvable date is neither `overdue: true` nor `overdue: false`
- `refusal`, ordering and `selected[]` are unchanged for every input

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — a case seeding a past-dated strategy that has
  landed work, asserting `pace: on_course` and `overdue: true` on the same row
- A second case seeding a strategy with no `target_date`, asserting neither value

**Gate** — what must pass before approval:

- The suite passes; no eligibility or ordering change is observable in any existing case

## Considerations

- `overdue` is deliberately not a refusal reason: `past_target_date` already refuses, and
  giving one state two refusals would double-count it.
- Ticket 3 composes this rather than re-deriving it — there must be exactly one place where
  a negative `days_to_target` becomes a word.
