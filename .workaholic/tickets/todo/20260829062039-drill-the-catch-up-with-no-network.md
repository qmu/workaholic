---
created_at: 2026-08-29T06:20:39+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: land-the-loop-s-own-work-when-the-base-moves-under-it
merge_policy:
verification_handoff: 
---

# Drill the catch-up with no network

## Overview

PROPOSED. `scripts/e2e/loop-drill.sh verify-catch-up` over a git-backed fixture and a bare
local origin: a mechanical conflict caught up and delivered, a content conflict refused with
the branch byte-identical, a foreign claim untouched, a scan-held pull request never caught
up, a second run a no-op.

**A breaker row that fires the moment the bound is widened** to a claim this identity does not
hold — the drill must be provably able to fail, on the behaviour rather than on a return shape,
so a refactor that keeps the shape and loses the bound still fires it.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — every outcome reported by its own name

## Key Files

- `scripts/e2e/loop-drill.sh` — the drill harness; operator tooling outside the plugin.
- `docs/loop-drill-runbook.md` — the operator procedure and the failure-reason→file blame table.
- The ticket-1 fixture — reused rather than rebuilt.

## Implementation Steps

1. Add the `verify-catch-up` verb, composing the ticket-1 fixture over a bare local origin
   with the transport stubbed. No network at any point.
2. Drill five rows: mechanical caught up and delivered; content refused, branch byte-identical;
   a foreign claim untouched; a scan-held pull request never caught up; a second run a no-op.
3. Add the breaker row: wire the identity bound open and prove the drill fails. Write it
   against the **behaviour**, not the output shape.
4. Register the verb in `docs/loop-drill-runbook.md` with its blame table rows.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Five rows plus a breaker, all with no network and no `gh`.
- The breaker is proved able to fail against a deliberately widened bound.
- Nothing outside the fixture is written.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-catch-up`

**Gate** — what must pass before approval:

- The drill is green on the finished mission and red on the deliberately broken seam.

## Considerations

The drill assumes the server's full `gh` and `qfs`, like every other verb, and ships to no
other agent. Keep it outside the plugin.
