---
created_at: 2026-08-29T19:21:37+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: follow-the-pull-requests-the-loop-opens-for-a-person
merge_policy:
verification_handoff: 
---

# Drill the operator-facing pull-request reading offline

## Overview

PROPOSED. A drill over a bare origin with the transport stubbed and **no network**,
registered so `Loop Drills` runs it on every push, carrying a breaker row written against
the **behaviour** rather than a return shape.

A drill whose rows carry no `bearing: "breaker"` row is `unproved` and counted outside the
passing total; a drill the register does not classify is `skipped:unclassified` and fails
`scripts/test-workflow-scripts.mjs`.

## Policies

- `workaholic:implementation` / `policies/testing-strategy.md` — a proof runs on every turn
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a failing check names the drill

## Key Files

- `scripts/e2e/loop-drill.sh` — the dispatcher; a new `verify-*` `case` arm.
- `docs/loop-drill-runbook.md` §9 — the drill register (one table, one reader); the new
  row's classification (`hermetic`) and its blame table entry.
- `plugins/workaholic/skills/drive/scripts/drill-register.sh` — the register's one reader.
- `.github/workflows/loop-drills.yml` — the matrix, one leg per drill, so the red check
  run is named after the drill.
- `scripts/e2e/loop-drill.sh`'s `verify-act-effect` and `verify-rulings` arms — the two
  closest precedents (a stubbed transport over a bare local origin; a breaker in halves).

## Implementation Steps

1. Add `verify-<name>` to `scripts/e2e/loop-drill.sh` building a throwaway repository with
   a **bare local origin** and a stubbed `gh`, making no network call on any path.
2. Drill the whole chain: the derivation naming a ruling and a strategy publication and
   **excluding** an ordinary auto-merged proposal; the reader's four values with the null
   age on `unreadable`; the question reaching its person exactly once over two ticks; a
   held subject and its release; and that no reading merged, closed, gated or lifted a
   gate.
3. Assert the byte-identity ticket 5 owns from inside the drill too: the survey's output
   across a repository with an un-acted ruling and one without.
4. Carry a **breaker row** written against the behaviour — e.g. the derivation wired at
   the pull-request **title** instead of the seam's refusal word — and prove the drill
   fails with it in place and passes without. A breaker written against a return shape
   would survive a refactor that keeps the shape and loses the bound.
5. Register the drill in `docs/loop-drill-runbook.md` §9 as `hermetic`, with its
   failure-reason→file blame entry, and confirm `verify-all` picks it up and
   `.github/workflows/loop-drills.yml` gives it its own matrix leg.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The drill passes on the unmodified tree with no network and no credential.
- The breaker row is proved able to fail, and it is written against the behaviour.
- The drill is registered `hermetic` in §9 and runs as its own matrix leg on every push.
- `sh scripts/e2e/loop-drill.sh verify-all` names it and reports no `skipped:unclassified`.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-<name>`
- `sh scripts/e2e/loop-drill.sh verify-all`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- All three commands pass, and the breaker demonstrably fails the drill when applied.

## Considerations

- The drill must write nothing outside its own fixture; the suite already fails a drill
  that touches the working tree.
- A stubbed transport that answers the same shape for every pull request would let the
  derivation pass without exercising the refusal word — the fixture needs at least three
  publications with different provenance.
