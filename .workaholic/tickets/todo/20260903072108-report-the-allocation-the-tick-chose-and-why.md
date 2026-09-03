---
created_at: 2026-09-03T07:21:08+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: decide-each-tick-s-allocation-from-what-the-tick-just-read
merge_policy:
verification_handoff: 
---

# Report the allocation the tick chose and why

## Overview

A tick may decide to do nothing but watch — every runner busy and nothing captured. The tick
can already do this; what is missing is that it be a decision the tick is making rather than the
residue of three gates all answering no. With the allocation now variable, the report is the only
place a person can see what the tick decided and whether it was right.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a run says what it did and what it could not read

## Key Files

- `plugins/workaholic/commands/infinite-development.md` — §3, the report's ceiling
- `plugins/workaholic/skills/loops/SKILL.md` — the contract the report answers to

## Implementation Steps

1. Report the allocation as one decision: how many `implement` runners were spawned, out of
   how many claimable units, against what bound.
2. Report the deferral by name when the strategy half was skipped, with the refusal it read and
   how many cadences it has been deferred.
3. Report a watch tick as a **decision** — `watching`, with the reason (every runner busy,
   nothing captured) — never as silence.
4. Name every reading that could not be made: `fanout_unreadable`, `bad_fanout`,
   `cadence_unreadable`, and a degraded survey by the survey's own word.
5. Hold the sibling rule from the cost mission: a tick that swept, reaped and spawned nothing
   still reports one line. An allocation of zero is one line, not five.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every tick names the allocation it chose and what it chose it from.
- A watch tick reads as a decision, not as silence.
- Every unreadable input is named by its own word.
- A tick that did nothing still reports one line.

**Verification method** — the commands/tests/probes that prove them:

- Read `commands/infinite-development.md` §3 against the four conditions.
- Run one tick with a fan-out and one watching: both report their decision.
- `node scripts/test-workflow-scripts.mjs` passes.

**Gate** — what must pass before approval:

- No allocation is taken without being reported, and no degraded reading renders as a healthy
  one.

## Considerations

This is last because it reports what the other five establish, and it is the ticket that makes
the fan-out arguable from outside the session — the same reason the sibling mission's reporting
ticket exists.
