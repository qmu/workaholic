---
created_at: 2026-08-27T05:22:41+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deliver-and-retire-what-the-loop-already-proved-finished
merge_policy:
verification_handoff: 
---

# Drill both acts with no network

## Overview

PROPOSED. This mission's two acts are outward-facing and destructive-adjacent: a merge and a
retirement (close a pull request, delete a branch, reap a worktree). Both must be provable on
demand rather than by waiting for a tick, and provable with **no network** — the standing shape
`verify-merged-claim` and `verify-close` already set, where the transport is stubbed and the
fixture is built locally.

Two drills: `verify-retire` over a squash-merged fixture, and `verify-delivery-retry` over a
unit whose merge was refused `session_type_cannot_merge`. Each carries a **deliberately broken
seam** that proves the drill can fail — a drill that passes over a broken seam proves nothing.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — operator tooling outside the plugin; both drills land here.
- Its existing `verify-merged-claim` and `verify-close` subcommands — read both in full for the
  squash-merge fixture, the transport stub, and the broken-seam row's shape.
- `docs/loop-drill-runbook.md` — the operator procedure and the failure-reason→file blame tables.
- `CLAUDE.md` — the drill subcommand list.

## Implementation Steps

1. Read `verify-merged-claim` and `verify-close` end to end before writing either drill: the
   squash-merged fixture, the stub seam and the deliberately-broken row are all already solved
   there, and a second solution to any of them is the drift to avoid.
2. `verify-retire`: build a fixture whose claim reads `superseded`, run the step, and assert
   the three acts and their idempotence on a second run. Assert a non-`superseded` row is
   refused by its own name, and that an `ambiguous_claim` and an `unanswerable` row are each
   refused by theirs.
3. `verify-delivery-retry`: build a unit whose recorded merge outcome is
   `merge_refused: session_type_cannot_merge`, run the retry, and assert one attempt, the
   recorded new outcome, and the token. Assert a scan-held row is skipped by name and its token
   behaviour is unchanged.
4. Give each drill a deliberately broken seam and assert the drill **fails** over it.
5. No network in either: the transport is stubbed and the fixture is local.
6. Register both in `docs/loop-drill-runbook.md` with their failure-reason→file rows, and in
   `CLAUDE.md`'s subcommand list, in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-retire` passes over a healthy tree.
- `sh scripts/e2e/loop-drill.sh verify-delivery-retry` passes over a healthy tree.
- Each fails over its deliberately broken seam.
- Neither makes a network call.
- Both are documented in the runbook with blame rows.

**Verification method** — the commands/tests/probes that prove them:

- Run both subcommands.
- Run both with the network unavailable and confirm the results are identical.
- Break each named seam in turn and confirm the corresponding drill fails.

**Gate** — what must pass before approval:

- The broken-seam rows are present and demonstrated, and no drill reaches the network.

## Considerations

- The drills are operator tooling: they assume the server's full `gh` and `qfs` and ship to no
  other agent. Keep them out of the plugin.
- A drill that needs the network is a drill nobody runs. That is why the stub is a requirement
  rather than a convenience.

## Final Report

Development completed as planned.

Both drills follow `verify-close`'s solved shapes rather than re-solving them: the same local
bare origin, the same `PATH` stub for `gh`, the same literal branch names, the same
`_before`/`_after` checkout comparison, and the same deliberately-broken-row discipline. Neither
makes a network call — proved by the fixture being local and the transport stubbed, and by both
drills passing identically with no remote of any kind reachable.

`verify-retire`: 8 load-bearing rows. `verify-delivery-retry`: 6.

Both broken seams were demonstrated rather than asserted. Replacing `retire-claim.sh`'s verdict
test with `if false` turned `retire_refuses_a_judgement` red while every other row stayed green —
and retired a live claim's branch, which is exactly the damage the gate prevents. Removing
`retry-undelivered.sh`'s verdict test turned two rows red together. Both scripts were restored
and both drills re-run green.

### Discovered Insights

- **Insight**: The retirement is not idempotent in the sense the ticket assumed, and the drill
  found it.
  **Context**: The first draft asserted that a second run reports `already_gone`. It does not: a
  completed retirement **deletes the branch**, and the claim oracle is the set of unmerged remote
  branches, so the row is simply gone and the honest answer is `no_such_claim` with all three
  acts `not_attempted`. `already_gone` and `already_closed` are reachable only on a **partial**
  retirement — the measured case where a cloud container may push but not delete a branch — so
  the drill now asserts both properties separately, on two different superseded claims.

- **Insight**: The retry's "redundant" second gate is the live backstop, not dead code.
  **Context**: Widening the verdict gate for the broken-seam proof made the scan-held unit stop
  at `scan_held:hard` — the gate whose own header calls it redundant by construction. So the
  defence-in-depth argument recorded in ticket 2 is demonstrably right: with the first gate gone,
  the second is what stands between an unattended run and a merge past a secret finding. The
  runbook records this so a later reader does not delete it as unreachable.

- **Insight**: `no_open_pull_request` is a *positive* assertion in the retry drill.
  **Context**: With the stub answering every pulls query with an empty list, an undelivered unit
  reaching that refusal proves both gates passed and the merge seam was entered — which is the
  strongest statement available without a real pull request, and it costs no network.

- **Insight**: A fixture needs two superseded claims, not one.
  **Context**: Because each retirement consumes its own claim, any second property about a
  superseded claim needs a second one to be proved on. This is the same reason `verify-close`
  builds three units rather than reusing one.
