---
created_at: 2026-09-02T04:20:38+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: take-the-moderation-tick-s-log-off-main
merge_policy:
verification_handoff: 
claim: work-20260906-025904
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

## Final Report

Development completed, with one deliberate resolution of the ticket's own stated fork recorded
here and in the code.

**The premise moved.** The ticket composes `migrate-moderations-off-main.sh` and reads
`step-open-log.sh`'s hydrate — both **deleted on 2026-09-03**, three days after the ticket was
written, when the log branch was retired and `.workaholic/moderations/` became git-ignored.
Steps 1-3 as literally written are therefore unimplementable: there is no mover to compose, and
`workaholic:workaholify` now states that no migration at the converge seam may reach the network.

**What is still true, and is what shipped.** A `.gitignore` added after the fact never untracks
what is already tracked, so a repository whose earlier ticks wrote day files to the base still
carries them — the residue the ticket calls its own second half — and nothing anywhere read it.
`step-open-log.sh` now reads it (`git ls-files`, local, no network) and raises
`log_tracked_on_base`, a `degraded` finding with an `event`, classified `repairable` so
`file-findings` files it once through `[FB]` → `/specificate` → `/implement` rather than
restating it hourly at nobody (the ticket's own Considerations asked for exactly that bound).

**Step 5's decision, made and stated.** The step **reports and moves nothing**, and that is the
design rather than the fallback: writing a second mover is what the composition rule forbids, and
an unattended tick deleting tracked files from the base on its own reading is wider than what the
retirement left the tick. The acceptance is disjunctive — *land the move **or** raise a finding,
never both silent* — and this satisfies it. The reasoning is written into the script, the step's
spec and the findings-classification table, not just here.

The reading is three-valued: tracked files are a finding; a root that is not a git repository has
no base to be on (a drill's throwaway root) and is **not** a degradation; only a git that failed
*inside* a repository is `log_tracking_unreadable`, because a reading we could not take must never
render as clean.

### Discovered Insights

- **Insight**: `open-log`'s row in the findings-classification table read
  `needs_ruling — Bookkeeping; it produces no finding to file`, which became false the moment the
  step produced one. The table's own rule (an unclassified step id reads `needs_ruling`) would
  have silently swallowed the new finding rather than filing it.
  **Context**: a step that grows its first finding must be re-classified in the same change, or
  the finding is raised and filed by nobody — a failure that looks exactly like a working tick.
- **Insight**: the drill's throwaway root is not a git repository, so any reading a step takes
  from git must treat "no repository" as not-applicable rather than as a degradation, or every
  drill goes red on a healthy tree.
  **Context**: `verify-moderate` runs `run.sh` against `mktemp -d`; several steps here already
  key on that shape, and `persist-log.sh` names it `not_a_repo` for the same reason.
