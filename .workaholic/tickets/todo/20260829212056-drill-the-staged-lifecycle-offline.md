---
created_at: 2026-08-29T21:20:56+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-direction-s-lifecycle-a-declared-stage
merge_policy:
verification_handoff: 
---

# Drill the staged lifecycle offline

## Overview

PROPOSED. Every mechanism in the direction layer that shipped since 2026-08-26 ships with
its own hermetic drill and a **breaker row** written against the *behaviour* rather than
a return shape — `verify-direction-health`, `verify-arrival`, `verify-expiry`,
`verify-residue`, `verify-corpus-boundary`. The staged lifecycle owes the same, and since
2026-08-29 `verify-all` runs the hermetic set on every push through `Loop Drills`, one
matrix leg per drill, so a drill that exists is a proof that keeps holding rather than one
somebody remembers to run.

`verify-stage` walks the whole mission end to end with **no network**: declare → move →
read → gate → order → render → ask.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/verification.md` — a proof that runs on every turn

## Key Files

- `scripts/e2e/loop-drill.sh` — the new `verify-stage` arm, over a git-backed fixture with
  the transport stubbed.
- `docs/loop-drill-runbook.md` — §9's drill register, the one table `drill-register.sh`
  reads; the row classifies `verify-stage` as **hermetic** so `Loop Drills` runs it.
- `scripts/test-workflow-scripts.mjs` — the pin that fails on a drill the register does
  not classify.
- `CLAUDE.md`.

## Implementation Steps

1. Read `docs/loop-drill-runbook.md` §9 whole and one recent drill arm whole
   (`verify-expiry` is the closest shape — a git-backed fixture whose dates come from the
   run clock) before writing the arm.
2. Build the fixture: three directions on a bare local origin, one per stage, plus one
   carrying **no** `stage:` line at all, so the absent-means-進行中 convention is drilled
   rather than assumed.
3. Assert, in order:
   - a stage is written by `create.sh` and refused outside the closed set with the
     artifact byte-identical;
   - an announced move reaches `amend.sh`, appends one dated `## Schedule` line, and its
     publish reports `merge_reason: strategy_touching` with `WORKAHOLIC_AUTO_MERGE=1`
     **deliberately set**;
   - `direction-state.sh`'s `state` is byte-identical across all three stages;
   - the 観察中 direction is refused `observing` and opens no issue, while the 進行中 and
     改良中 ones propose exactly as today;
   - 改良中 sorts before 進行中 with set membership unchanged;
   - the digest, the roadmap and the question all name the stage;
   - each transition question is asked exactly once over two ticks and nothing moves the
     stage.
4. Assert the negatives explicitly: no reading closes, amends or re-dates a direction; the
   strategy writer set is still three; no question is derived from a handoff or a block.
5. Add the register row in `docs/loop-drill-runbook.md` §9 with its failure-reason→file
   blame entry.
6. Carry a **breaker row** written against the behaviour, not the return shape: wire the
   `observing` gate at a *derived* reading (`quiescent`) instead of the declared field.
   A refactor that keeps the output shape while letting evidence silence a direction must
   fire it — that substitution is the mission's central failure mode.
7. Prove the breaker can fail before shipping it, and prove the drill passes on the
   unmodified tree.
8. Update `CLAUDE.md` in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-stage` passes on the unmodified tree with no
  network, no `gh` and no Slack post.
- The breaker row fires when the `observing` gate is wired at a derived reading.
- `verify-all` includes it and `Loop Drills` runs it as its own named matrix leg.
- The drill is classified in the register; nothing reads `skipped:unclassified`.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-stage`
- `sh scripts/e2e/loop-drill.sh verify-all`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The drill writes nothing outside its fixture and makes no network call.

## Considerations

- The drill is the last ticket because it asserts the whole chain; if it is driven early
  its assertions are written against work that does not exist yet.
- A drill with no breaker row counts as `unproved` in `verify-all`'s tally, which is a
  gap in coverage rather than a broken mechanism — this one must not land that way.
