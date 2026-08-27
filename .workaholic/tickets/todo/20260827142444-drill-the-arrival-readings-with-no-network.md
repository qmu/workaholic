---
created_at: 2026-08-27T14:24:44+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260827142444-report-the-arrival-as-a-moderation-event.md
mission: say-when-a-direction-has-arrived
merge_policy:
verification_handoff: 
---

# Drill the arrival readings with no network

## Overview

PROPOSED. Add `scripts/e2e/loop-drill.sh verify-arrival`, over local fixtures with the transport
stubbed and **no network at all** — the shape `verify-direction-health` already sets for this
layer. It drills: arrived, dormant, overdue-and-arrived, unreadable, the asked-once gate, and its
own deliberately broken seam that proves the drill can fail.

The broken seam is the point. A drill that cannot fail proves nothing, and every recent drill in
this repository carries one.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — the drill harness; `verify-direction-health` is the sibling to
  follow, including how it stubs the transport and builds fixtures.
- `docs/loop-drill-runbook.md` — the operator procedure and the failure-reason→file blame table.

## Implementation Steps

1. Read `verify-direction-health` end to end — fixture construction, transport stubbing, the
   assertion style and its own broken-seam case.
2. Add `verify-arrival` with fixtures for each reading: arrived; dormant; a direction both overdue
   and arrived (proving `arrived` wins); unreadable.
3. Drill the asked-once gate: run the step twice over the arrived fixture, assert one question
   then none.
4. Add the deliberately broken seam and assert the drill fails on it.
5. Register the drill in `docs/loop-drill-runbook.md` with its blame table row.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-arrival` passes and makes no network call.
- Each of the four readings is asserted, with overdue-and-arrived resolving to `arrived`.
- The asked-once gate is drilled across two runs.
- The broken seam fails the drill.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-arrival`
- The drill run with the network unavailable.

**Gate** — what must pass before approval:

- The broken seam demonstrated failing.

## Considerations

- Fixtures must not depend on the wall clock for the overdue case, or the drill rots on a fixed
  date; pass the dates in as the sibling drills do.
