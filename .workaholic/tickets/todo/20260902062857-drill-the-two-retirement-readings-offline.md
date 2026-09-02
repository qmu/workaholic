---
created_at: 2026-09-02T06:28:57+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: retire-a-claim-whose-work-is-finished-or-abandoned
merge_policy:
verification_handoff: 
---

# Drill the two retirement readings offline

## Overview

PROPOSED. Both readings this mission adds decide whether a branch is deleted, and the
measured failure ran for hours with nothing catching it. A drill with a breaker row written
against the behaviour is what makes a regression name itself in CI rather than reaching the
operator's channel.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — the dispatcher; a new `verify-*` arm.
- `docs/loop-drill-runbook.md` §9 — the drill register, the one table `drill-register.sh`
  reads; an unclassified drill fails the suite.
- `.github/workflows/loop-drills.yml` — one matrix leg per drill, so the red check run is
  named after the drill.
- `scripts/test-workflow-scripts.mjs` — fails on a drill the register does not classify.

## Implementation Steps

1. Add one hermetic drill arm covering both readings end to end: a claim whose mission is
   archived becomes a candidate and its branch is deleted; a claim whose retirement is owned
   raises no stuck-work question and is counted instead.
2. Seed it from the drill's own fixtures — no network, no `gh`, no credential, and no
   permission beyond the default read.
3. Register it in `docs/loop-drill-runbook.md` §9 with a `bearing: "breaker"` row written
   against the **behaviour**: which failure the drill goes red on, not which return shape.
4. Add its matrix leg to `.github/workflows/loop-drills.yml`.
5. Confirm `verify-all` reports the new drill in its own vocabulary and that an unclassified
   drill still fails the suite.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-all` names the new drill and passes.
- The drill is classified in the register with a breaker row written against behaviour.
- The drill runs in CI as its own matrix leg and needs no credential.
- Reverting either reading makes the drill fail, and it fails naming that drill.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-all`
- `node scripts/test-workflow-scripts.mjs`
- Revert each reading locally and confirm the drill goes red for it.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`

## Considerations

- A drill that only asserts a return shape is `unproved` by the register's own rule; the
  breaker row has to name the behaviour a regression would break.
