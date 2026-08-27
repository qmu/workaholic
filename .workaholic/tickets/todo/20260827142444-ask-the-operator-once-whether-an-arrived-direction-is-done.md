---
created_at: 2026-08-27T14:24:44+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260827142444-project-quiescent-as-the-arrived-lifecycle-state.md
mission: say-when-a-direction-has-arrived
merge_policy:
verification_handoff: 
---

# Ask the operator once whether an arrived direction is done

## Overview

PROPOSED. The reading only matters if it reaches a person. `step-direction-health.sh` already hands
every non-`live` reading to the check-in as a question addressed to the direction's assignee; add
the `arrived` row, keyed **`direction-arrived:<slug>`**, naming what landed and the date.

The wording is held to the same discipline `direction-dormant` carries: a **description of the
reading**, never an assertion that the direction is finished. The step **asks and nothing else** —
it never closes a strategy, never proposes, never amends and never lifts a gate.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-direction-health.sh` — the step; its subject
  list gains one entry and its header one paragraph.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the step's contract.

## Implementation Steps

1. Read `step-direction-health.sh` end to end, including how `direction-overdue` and
   `direction-dormant` compose their `heading`/`body` and how `direction-none` is addressed to
   nobody.
2. Add the `arrived` subject: key `direction-arrived:<slug>`, addressed to the strategy's
   assignee, `heading` naming the direction, `body` naming **what landed** and **the date**.
3. Word the body as a reading: it says the direction's work is all in and nothing is in flight, and
   asks whether to close it — never that it is finished.
4. Add `arrived` to the summary counts beside live/overdue/dormant/unreadable.
5. Change no gate: the asked-once ledger, the per-tick cap, the quiet hours and the working-day
   hold all apply through `ask-question.sh` unchanged.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An `arrived` direction produces exactly one subject, keyed `direction-arrived:<slug>`, addressed
  to its assignee.
- The second tick over the same reading asks nothing (the existing asked-once gate).
- The body names what landed and the date, and asserts nothing about the direction being finished.
- `unreadable` is still counted and never asked about.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- The step run twice over an arrived fixture, showing one question then none.

**Gate** — what must pass before approval:

- The step reaches no strategy writer — `create.sh`, `amend.sh` and `close.sh` are all unreachable
  from it.

## Considerations

- A direction can be arrived on one tick and not the next (new work lands). The asked-once gate
  means the operator is asked once regardless; that is the intended bound, not a bug.
