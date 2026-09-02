---
created_at: 2026-09-02T04:31:17+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-a-routine-tick-from-parking-on-a-permission-prompt
merge_policy:
verification_handoff: 
---

# Make a parked routine tick visible as parked

## Overview

PROPOSED. "Every tick it fires it silently produces nothing while reading as scheduled and
healthy" is the half of the failure that let it run for hours. `/moderate` has a repair for
this — `blocked-tick`, which reads for an opening with no closing in the tick log — and
`[Propose]` has none: it writes no log, so a parked propose tick leaves no trace anywhere.

This ticket gives the same visibility to the routine that originates the loop's work, so a
recurrence is named within an hour rather than noticed by a person days later.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — a silent failure is the failure that lasts

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-blocked-tick.sh` — the existing repair
  for `[Moderate]`; the shape to follow and, where possible, the machinery to reuse.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — where the opening persist happens,
  the half that makes a stop legible at all.
- `plugins/workaholic/skills/moderate/scripts/persist-log.sh`,
  `plugins/workaholic/skills/moderate/scripts/log-append.sh` — the log writers; whether the
  propose tick gets a trace here is this ticket's central decision.
- `plugins/workaholic/skills/propose/SKILL.md`, `reference/loop.md` — `/propose` is a pure
  reader whose only writes are GitHub issues; anything added must not break that.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — where a new or widened step's
  spec lives.
- `CLAUDE.md` — the `/propose` and `/moderate` contracts this touches.

## Implementation Steps

1. Reproduce the invisibility: a propose tick that dies before its report leaves what, on
   the base and in the channel? Establish that it leaves nothing before designing a trace.
2. Decide where the trace lives, and record the decision with its cost. `/propose` is
   contracted as a pure reader of this repository whose only writes are GitHub issues, so
   giving it a tick log would widen that contract — say so, weigh it against reading the
   routine's own record from outside, and choose deliberately rather than by convenience.
3. Implement the chosen reading so `blocked-tick`, or a sibling step written to the same
   shape, can answer *the propose tick opened and never closed* for the tick before last —
   the same structural bound `blocked-tick` already uses, rather than a tuned threshold.
4. Say what is known and no more. The reason a tick parked is not on the base by
   construction, so the question names the tick and what it reached, and never guesses a
   cause. This is the rule `blocked-tick` already holds.
5. Drill it offline, as `verify-blocked-tick` drills the existing step: a seeded opening
   with no closing produces the finding; a healthy pair produces none.
6. Update `workaholic:propose`, `workaholic:moderate` and `CLAUDE.md` wherever the contract
   moved.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A propose tick that opened and never closed is named within the following two ticks.
- The finding says what is known and guesses no cause.
- Any widening of `/propose`'s pure-reader contract is stated where that contract is stated.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`, including the new drill

**Gate** — what must pass before approval:

- The new drill fails when the detection is removed and passes with it.
- The drill is hermetic: no network, no credential.

## Considerations

- This is a backstop, not the repair. If the source fix lands and holds, this step should
  find nothing forever — which is the point, and is why it must be drilled rather than
  trusted.
- Widening `/propose` to write a log is a real cost and the reason the decision is a step
  rather than an assumption. An outside reading that needs no write may be the better trade.
