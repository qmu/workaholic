---
created_at: 2026-09-01T12:33:58+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: adjust-the-plan-hourly-not-only-report-it
merge_policy:
verification_handoff: 
---

# Drill the divergence hold and the offer order offline

## Overview

PROPOSED. The two acts this mission adds are both silences: a tick that opens no issue because
work in flight is above the limit, and an offer order that puts the right unit first. A
regression in either is invisible — the loop keeps running and simply plans worse, which is the
exact failure mode the ask describes and which took a person a full day to notice. This adds
`verify-plan-adjust` to the offline drill set and registers it, so both have a breaker written
against the behaviour and CI names the drill when it goes red.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — the dispatcher; `verify-all` derives its set from the `case` arms plus the register.
- `docs/loop-drill-runbook.md` §9 — the drill register and its `bearing` classification.
- `.github/workflows/loop-drills.yml` — one matrix leg per drill.
- `plugins/workaholic/skills/drive/scripts/drill-register.sh` — the register's one reader.

## Implementation Steps

1. Add a hermetic `verify-plan-adjust` arm: no credential, no network, no GitHub, no Slack. It
   seeds a fixture board (two directions, several missions, a queue) and drives the readers and
   gates directly.
2. Assert the **hold**, phrased as the failure it catches: with a declared limit and work in
   flight above it, `/propose`'s gate refuses by name and opens nothing; at or below it,
   origination proceeds unchanged. A regression that ignores the limit fails here.
3. Assert the **absent declaration** case with equal weight: with nothing declared, the gate
   reports `skipped` and behaviour is byte-identical to before. A regression that holds every
   repository by default fails here — and that is the more dangerous direction, because it
   stops the loop silently.
4. Assert the **order**: a fixture board whose stated terms imply a known offer order returns
   exactly that order, and the set of units offered is unchanged from before the ordering
   existed. A regression that reorders by dropping units fails here.
5. Register the drill in `docs/loop-drill-runbook.md` §9 with a `bearing: "breaker"` row
   written against the behaviour — unregistered reads `skipped:unclassified` and fails
   `test-workflow-scripts.mjs`; registered without a breaker is `unproved` and counted outside
   the passing total.
6. Add the failure-reason → file blame rows the runbook keeps, and confirm the drill runs as
   its own matrix leg so `/moderate`'s `drill-health` can name it.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-plan-adjust` passes offline with no credential.
- `verify-all` includes it and reports it in the drill vocabulary.
- The register carries a `bearing: "breaker"` row, so it is not counted `unproved`.
- Reverting the limit gate or the ordering turns the drill red.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-plan-adjust`
- `sh scripts/e2e/loop-drill.sh verify-all`
- `node scripts/test-workflow-scripts.mjs` — the unclassified-drill row.
- Revert each behaviour locally, confirm the drill fails, restore.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`

## Considerations

- **The revert test is the point.** Both behaviours are about something not happening, which is
  the easiest kind of drill to write so that it passes before and after the change. The register
  calls that `unproved` by name; prove the breaker actually breaks.
- The absent-declaration assertion matters more than the hold itself: this mission adds a brake
  to a loop whose measured failure mode this week was going quiet, and a brake that engages by
  default would be indistinguishable from that outage.
- Keep it hermetic. Reaching GitHub to prove no issue was opened would make it credentialed,
  which `loop-drills.yml` cannot run on every push — and the regression is invisible again.
- Drive after tickets 2 and 3; the drill has nothing to break before they land.
