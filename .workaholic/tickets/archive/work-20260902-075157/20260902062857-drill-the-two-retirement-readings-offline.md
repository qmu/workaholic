---
created_at: 2026-09-02T06:28:57+00:00
status: done
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

## Final Report

Development completed as planned.

`verify-retired-claim` walks both readings in **one** verb, deliberately: split in two, each half
would pass while the pair stayed broken — a candidate nobody filters on and a filter with nothing
to filter are each individually green.

Six rows over one hermetic fixture (a bare local origin, `gh` stubbed, no network and no
credential): two claims identical in every respect but the state of the mission each names, both
aged out of the heartbeat window and both empty against the base outside `.workaholic/`, so
neither the heartbeat nor the emptiness is what tells them apart.

1. the reading itself — an archived mission is `not_active` with its `status`, an active one
   `active`, a `batch-<ts>` unit its own kind, an unknown one a named absence with no `state`;
2. the ended mission's claim is a candidate under `mission_not_active`, the living one under
   nothing;
3. **the breaker**;
4. the act re-derives the class — refusing the living mission by name, taking the ended one;
5. the stuck-work question is asked about the living claim only, and the subtraction is counted;
6. the checkout is byte-identical afterwards.

**The breaker is written against the behaviour**: the ended mission is moved back to `active/`
and the candidate must disappear. A reader that ignored the mission — the whole defect — would
offer the branch in both states, so a refactor that keeps the JSON shape and loses the bound
still turns the row red.

No matrix leg was added by hand: `.github/workflows/loop-drills.yml` derives its matrix from the
`enumerate` job, which reads the register, so registering the drill is what gives it its own
named check run.

### Discovered Insights

- **Insight**: The fixture has to make the two claims differ in **exactly one** respect. The
  first draft let the ended mission's branch also be the older one, and the row would then have
  passed with the mission reading removed.
  **Context**: Both claims are seeded by one function with the mission slug as its argument, so
  the only asymmetry in the whole fixture is the directory its mission lives in — which is what
  makes row 3 a breaker rather than a restatement.
- **Insight**: The act's `pull_request_open` probe is a **separate** `gh` call from the four-state
  read, so a stub that answers one shape for everything makes every candidate read as held open.
  The sibling drill's header records this; it cost nothing here only because that note existed.
  **Context**: A stub is a model of a transport, and a model that answers one shape is the
  commonest way a hermetic row passes for the wrong reason.
