---
created_at: 2026-08-30T04:28:04+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: catch-a-reported-claim-up-before-its-conflict-hardens
merge_policy:
verification_handoff: 
---

# Drill the widened catch-up offline

## Overview

PROPOSED. `verify-catch-up` already drills the act over a bare local origin with the
transport stubbed and no network. Extend it with the **widened trigger**, and carry a
breaker written against the **behaviour** rather than a return shape — so a refactor
that keeps the shape and wires the candidate reader back at the delivery verdict
still fires it.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — `verify-catch-up`'s existing rows and its fixture
  (bare local origin, stubbed transport, no network)
- `docs/loop-drill-runbook.md` §9 — the drill register; a drill with no
  `bearing: "breaker"` row is `unproved` and counted outside the passing total
- `plugins/workaholic/skills/drive/scripts/list-catchable-claims.sh` — under test

## Implementation Steps

1. Read `verify-catch-up` whole before extending it: its fixture already builds a
   mechanical conflict, a content one and a scan-held pull request, and the new rows
   should reuse that fixture rather than building a second one.
2. Add rows for: a **`queue_drained` mechanical** claim caught up and pushed; a
   **reviewed** pull request refused with the branch byte-identical; a **`content`**
   one refused exactly as today; a **second run** reporting `already_current`; and a
   claim of **another identity** untouched.
3. Assert the run report names each candidate's outcome, and that no gate, token,
   survey or sort moved.
4. Carry a **breaker** row written against the behaviour: wire the candidate reader
   back at the delivery verdict alone. The drill must go red on it — a pin that
   cannot fail proves nothing — and be reverted.
5. Register the extension in `docs/loop-drill-runbook.md` §9 with its
   `bearing: "breaker"` row and its hermetic classification, so `verify-all` runs it
   and CI names it.
6. No network, no `gh`, no Slack post, and nothing written outside the fixture.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- All five rows pass on the unmodified tree
- The breaker is proved red, then reverted
- The register row exists and the drill is not `unproved`
- No network call, no `gh`, and nothing written outside the fixture

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-catch-up`
- `sh scripts/e2e/loop-drill.sh verify-all`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The drill passes with no network reachable

## Considerations

- The reviewed-pull-request row needs the stubbed transport to answer a reviews read;
  extend the stub rather than reaching the network, and keep the drill hermetic —
  a drill that needs a credential is classified out of the CI set and stops proving
  anything on merge.
