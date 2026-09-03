---
created_at: 2026-09-03T07:10:53+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-a-finished-subagent-and-take-the-loop-s-clock-off-it
merge_policy:
verification_handoff: 
---

# Report the cadence's source and every reaping

## Overview

Three rules move in this mission and all three are invisible from the outside: whether a loop
was skipped, why, and what the tick stopped. The tick's own report is the only surface, and the
loop's standing rule is that a degraded read is named rather than rendered as a healthy one.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a run says what it did and what it could not read

## Key Files

- `plugins/workaholic/commands/infinite-development.md` — §3 is the report's ceiling
- `plugins/workaholic/skills/loops/SKILL.md` — the contract the report answers to

## Implementation Steps

1. Per loop, report `spawned` / `still_running` / `not_due`, and for `not_due` name the age
   **and its source**: the recorded finish, or `no_finish_recorded` when the line was absent.
2. Report `reaped: <name>` per idle agent stopped, with the finish that was recorded for it.
3. An unreadable log is `cadence_unreadable: <reason>` and every loop reads as due — reported,
   never rendered as `not_due`.
4. Keep §3's own rule: a tick that swept nothing, reaped nothing and spawned nothing says
   exactly that, in one line. This adds words only to a tick that did something.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every `not_due` names the age and where the age came from.
- Every reaping is reported by name.
- An unreadable cadence source is named as unreadable and never as `not_due`.
- An idle tick's report does not grow.

**Verification method** — the commands/tests/probes that prove them:

- Read `commands/infinite-development.md` §3 against the four conditions above.
- `node scripts/test-workflow-scripts.mjs` passes.

**Gate** — what must pass before approval:

- No report line names an identifier the reader cannot act on, and none grows the idle tick.

## Considerations

This is the mission's smallest ticket and it is the one that makes the other four checkable
from outside the session; it is last because it reports what they establish.
