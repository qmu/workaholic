---
created_at: 2026-08-27T14:24:44+00:00
status: done
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

## Final Report

Development completed as planned. `step-direction-health.sh` gains the `arrived` subject, keyed
`direction-arrived:<slug>`, addressed to the strategy's `assignees`. The heading names the
direction and, when there is something to name, **what landed and the date**
(`(1 item(s) landed, dated 2027-06-23)`); the body — 23 words, inside notify's 25-word bound —
says everything attributed has landed and nothing is waiting, and asks whether it ended, closing
with *the loop closes nothing*. It asserts nothing about the direction being finished. `arrived`
joins the summary counts beside live/overdue/dormant/unreadable, and no gate moved: the
asked-once ledger, the per-tick cap, the quiet hours and the working-day hold all still come
from `ask-question.sh`.

**One dependency this ticket did not anticipate**: the body must name what landed and the date,
and neither reached the step. `direction-state.sh` composes only, and the survey's `refused`
rows — the shape an arrived-and-overdue direction arrives in — carried neither `landed` nor
`target_date`. Both are now **projected**: `survey-strategies.sh` adds `landed_count` and
`target_date` to the refused map (additive, the same shape `quiescent` took), and
`direction-state.sh` projects `landed` and `target_date` onto every row. Nothing counts anything
twice, and no artifact gained a field.

Verified: over the arrived fixtures the step emits exactly one subject per arrived direction,
addressed to its assignee; `ask-question.sh` allows the first ask under
`direction-arrived:arrived` and refuses the second `already_asked`; `unreadable` is counted and
never asked about. `node scripts/test-workflow-scripts.mjs` — 4031 passed, 0 failed.

**Gate**: the step reaches no strategy writer. Its closure (the step plus `direction-state.sh`,
comments stripped) names none of `create.sh`, `amend.sh`, `close.sh` — pinned by the suite and
by `loop-drill.sh verify-arrival`.

### Discovered Insights

- **Insight**: a reading that must be *quoted to a person* needs the facts it quotes projected
  all the way through the composing readers, and the refused rows are where that breaks.
  **Context**: the useful case for `arrived` is a direction whose date has passed, which is
  refused, and the refused projection is a hand-written `map({...})`. A reading added only to
  the row is invisible to exactly the consumer that needed it.
