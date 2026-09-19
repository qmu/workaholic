---
created_at: 2026-09-19T11:55:11+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-the-codex-clock-dying-silently-and-writing-the-locks-it-reads
merge_policy:
verification_handoff: 
---

# Announce a Codex clock that stopped or executed nothing

## Overview

`executed: false` with a reason is an honest refusal by the worker, and it reaches nobody. The
supervisor's whole escalation reach is `write_supervisor stopped <reason>` plus a line on stderr,
and nothing outside `skills/work/` reads the status surface at all — no `/moderate` step, no
command, no routine. That is how a loop stayed `blocked / interrupted` for twelve days with a
person looking at the repository the whole time.

The repository already has the answer for a stop nobody can see: `workaholic:notify`'s
precondition-stop shape, posted under the tick's own signature with its dedup, escalation and
cool-down (2026-09-08). It is written as an obligation on the coordinator **inside** a tick, which
is exactly the layer that cannot run when the tick body is unreadable or the supervisor has
already exited. This ticket gives the same shape a caller one layer down. No new shape, no new
transport, no second liveness authority.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a stop that reaches no reader is a silent stop

## Key Files

- `plugins/workaholic/skills/work/scripts/codex-loop.sh` — `write_supervisor()`, the
  `ensure_plugin_tree` refusal, the readiness refusal, the interrupt trap, and `run_tick`'s
  `tick_not_executed` / `BLOCKED_REASON` arm with the role records' `consecutive_failures`.
- `plugins/workaholic/skills/notify/SKILL.md` — the precondition-stop shape, its signature, dedup,
  escalation and cool-down; this ticket reuses the wording and adds none.
- `plugins/workaholic/commands/infinite-development.md` — states the same obligation at the
  coordinator level; the two must not drift into two wordings.
- `plugins/workaholic/skills/transport/scripts/perform.sh` and
  `plugins/workaholic/skills/specificate/scripts/notify-slack.sh` — the script-level seams a POSIX
  supervisor can reach, with `WORKAHOLIC_ROLE` set at its own entry.

## Implementation Steps

1. Reproduce both silences: a supervisor stopped by an unrecoverable tree, and a supervisor whose
   ticks return `executed: false` three times running. Record what a person could have seen in
   each case — currently the state directory and stderr, and nothing else.
2. Name the two trigger conditions precisely and derive them from state that already exists: a
   `stopped` record whose reason is not an ordinary end (`completed_once`), and a tick outcome of
   `tick_not_executed` repeated to the existing consecutive-failure threshold. Add no new field
   and no new counter.
3. Post the precondition-stop shape through the transport seam, under the supervisor's own
   signature, reusing `workaholic:notify`'s dedup key, escalation and cool-down unchanged so a
   wall the loop keeps hitting is one alert, not one per tick.
4. Treat an undeliverable transport as a recorded refusal, never as a post: the outbox keeps the
   pending notification and the supervisor reports the refusal word. Slack is undeliverable in
   this repository today (`operations_unsatisfied` when the declared operations are required,
   `ambiguous_identity` when narrowed, no `SLACK_BOT_TOKEN`), so the verification is the outbox
   and the refusal word rather than a message anybody reads.
5. Set `WORKAHOLIC_ROLE` at the supervisor's own entry, as every other unattended path does, and
   read `branching/scripts/lib/base-ref-gate.sh` at nothing — this path writes no commit and no
   ref, and must not acquire one.
6. Prove it offline in `scripts/e2e/drills/verify-codex-clock.sh`: a stub transport, both trigger
   conditions, one alert per condition across repeated ticks, and a breaker that removes the
   announcement and requires the drill to notice.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A supervisor that stops for a reason other than an ordinary end emits exactly one
  precondition-stop announcement, with its reason word in the body.
- A clock ticking without executing emits one announcement at the existing threshold and does not
  repeat it every tick.
- An undeliverable transport leaves a retained outbox entry and a named refusal, and never reads
  as posted.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-codex-clock` with the new rows and their breakers.
- `node scripts/test-workflow-scripts.mjs`, including the pinned wording shared with
  `commands/infinite-development.md`.

**Gate** — what must pass before approval:

- The announcement wording is byte-identical to the shape `workaholic:notify` already publishes,
  pinned by the suite.

## Considerations

- This ticket is ordered after the other two. Before them, an hourly reader of the status surface
  would keep four lock files permanently fresh and a stop would have no record to announce — the
  measured failure, amplified rather than cured.
- Do not add a `/moderate` step that polls the state directory as well; one announcement of one
  fact is the rule this repository retires roots for.
