---
created_at: 2026-08-29T19:31:03+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-the-two-executors-agree-about-a-proved-empty-claim
merge_policy:
verification_handoff: 
---

# Drill the two executors agreeing with no configured git identity

## Overview

PROPOSED. `verify-ci-retirement` exists, is registered, ran green on every push, and did
not catch this: three proved-`superseded` branches stood for eight days while the drill
passed. Its fixture configures a git identity, so the term that decides in CI is never
varied — the drill proves the split between the two executors under conditions CI does not
have.

This adds the row that would have caught it, and a breaker written against the
**behaviour** rather than a return shape.

## Policies

- `workaholic:implementation` / `policies/testing-strategy.md` — a proof runs on every turn
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:safety` / `policies/least-privilege.md` — a destructive act's bound is what the drill asserts

## Key Files

- `scripts/e2e/loop-drill.sh` — the `verify-ci-retirement` arm and its fixture; the place
  the new row goes.
- `docs/loop-drill-runbook.md` §9 — the drill register and the failure-reason→file blame
  table; the row's classification (`hermetic`) and its `bearing: "breaker"` entry.
- `plugins/workaholic/skills/drive/scripts/list-retirable-claims.sh` — the reader whose
  two readings must agree.
- `plugins/workaholic/skills/drive/scripts/delete-retired-claim-branch.sh` — the act whose
  bounds the drill must assert are unmoved.
- `scripts/test-workflow-scripts.mjs` — fails a drill the register does not classify.

## Implementation Steps

1. Extend `verify-ci-retirement`'s fixture so the candidate reader is exercised **with no
   `user.email` configured** — the state `actions/checkout@v4` leaves a runner in — beside
   the existing identity-configured run, and assert the two readings **agree** on the same
   refs.
2. Assert the safety bound in the same fixture: a branch behind a **live** claim and one
   behind a **foreign** author stay undeletable under both identity states. A repair that
   made CI see every claim as its own would pass step 1 and must fail here.
3. Assert the per-unit legibility ticket 1 adds: a unit absent from a completed turn's
   candidate reading reads by its own name rather than `taken`, and does not hold its
   question.
4. Write the **breaker** against the behaviour — restore the identity-first precedence (or
   whichever term the ticket-2 repair moved) and show the candidate count falling to zero
   while the drill fails. A breaker asserting a return shape would survive exactly the
   refactor that reintroduces this.
5. Keep it **hermetic**: a bare local origin, the transport stubbed, no network and no
   credential; register the row in `docs/loop-drill-runbook.md` §9 with its blame entry,
   and confirm `verify-all` and `.github/workflows/loop-drills.yml` pick it up.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The drill fails on the pre-repair tree and passes after ticket 2 lands.
- Both identity states produce agreeing candidate readings; a live or foreign claim stays
  undeletable under both.
- The breaker is written against the behaviour and is proved able to fail.
- The row is classified `hermetic` in §9 and runs as its own matrix leg.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-ci-retirement`
- `sh scripts/e2e/loop-drill.sh verify-all`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- All three pass, and the breaker demonstrably fails the drill when applied.

## Considerations

- The honest reading of this ticket is that the existing drill's fixture asserted the
  mechanism under the executor's conditions rather than under CI's; the register's
  `unproved` marking would not have flagged it, because the drill *had* a breaker.
- The drill proves the mechanism; only the live origin proves the three branches are gone,
  which is ticket 2's step 6 and stays there.
