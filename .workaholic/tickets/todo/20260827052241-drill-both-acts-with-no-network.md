---
created_at: 2026-08-27T05:22:41+00:00
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
