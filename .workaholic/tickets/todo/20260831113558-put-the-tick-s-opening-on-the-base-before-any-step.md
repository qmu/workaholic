---
created_at: 2026-08-31T11:35:58+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-an-unattended-tick-from-waiting-on-a-person
merge_policy:
verification_handoff: 
---

# Put the tick's opening on the base before any step

## Overview

`persist-log.sh` is the tick's **closing** act, so a tick that dies mid-run leaves
nothing on the base at all: the record that would show it stopped is the record the stop
prevents. One early persist, immediately after the log is opened, makes a dead tick
visible without changing what the closing persist does.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/persist-log.sh` — the writer; already
  idempotent and already unions by `(tick, step)`, which is what makes a second call
  safe.
- `plugins/workaholic/skills/moderate/scripts/step-open-log.sh` — the tick's first step,
  where the opening exists.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — the step driver.


## Implementation Steps

1. Persist once immediately after the log is opened, carrying the tick's opening line and
   nothing else. The union by `(tick, step)` already guarantees the closing persist adds
   the rest without rewriting it, so this needs **no change to the writer's contract**.
2. Keep every prohibition: no `work-*` branch, no claim, no pull request, no merge, the
   caller's checkout byte-identical.
3. Report the early persist exactly as the closing one reports itself — a persist that
   missed the base is `degraded` by name, and never fails the tick.
4. Do **not** persist per step: twenty-nine commits an hour for a log is the noise the
   pull-request-per-tick design was refused for. Two persists bound the loss to whatever
   a dead tick had done since it opened, which is the fact that matters.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A tick that is killed after its first step leaves its opening section on the base.
- A tick that completes produces a base state byte-identical to today's.
- The early persist is idempotent and reports a miss as `degraded` by name.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-moderate`

**Gate** — what must pass before approval:

- No `work-*` branch, no claim, no pull request and no merge; the caller's checkout is
  byte-identical after both persists.


## Considerations

- Two commits an hour instead of one on an active repository. That is the price of the
  reading and it is small beside twenty-nine; state it rather than hiding it.
- A tick killed **before** its first step still leaves nothing. That case is genuinely
  outside this seam and should be said so rather than papered over.

