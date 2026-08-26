---
created_at: 2026-08-26T08:20:29+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-when-the-loop-has-run-out-of-direction
merge_policy:
verification_handoff: 
---

# Add the moderate step direction-health

## Overview

A reading nobody is told is the failure this whole mission exists to end. Add the
`/moderate` step `direction-health`: it reads `direction-state.sh` and hands every
non-`live` reading to the check-in as a question addressed to the direction's assignee,
keyed `direction-overdue:<slug>` / `direction-dormant:<slug>` / `direction-none`.

The check-in's existing machinery applies unchanged — the working-day and quiet-hour
holds, the asked-once gate, the three-state answer reader (`never_asked` / `asked` /
`answered`) and the once-more re-ask rule. `unreadable` is reported in the step summary
and **never asked about**, exactly as `strategy-pace` refuses to spend a person's
attention on our own degradation.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-direction-health.sh` — new; modelled
  on `step-strategy-pace.sh`, which is the closest existing shape (a pure read handed to
  the check-in as a question with a name on it).
- `plugins/workaholic/skills/moderate/scripts/run.sh` — the flat `STEPS` list the step
  must be registered in.
- `plugins/workaholic/skills/moderate/reference/workflow.md` and `SKILL.md` — the step
  contract and the step count.
- `CLAUDE.md` — the `/moderate` row's step count and description.

## Implementation Steps

1. Read `step-strategy-pace.sh` end to end, header included: it records why the
   question surface was chosen over `/propose`'s run report and over the proposal issue,
   and this step is admitted on the same grounds.
2. Copy its shape: `--tick` / `--root`, one JSON line out, `emit` with `status`,
   `reason`, `summary`, `needs_agent` and the post-facing `event`.
3. Call `direction-state.sh` and partition: `overdue` and `dormant` become question
   subjects addressed to that strategy's assignee; `unreadable` goes in the summary
   only; `none` becomes one repository-level question with no slug.
4. Hand the subjects to the check-in through `needs_agent` in the shape
   `step-strategy-pace.sh` uses, so `step-human-checkin.sh` needs no change: the keys are
   the step's, the gate and the ask are the check-in's.
5. Register the step in `run.sh`'s `STEPS`, positioned beside `strategy-pace` and before
   `human-checkin` (which must stay last and stay deadline-exempt).
6. Update `moderate/reference/workflow.md`, `moderate/SKILL.md` and `CLAUDE.md` — the
   step count moves — in the same commit.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The step emits one JSON line with a `direction-health` step id and contributes a
  report row on every tick, including when every direction reads `live`
- Each non-`live` reading produces exactly one question key, asked at most once, holds
  applied; `unreadable` produces none
- `run.sh`'s `STEPS` names the step and `human-checkin` is still last

**Verification method** — the commands/tests/probes that prove them:

- `sh plugins/workaholic/skills/moderate/scripts/step-direction-health.sh --tick
  drill-0000 --root .` on this repository
- `sh plugins/workaholic/skills/moderate/scripts/run.sh --only direction-health`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The step writes nothing outside the tick log and calls no writer of any artifact
- The documentation this change makes wrong is updated in the same commit

## Considerations

- The check-in's per-tick ceiling is five questions and its per-day bound ten. A
  repository with several expired directions could crowd the other steps out for an hour;
  the questions are held, not dropped, so this is a latency cost rather than a loss —
  worth stating in the step header rather than tuning a cap nobody has measured.
- `direction-none` has no assignee to address. It should be asked without a mention
  token rather than aimed at whoever happens to run the tick.
