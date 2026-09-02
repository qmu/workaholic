---
created_at: 2026-09-03T07:10:53+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-a-finished-subagent-and-take-the-loop-s-clock-off-it
merge_policy:
verification_handoff: 
---

# Record each loop run's finish on the tick log

## Overview

The loop's cadence is read off a live idle agent's `started` age, which is why a finished run
is kept alive. Nothing anywhere records when a run *finished*. Give the cadence a source that is
not an agent: one line on the tick log, written by the tick that first observes the run idle —
the same tick that is about to stop it, so no second walk and no new store.

Measured on the fifteen-minute `propose` cadence: respawns at ages of 21, 31 and 45 minutes,
because `started` measures the previous run's start plus its whole duration.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a run says what it did and what it could not read

## Key Files

- `plugins/workaholic/commands/infinite-development.md` — §2 is the ceiling; the tick reads
  `ListAgents` here and already reads the tick log for `moderate`'s gate
- `plugins/workaholic/skills/moderate/scripts/log-append.sh` — the one writer of the log,
  idempotent per `(tick, step)`; the line is written through it and through nothing else
- `plugins/workaholic/skills/loops/SKILL.md` — the loop's premise and subagent contract
- `plugins/workaholic/skills/moderate/SKILL.md` — states what the log is and who may write it

## Implementation Steps

1. Read what `ListAgents` reports for an `idle` agent. If a completion timestamp is on the
   listing, that is the finish; if only `started` and an age are, the finish is the **observing
   tick's own id**. Record which the implementation used — the whole ticket rests on it.
2. At the head of §2, for each `idle` agent, call `log-append.sh --step loop-finish-<name>`
   with the finish as the summary, before anything is spawned. Reuse the tick id the run
   already has; add no second writer and no new area.
3. State in `moderate/SKILL.md` that `/infinite-development` writes `loop-finish-<name>` lines,
   so the log's writer list stays true — the log has one writer script and now a second caller.
4. Name the accuracy in the command body: the recorded finish is the first tick that observed
   the run idle, so it is exact to one tick where `started` was wrong by the run's duration.
5. Leave `log-append.sh` byte-identical. It already takes an arbitrary `--step` slug.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A tick that observes an `idle` agent writes exactly one `loop-finish-<name>` line for it.
- A tick that observes the same idle agent twice writes one line, not two (the writer's own
  idempotence per `(tick, step)`).
- No new file, area, cursor or store is introduced.

**Verification method** — the commands/tests/probes that prove them:

- `bash plugins/workaholic/skills/moderate/scripts/log-read.sh --step-prefix loop-finish-`
  lists the recorded finishes.
- `node scripts/test-workflow-scripts.mjs` passes.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`.

**Gate** — what must pass before approval:

- `log-append.sh` unchanged.
- The command body names the accuracy limit rather than implying the finish is exact.

## Considerations

The log is git-ignored and stays in the checkout that wrote it, which is the checkout the next
tick reads (`CLAUDE.md`, `.workaholic/` runtime conventions). A tick running where that state
cannot survive loses the cadence source and every loop reads as due — the same degradation
`moderate`'s own gate already accepts, and the honest one: over-spawning beats a loop that
silently stops.
