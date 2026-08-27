---
created_at: 2026-08-27T14:24:44+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-when-a-direction-has-arrived
merge_policy:
verification_handoff: 
---

# Add the quiescent reading to the strategy survey

## Overview

PROPOSED. `survey-strategies.sh` emits three readings about a direction's health — `pace`,
`overdue`, `dormant` — and every one of them answers *is this direction in trouble*. None answers
*has it arrived*. Add **`quiescent`**: `true` exactly when the row is readable, `active`, `mine`,
carries non-empty `feedback_refs`, has a **non-empty** `landed[]`, has
`waiting_missions + waiting_count == 0`, and carries no open proposal.

Every term is already on the row — no new counter, no field on any artifact, no second derivation.
It is `dormant`'s complement on the one term that separates *a direction nothing has answered*
from *a direction whose answers are all in*: `landed` empty versus `landed` non-empty.

It carries **no date term at all**, deliberately, unlike `dormant` (which is `false` once
`days_to_target < 0`). Arrival is independent of the date, and that independence is exactly why
the projected state must outrank lateness in the next ticket.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — the survey; the `dormant`
  block immediately above is the shape to follow, including its header discipline.
- `plugins/workaholic/skills/propose/SKILL.md` — where `pace`, `overdue` and `dormant` are
  recorded; `quiescent` joins them.

## Implementation Steps

1. Read the `pace` / `overdue` / `dormant` chain in `survey-strategies.sh` and the header block
   above it, so the new reading is placed and documented the same way.
2. Add `| . + {quiescent: ...}` **after** `dormant` and **before** `refusal`, so `refusal`, `pace`,
   `overdue`, `dormant`, the sort and `selected` stay byte-identical.
3. Emit it on **every** surveyed row, eligible and refused alike — the refused case is the point,
   since a direction whose date has passed is exactly the one whose arrival must still be visible.
4. Write the header: why it carries no date term, and how it differs from `dormant` on the single
   term that separates them.
5. Record the reading in `plugins/workaholic/skills/propose/SKILL.md` beside the other three.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `quiescent` appears on every row of `eligible[]` and `refused[]`.
- It is `true` only under the full conjunction above, and `false` whenever `landed[]` is empty.
- `refusal`, `pace`, `overdue`, `dormant`, the eligible sort and `selected` are unchanged for
  every fixture.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- Run `survey-strategies.sh` before and after over the same fixture and diff every field but
  `quiescent`.

**Gate** — what must pass before approval:

- The byte-identical diff on the pre-existing fields, demonstrated rather than asserted.

## Considerations

- `dormant` and `quiescent` are mutually exclusive by construction (`landed` empty versus
  non-empty), but nothing needs to enforce that — deriving each from the row independently is what
  keeps them from drifting.
