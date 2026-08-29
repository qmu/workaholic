---
created_at: 2026-08-29T19:21:37+00:00
status: done
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

## Final Report

**Implemented.** `sh scripts/e2e/loop-drill.sh verify-operator-pulls` — **16 load-bearing rows,
0 failures, 1 proved breaker**, with **no network, no credential and no `gh` on the real PATH**.

- **The fixture** is a throwaway git repository with a bare-style local origin remote and a
  stubbed `gh`, carrying **three publications with different provenance** (the ticket's own
  Consideration): a ruling whose title says nothing about rulings, a strategy amendment titled
  `[Ruling] …`, and an ordinary `[Proposal]` that auto-merged. A stub answering one shape for
  every pull request would let a title-keyed derivation pass, so the fixture is built to refuse
  that.
- **The whole chain is drilled** (step 2): the shared rule over its four shapes; the derivation
  naming the ruling and the strategy and **excluding** the proposal; the reader's four values
  with the **null** age on `unreadable`; the question reaching its person **exactly once over
  two ticks** (the drill plays `run.sh`'s part by appending the ask's own log line between the
  two calls, since the gate reads the tick log); the settled case asking nobody; the hold's
  reading shared rather than re-derived; and that the step reaches no merge, close, push, gate
  or survey call site.
- **The breaker is written against the BEHAVIOUR** (step 4): a copy of the derivation wired at
  the pull request's **title** instead of the seam's refusal word — which is what
  `list-open-rulings.sh` does on purpose, for a brake. It loses the retitled ruling (members
  become `[]`), so the row is **proved able to fail** rather than asserted to be. A breaker
  written against the return shape would survive a refactor that keeps the JSON and loses the
  bound. The broken copy is given a real `lib/publication-refusal.sh` beside it, so it cannot
  pass for the unrelated reason of refusing `no_refusal_rule`.
- **Registered** (step 5) in `docs/loop-drill-runbook.md` §9 as **`hermetic`** with `Breaker:
  yes` and its mission slug, plus a quick-reference row. `drill-register.sh drill
  verify-operator-pulls` resolves it; `verify-all --list` names it (32 drills, 24 hermetic);
  `verify-all --only verify-operator-pulls` reports `proved: 1, unproved: 0, failed: 0`; and
  `verify-all --list --kind hermetic` — the matrix `.github/workflows/loop-drills.yml` derives —
  includes it, so it runs as **its own matrix leg** on every push.
- **It writes nothing outside its own fixture**: the drill asserts the checkout is byte-identical
  after it runs.

**Gate:** `verify-operator-pulls`, `verify-all` and `node scripts/test-workflow-scripts.mjs` all
pass, and the breaker demonstrably fails the drill when applied.
