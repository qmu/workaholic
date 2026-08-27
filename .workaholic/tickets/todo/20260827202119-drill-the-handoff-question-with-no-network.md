---
created_at: 2026-08-27T20:21:19+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: ask-for-the-one-act-a-declared-handoff-is-waiting-on
merge_policy:
verification_handoff: 
---

# Drill the handoff question with no network

## Overview

PROPOSED. `scripts/e2e/loop-drill.sh` is how every reading in this loop is provable on demand
rather than by waiting for a tick. Add `verify-handoff-question`: over local fixtures with the
transport stubbed, it proves a declared handoff is asked about once, that a second tick asks
nothing, that `stalled-units` is silent on the same unit, and that nothing was cleared — plus
one row that deliberately breaks the seam, so the drill can be seen to fail.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — a drill with no failing row proves only that it ran

## Key Files

- `scripts/e2e/loop-drill.sh` — the `case` dispatch (~3267) and the `USAGE` string (~3240),
  both of which must carry the new verb.
- `scripts/e2e/loop-drill.sh` — `cmd_verify_retire` (~2594) and `cmd_verify_delivery_retry`
  (~3078): the closest precedents, each with a local bare origin, a `PATH` stub for the
  transport, and their own deliberately broken row.
- `plugins/workaholic/skills/moderate/scripts/step-handoff-units.sh` — under drill.
- `plugins/workaholic/skills/moderate/scripts/step-stalled-units.sh` — asserted silent.
- `docs/loop-drill-runbook.md` — the operator procedure and the failure-reason→file blame
  table; a new verb is listed there or it is undiscoverable.

## Implementation Steps

1. Build the fixture: a bare local origin, a claim branch whose remaining queued ticket
   declares `verification_handoff:` with a recognisable reason string, a branch story at the
   tip so the unit reads *reported*, and a lapsed heartbeat. Stub the transport on `PATH`; make
   **no** network call.
2. Assert the oracle first — `list-claims.sh` reads `awaiting_verification` — so a drill
   failure downstream is attributable to the step rather than to a mis-built fixture.
3. Drive the step and assert one `needs_agent` entry keyed `handoff-unit:<unit>`, addressed to
   the claim holder, carrying the declared reason **verbatim** (assert the string, not a
   substring of the ticket title).
4. Run a second tick over the same fixture and assert it asks nothing — the ledger's
   asked-once gate, spent through `ask-question.sh`.
5. Assert `step-stalled-units.sh` produces no question for the same unit in the same tick, and
   that it counts it in its summary.
6. Assert nothing was cleared: the claim still stands, the branch is untouched, the pull
   request is not merged or closed, and the tree carries no write but the tick log.
7. Add one row that **deliberately breaks the seam** — e.g. a fixture whose declared reason is
   removed from the queued work, where the verdict must fall back and the question must not be
   asked — and label it as the intentional failure, as `verify-retire` does.
8. Register the verb in the dispatch, in `USAGE`, in `CLAUDE.md`'s drill list, and in
   `docs/loop-drill-runbook.md`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-handoff-question` passes with no network access
- It proves: asked once, second tick silent, `stalled-units` silent, nothing cleared
- It contains one labelled intentional-failure row and that row is observed to fail
- The verb appears in the dispatch, `USAGE`, `CLAUDE.md` and the runbook

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-handoff-question --json`
- Run it with networking unavailable and confirm the result is unchanged

**Gate** — what must pass before approval:

- The drill passes offline, and the intentional-failure row demonstrably fails

## Considerations

- The fixture must reach `awaiting_verification` through the real derivation — reported, work
  still queued, declaration on the **queued** work — not by forcing the verdict. A drill over a
  forced verdict proves the renderer and nothing about the oracle.
- The drill is operator tooling outside the plugin and may assume the server's full `gh` and
  `qfs`; it must still make no network call, exactly as its two neighbours do.
