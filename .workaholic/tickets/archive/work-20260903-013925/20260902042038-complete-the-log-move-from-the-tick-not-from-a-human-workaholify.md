---
created_at: 2026-09-02T04:20:38+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: take-the-moderation-tick-s-log-off-main
merge_policy:
verification_handoff: 
claim: work-20260903-013925
---

# Complete the log move from the tick, not from a human workaholify

## Overview

PROPOSED. The off-main log design reaches a repository only through
`converge-layout.sh`, which runs from `/workaholify` — a command a person invokes. So
between the plugin shipping the design and a human running that command, every tick keeps
writing day files to the base. Measured on a consuming repository: twelve days of silent
hourly accumulation, ended only when the operator ran `/workaholify` by hand on
2026-09-02, and even then they had to commit and merge the staged removals themselves.

The tick that owns the log already reaches the network — `ensure-log-ref.sh` creates the
branch. This ticket makes the tick responsible for the state of its own log: when it finds
day files still tracked on the base, it either completes the move itself or raises a
per-tick finding that reaches a person, every tick, until the state is repaired. Twelve
days of accumulation is the defect; the leftover files are only its residue.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — a migration nobody runs is not a migration

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-open-log.sh` — the tick's opening seam;
  it already hydrates the log, so it is where the tick learns the log's state.
- `plugins/workaholic/skills/gather/scripts/migrate-moderations-off-main.sh` — the existing
  migration: it seeds the branch and only then untracks, and that order is the safety
  property. Compose it; do not write a second mover.
- `plugins/workaholic/skills/gather/scripts/ensure-log-ref.sh` — proof that the tick
  already reaches the network for this purpose.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — where a per-tick finding is
  reported and where the step's summary is composed.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the per-step specs; the
  step's new behaviour is written here.
- `plugins/workaholic/skills/workaholify/scripts/converge-layout.sh` — the living-migration
  registry; its registration of the migration must stay correct after this change.

## Implementation Steps

1. Reproduce the state, offline: build a throwaway repository whose
   `.workaholic/moderations/` day files are tracked on the base and whose log ref does not
   exist. Confirm today's `step-open-log.sh` reports healthy against it — that is the
   silence this ticket removes.
2. In `step-open-log.sh`, after the hydrate, read whether any `.workaholic/moderations/`
   path is tracked on the base. Report that reading by name; an unreadable one is
   `degraded` with its reason and never rendered as clean.
3. When files are tracked on the base, compose `migrate-moderations-off-main.sh` — never a
   second mover — and land the move through the publish seam the tick already uses. Report
   the outcome in its own word: `moved`, `already_off_base`, or a named refusal.
4. When the move cannot be completed (no network, a refusal from the migration, an
   unwritable ref), raise a per-tick finding rather than passing silently, so the condition
   reaches a person every tick until it is repaired. Route it through the tick's existing
   finding seam; add no new store and no cursor.
5. Decide and state which of the two the step does by default, and why, in
   `moderate/reference/workflow.md`. Both halves are specified; a step that only reports is
   the fallback, never the design.
6. Write the hermetic drill: a repository with day files on the base runs one tick and ends
   with them off the base, or with the finding raised — asserted offline, no network.
7. Update `CLAUDE.md`'s `.workaholic/` runtime conventions and `workaholic:moderate` in the
   same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A tick against a repository with tick-log files tracked on the base either lands the move
  or raises a finding — never both silent.
- The migration is composed, not reimplemented: `migrate-moderations-off-main.sh` stays the
  one mover and its seed-then-untrack order is unchanged.
- A repository already off the base is byte-identical to before this change.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`

**Gate** — what must pass before approval:

- The hermetic drill fails on a repository whose tick log is on the base and passes once it
  is off.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` clean.

## Considerations

- Making the tick move files on the base widens what an unattended tick writes. Bound it:
  the move touches `.workaholic/moderations/` and nothing else, and it goes through the
  publish seam rather than a direct push into any branch the claim protocol owns.
- The finding half must not become an hourly restatement addressed to nobody — that is the
  shape this repository has twice retired status roots for. Route it through the existing
  question machinery, which is asked once per subject.
