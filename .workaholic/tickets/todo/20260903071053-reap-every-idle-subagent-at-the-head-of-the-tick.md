---
created_at: 2026-09-03T07:10:53+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-a-finished-subagent-and-take-the-loop-s-clock-off-it
merge_policy:
verification_handoff: 
---

# Reap every idle subagent at the head of the tick

## Overview

With the clock off the agent, a finished run has no remaining job and is stopped at the
earliest moment the tick can act — the head of the next tick, unconditionally, whatever any
cadence reads. An idle agent is not a corpse: it is a resumable session holding its whole
transcript, and a send resumes it inside that context. Measured twice in one session. Stopping
it is the only act that actually returns the context window.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a run says what it did and what it could not read

## Key Files

- `plugins/workaholic/commands/infinite-development.md` — §2's reap paragraph; the reap moves
  from "before the spawn, for the due loop" to "at the head, for every idle agent"
- `plugins/workaholic/skills/loops/SKILL.md` — states the listing is the whole record
- `plugins/workaholic/commands/moderate.md` — unaffected; named so the driver confirms it

## Implementation Steps

1. At the head of §2, after `ListAgents` and after the finish line of the previous ticket is
   written, `TaskStop` **every** `idle` agent — not only the loop that is due, and not only the
   three named loops.
2. Order it explicitly: record the finish, then stop. A stop before the record loses the
   cadence source for that run.
3. Delete the reap-at-spawn justification and the `propose-3` naming-collision note from the
   command body, and carry the measurement into `workaholic:loops` where the history lives —
   the record is kept, the operative instruction stops carrying it.
4. State what is discarded: nothing. The run is over and its result arrived as a task
   notification, which is the same argument the current text already makes.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every `idle` agent is stopped at the head of the tick, whatever its cadence reads.
- The finish is recorded before the stop, in that order.
- The listing after the head of a tick contains no `idle` agent.

**Verification method** — the commands/tests/probes that prove them:

- Read `commands/infinite-development.md`: the reap is unconditional and precedes every spawn.
- `node scripts/test-workflow-scripts.mjs` passes.

**Gate** — what must pass before approval:

- No sentence anywhere still says an idle agent is the loop's clock.

## Considerations

A subagent this tick did not spawn — one a person started in the same session — is also
`idle` in the listing. Reaping it is the honest reading of *stop what has finished*, but it is
the tick acting on something outside the loop, so the command names the bound it applies
rather than leaving it to the run's judgement.

## Final Report

**Outcome**: implemented.

Every `idle` subagent is stopped at the **head** of the tick — before the cadence is read, before
anything is spawned, and **whatever any cadence says**. The listing the concurrency rule reads then
carries **running runs only**.

**The reason is in the command, because it is the part a reader will not guess**: an idle agent is
**not a corpse**. It is a resumable session holding its whole transcript, and a send resumes it
inside that context — measured twice in one session. Stopping it is the only act that actually
returns the context window, which is the operator's stated intent.

**"Unconditionally" is the load-bearing word.** The previous rule reaped *before the spawn*, which
meant a loop that was not due kept its finished agent for a whole cadence — precisely the case the
intent excludes. Removing the condition is the change; the `TaskStop` call is not new.

**It depends on the sibling ticket and would be wrong without it**: with the clock still on the
agent, reaping at the head would destroy the cadence. The order of the two in this mission is not
arbitrary.

**Verified**: `node scripts/test-workflow-scripts.mjs`.
