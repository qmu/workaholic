---
created_at: 2026-08-27T23:22:22+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260827232222-report-what-stands-and-what-is-outstanding.md
mission: finish-the-retirement-the-loop-cannot-complete
merge_policy:
verification_handoff: 
---

# Stop restating a standing blocked retirement

## Overview

`0 retired` over a unit already asked about is a **held** condition, not a new one.
The step's `event` fires only on a successful retirement today, so the root is
already correct — but the summary the root's diff reads must not move while nothing
changes, or a standing block renders as an hourly change. This is the property
`📦 Release Preparation` was retired for, one step over.

The repository has measured the same shape three times: a status restated hourly is
read by nobody by the second day.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — an unchanged condition reads as unchanged

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-retire-claims.sh` — the `summary`
  the diff reads and the `event` the root renders.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — where the previous tick's
  summary is compared; the normalisation set lives with it.

## Implementation Steps

1. Prove the summary is stable across ticks over an unchanged blocked set: the same
   units, the same acts standing, the same refusal must render the same string. Any
   term that moves on its own (an age, a count of ticks, a timestamp) is removed.
2. Keep `event` empty for a tick that retired nothing, so a hold renders no root
   line at all — the independent guard, unchanged.
3. A **newly** blocked unit is a change and must still surface: the summary moves
   when the unit set or an act state moves, so a fresh block is visible the hour it
   happens. Do not suppress by unit — suppress by nothing, and let the diff work.
4. Do not add a second ledger. Ticket 5's asked-once gate already bounds the
   question; this ticket bounds only the **restatement**, and the two must not grow
   into two stores of the same fact.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Two consecutive ticks over an unchanged blocked set produce an identical summary
  and no root line.
- A newly blocked unit changes the summary on the tick it appears.
- No stored cursor and no field on any artifact is added.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-retire`
- `sh scripts/e2e/loop-drill.sh verify-moderate`

**Gate** — what must pass before approval:

- The stability and the still-visible-when-new properties are both drilled, not asserted.

## Considerations

- The tempting fix is a per-unit suppression list. It is refused: the diff already
  answers this question, and a second ledger beside the asked-once gate is how the
  two drift.
- This depends on ticket 4 rather than merely following it: ticket 4 puts the act
  states into the summary, and that is exactly the string whose stability is proved here.
