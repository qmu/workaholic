---
created_at: 2026-08-31T20:22:50+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: repair-a-mechanically-resolvable-conflict-instead-of-reporting-it
merge_policy:
verification_handoff: 
---

# Drill the stranded-publication repair offline

## Overview

PROPOSED. The measured failure ran for a full day with the loop reporting it hourly, so the
regression this mission must not allow is the repair quietly ceasing to fire. A drill is how
that becomes a red check run named after the behaviour rather than a silence. This ticket
adds the drill and its register row, both written against the behaviour and not a return
shape.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — the dispatcher; a new `verify-*` arm is what `verify-all`
  derives its set from.
- `docs/loop-drill-runbook.md` §9 — the drill register, one table and one reader; an
  unclassified drill is `skipped:unclassified` and fails the suite.
- `.github/workflows/loop-drills.yml` — one matrix leg per drill, so the red check run is
  named after the drill and `/moderate`'s `drill-health` step can name it.
- `plugins/workaholic/skills/drive/scripts/drill-register.sh` — the register's one reader.

## Implementation Steps

1. Add one `verify-*` arm that seeds the measured shape offline: a base and two branches
   colliding only on a generated region, plus a third colliding on content.
2. Assert the **behaviour**: the mechanical pair is settled and delivered without a person;
   the content one is refused by its own word with its branch byte-identical; a re-run of
   either is a no-op.
3. Register it in `docs/loop-drill-runbook.md` §9 with a `bearing: "breaker"` row written
   against that behaviour — a drill with no breaker row is `unproved` and counted outside the
   passing total.
4. Add its matrix leg to `.github/workflows/loop-drills.yml`, hermetic: no credential, no
   permission beyond the default read, no network call.
5. Add the failure-reason to file blame row the runbook's tables carry, so an operator meeting
   the red check knows where to look.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-all` runs the new drill and reports it in the drill
  vocabulary (`pass` / `fail` / `skipped:<reason>`).
- The drill fails when the repair is reverted, and passes when it is present.
- The drill runs with no credential and no network.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-all`
- `node scripts/test-workflow-scripts.mjs` — which fails on a drill the register does not
  classify.

**Gate** — what must pass before approval:

- The register row is a breaker written against the behaviour, not against a return shape.

## Considerations

- Seeding a merge conflict deterministically is the fiddly part; reuse whatever the
  localization ticket built rather than writing a second seeder.
- The drill proves the loop's own repair. It cannot prove the consuming repository's incident
  is gone, since that repository may be on a different plugin version — say so in the runbook
  row rather than implying wider coverage than the drill has.
