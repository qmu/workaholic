---
created_at: 2026-08-26T11:00:17+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260826110016-pin-the-three-refusals-with-a-hermetic-test.md
mission: say-when-the-loop-has-run-out-of-direction
merge_policy:
verification_handoff: 
---

# Drill the direction-health chain with no network

## Overview

Every other part of this loop is provable on demand rather than by waiting for a tick —
`verify-specificate`, `verify-implement`, `verify-plan`, `verify-status`, `verify-cadence`,
`verify-planner`, `verify-standup`, `verify-moderate`, `verify-propose`. Add
`verify-direction-health`: seed an overdue direction, a dormant one and an empty tree, then
assert each reading, each question key, the once-only gate, and that nothing was written.

No network and no credential, so the chain is provable by an operator on demand rather than
by waiting an hour and reading a channel.

## Policies

- `workaholic:operation` / `policies/delivery.md` — a chain provable on demand beats one observed in production
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — the drill; `verify-propose` is the closest existing verb
  (it drills a brake with no network at all) and is the shape to follow.
- `docs/loop-drill-runbook.md` — the operator procedure and the failure-reason → file blame
  tables; a new verb that is not in the runbook is a verb nobody runs.
- `CLAUDE.md` — the drill's verb list.

## Implementation Steps

1. Read `cmd_verify_propose` in full — it establishes how a drill seeds strategies and
   asserts a gate with no `gh` call, and this verb must not invent a second way.
2. Seed three trees: one strategy past its `target_date` with landed work, one `active`,
   in-date, owned strategy with nothing landed/waiting/proposed, and one with no `active`
   strategy at all.
3. Assert per tree: the reading from `direction-state.sh`, the question key
   `direction-overdue:<slug>` / `direction-dormant:<slug>` / `direction-none`, and that a
   second run of the step asks nothing (the once-only gate).
4. Assert nothing was written — no file under `.workaholic/strategies/`, no commit, no
   branch, no issue.
5. Make it runnable with no network and no credential. A drill that needs a token is a
   drill nobody runs on the day it matters.
6. Add the verb to `docs/loop-drill-runbook.md` with its failure-reason → file table, and
   to `CLAUDE.md`'s verb list, in the same commit.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-direction-health` passes with no network and no
  credential
- All three readings, all three keys and the once-only gate are asserted
- The drill leaves no file, commit, branch or issue behind
- The verb appears in the runbook with its blame table and in `CLAUDE.md`

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-direction-health`
- The same command with networking unavailable, asserting an identical result
- `git status --porcelain` before and after, asserting no difference

**Gate** — what must pass before approval:

- All four criteria hold, and the existing drill verbs still pass

## Considerations

- `loop-drill.sh` is operator tooling outside the plugin and assumes the server's full
  environment; this verb must be the part of it that assumes least, since its whole value is
  being runnable when nothing else is.
