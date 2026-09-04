---
created_at: 2026-09-04T14:24:05+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: [20260904142404-reproduce-and-classify-codex-loop-readiness-failures.md]
mission: prove-codex-loop-progress
merge_policy:
verification_handoff:
---

# Record each Codex tick outcome and next due time

## Overview

Give the Codex loop one durable status derived from completed ticks. An operator must be able to
tell the last tick's outcome and blocked reason from the time the supervisor plans to try again,
without reading an arbitrary transcript filename or inferring progress from a process listing.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — one current operational reading with named degradation

## Key Files

- `scripts/codex-loop.sh` — the only writer with the tick exit, report, and interval in hand.
- `.gitignore` — keep runtime status outside versioned knowledge if a new filename is introduced.
- `scripts/test-workflow-scripts.mjs` — verify atomic updates and time derivation.

## Implementation Steps

1. Define one machine-readable status document in the existing `.codex-loop` runtime directory;
   do not add a second log, branch, or repository artifact.
2. After every tick, atomically record tick id, start and finish, normalized outcome, blocked
   reason, report path, transport verdict, and the next due time derived from the interval.
3. Record interrupted, missing, and unreadable results explicitly; never retain the previous
   tick's green verdict under a new timestamp.
4. Demonstrate consecutive ticks replacing the current status while preserving their immutable
   transcripts for detailed diagnosis.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- One status read answers last outcome, blocked reason, report location, and next due time.
- A partial write or unreadable result cannot masquerade as the previous successful tick.

**Verification method** — the commands/tests/probes that prove them:

- Run hermetic multi-tick, interruption, and malformed-report cases plus the full script suite.

**Gate** — what must pass before approval:

- The status has one writer and remains git-ignored runtime state.

## Considerations

The status is local operational memory, not immutable project knowledge. It must survive ordinary
ticks without ever being swept into commits or used as a second source for workflow cadence.

## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: An atomic current-status document can point to immutable per-tick reports and
  transcripts without becoming a second cadence source.
  **Context**: The next due time is informational; the tick log remains authoritative for loops.
