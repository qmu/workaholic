---
created_at: 2026-08-26T11:00:16+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260826110016-write-the-one-reader-of-a-direction-s-lifecycle-state.md
mission: say-when-the-loop-has-run-out-of-direction
merge_policy:
verification_handoff: 
---

# Add the moderate step direction-health

## Overview

A reading nobody reads changes nothing. Add `/moderate`'s fifteenth step,
`direction-health`, which reads `direction-state.sh` and hands every non-`live` reading to
the check-in as a question **addressed to the direction's assignee** — the same route
`step-strategy-pace.sh` and `step-stalled-units.sh` already take, and the only path in this
repository from *the loop is out of fuel* to *a person is asked*.

Keys are `direction-overdue:<slug>` / `direction-dormant:<slug>` / `direction-none`, asked
once, with the existing working-day and quiet-hour holds, the three-state answer reader and
the once-more re-ask rule applying unchanged. `unreadable` is reported in the step summary
and **never asked about** — spending a person's attention on our own degradation is what
`strategy-pace` already refuses.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/runtime-behavior.md` — a degraded read is named, never a step that ran and found nothing

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-direction-health.sh` — new; modelled on
  `step-strategy-pace.sh`, which is the closest existing shape (reads a survey, hands
  `needs_agent` to the check-in, asks nothing itself).
- `plugins/workaholic/skills/moderate/scripts/run.sh` — the `STEPS` list; the new step goes
  beside `strategy-pace`, before `human-checkin`, which must stay last.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the step contract.
- `plugins/workaholic/skills/moderate/SKILL.md`, `CLAUDE.md` — the step count and purpose.

## Implementation Steps

1. Read `step-strategy-pace.sh` in full, including its header's three refused surfaces —
   this step is admitted on exactly the same argument and must not re-argue it differently.
2. Read `step-human-checkin.sh` and `ask-question.sh` so the `needs_agent` shape, the key
   derivation and the hold semantics are matched rather than approximated.
3. Write `step-direction-health.sh`: call `direction-state.sh`, partition the rows, and
   emit `needs_agent` carrying each non-`live` reading with its slug, assignee and key.
4. `unreadable` rows and a refused reader are `degraded` with the reason named, and produce
   no question.
5. Add `direction-health` to `STEPS` in `run.sh`, keeping `human-checkin` last.
6. The step asks nobody itself, writes nothing, calls no writer. It never lifts a
   `/propose` gate: a `dormant` direction that is somehow also gated stays gated.
7. Update `reference/workflow.md`, `moderate/SKILL.md` and `CLAUDE.md` — including the step
   count, which this change moves from fourteen to fifteen.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A non-`live` reading produces exactly one question, keyed as above, addressed to that
  direction's assignee
- The same reading on a later tick produces no second question (the asked-once gate)
- `unreadable` and a refused reader produce a named `degraded` line and no question
- `run.sh` invokes the step and it contributes a report line on every tick

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — a case per reading asserting the key and the
  addressee, one asserting the second tick is silent, one asserting `unreadable` is named
- A `run.sh --only direction-health` invocation asserting one report row

**Gate** — what must pass before approval:

- The suite passes and no existing `/moderate` step's output changes

## Considerations

- `direction-none` carries no slug by construction — it is a fact about the repository. Its
  addressee is a judgment the step must make explicitly rather than leave empty; where no
  assignee can be resolved the step reports it rather than asking nobody.
- The step count appears in several documents; missing one is the documentation defect this
  repository's own rule names.
