---
name: work
description: Run the development loop — observe Slack and feedback issues, answer people, and dispatch due work without waiting for it.
---

# Work

Run one coordinator with two independent clocks:

- the work clock, anchored at startup, advances implement, propose/specificate, and moderate;
- the observation clock watches Slack and assigned feedback issues. Activity shortens it and
  silence gradually lengthens it.

The coordinator owns communication and never performs or waits for the dispatched work.
The live conversation is the highest-priority input: a request to wait suspends dispatch.

## Start

Use the strongest mechanism this session actually has:

1. If it can wait interruptibly, emit commentary, and start background children, keep this
   turn as the native parent.
2. Otherwise, if a same-chat scheduler is callable, schedule this tick in the local project.
3. Otherwise run `scripts/codex-loop.sh`; use `--once` for cron or systemd.

If Codex cannot sustain the native parent in step 1, prefer a Scheduled task attached to the current chat. Do not start `scripts/codex-loop.sh`
from that task because it would create a second clock. Codex CLI uses
`scripts/codex-loop.sh` as its fallback.

For native parents and same-chat schedulers, read `runtime/reference/native-loop.md` and call
`runtime/scripts/coordinator.sh --instance <session-id> --input <event.json>` with a `start`
event before creating the clock. On Claude Code this must be the actual native session ID;
every child prompt includes `workaholic-receipt:<id>` for the launch guard. Reuse the instance ID after compaction. The same entrypoint
handles `hold`, `resume`, `stop`, reservations and terminal results. Persist hold before saying
you will wait. Timer events cannot resume. On stop cancel the schedule and stop named children.
Record each confirmed native cancellation with `cancelled`; it is not a role completion.

State the selected clock, where reports appear, and any missing continuation mechanism. An
explicit interval selects fixed observation. Without one, use adaptive observation:

- activity: 30 seconds;
- successive quiet observations: 60, 120, 240, 480, then 900 seconds;
- cold quiet start: 300 seconds;
- provider failure: retry separately and never count it as quiet.

Do not add quiet hours. Silence naturally backs off at night, and activity at any hour resets
the interval. A scheduler with one-minute precision clamps 30 seconds to 60 and says so.

For an external Codex clock:

```sh
sh <this-skill>/scripts/codex-loop.sh
sh <this-skill>/scripts/codex-loop.sh --once
sh <this-skill>/scripts/codex-loop.sh --status --json
```

## Tick

Read `plugins/workaholic/commands/infinite-development.md` and execute one tick. On an agent
without command dispatch, translate command names as follows:

- read `plugins/workaholic/commands/<name>.md` for implement, propose, specificate, or moderate;
- start due native children in the background, or call
  `scripts/codex-loop.sh --dispatch <implement|propose|moderate>`;
- never run those roles inline and never wait for them;
- use the plugin directory in place of `${CLAUDE_PLUGIN_ROOT}`.

Observe both inputs before deciding the next observation:

- Slack through `transport/scripts/observe-channel.sh`, capturing messages before advancing its cursor;
- `specificate/scripts/list-inbound-issues.sh`, which returns open feedback issues assigned
  to this identity and excludes already captured or self-originated issues.

Report the route each Slack effect actually took. Startup names the declared binding it
resolved, whether the channel and sender were verified, and any `binding_contradictory` /
`binding_incomplete` reading. Name the destination: the
workspace and channel it resolved, and `channel_id` when the declaration carries one, taken
from the reader's own `binding` and never from memory, a directory name or a repository name —
a report that names no destination is **non-conformant on its face**, and an undeclared
repository names the environment fallback it used instead.
Each effect names its `route` and, when it left the preferred one,
`degraded_from` and the typed `degradation_reason`. A connector or token success is a **degraded
success** — it proves delivery and never that the preferred route is configured — and reporting
it as an ordinary one is how a repository runs for weeks on a route nobody chose.

An observation is quiet only when every configured source was read successfully. Any new
human Slack root or reply, or any new assigned feedback issue, is activity. Bot-authored
messages do not reset the interval. A new feedback issue makes propose-then-specificate due
immediately. Work, exploration, maintenance, and provider retry deadlines stay independent.

Use `runtime/scripts/plan-poll.sh` for the pure cadence transition. Persist its
`next_state` only after inbox capture; after a crash, an early duplicate read is safer than
advancing past uncaptured input. Sleep until the earliest work, observation, or retry
deadline. Native waits remain interruptible and at most 60 seconds.

**An answer recorded in a `/moderate` question's own thread needs no dispatch of its own**
(2026-09-08, mission `turn-quiescent-blockers-into-mature-decisions-and-resume-work`). It is
recorded by `moderate/scripts/record-answer.sh` inside the tick that read the thread, and the
direction it unblocks is re-judged on the **next ordinary `[Propose]` turn**, which reads it
through `moderate/scripts/decision-maturity.sh` before it may report `no_evolutionary_move`. So
there is no reopen signal to route, no new due-role, no cursor to advance and no state to clear:
the answer is derived state, and the cadence that already exists is what picks it up. An answer
that also **asks for something** is a different fact and takes the path it always took — one
`[FB]` issue through `propose/scripts/file-inbound-ask.sh`, which makes propose-then-specificate
due immediately by the rule above.

## Children and reports

Reserve a receipt through `coordinator.sh` before launching, then record `child_id` with `started`.
Keep one child for propose/moderate and at most the configured implement fanout. Record each
terminal result with `finish`, emit commentary once, then mark `reported`. After compaction,
rediscover children. Idle without a readable result is `unknown`, never completed. Native
cadence is derived from receipts, not remembered timestamps.
For native children, also apply the tick's total `WORKAHOLIC_MAX_WORKERS` limit (default 2)
across roles and reserve each launched slot immediately. Capacity-held roles remain due.

Every worker returns the supplied result schema:

- `executed`: whether it actually read and performed its command;
- `outcome`: the command's terminal token;
- `reason`: what stopped or withheld it;
- `report`: the command's report block.

Process exit, execution, work completion, and notification delivery are separate facts.
Missing or malformed results are unreadable, never successful.

Under a native parent, ordinary ticks and user steering use commentary. A final response is
reserved for an explicit stop or a named inability to continue. A correction does not reset
the startup anchor. On stop, name still-running roles and child identifiers.

Connector-less nested Codex runs may use the documented relay only when a connector-owning
parent is explicitly waiting. Otherwise report `no_slack_transport`.

Historical measurements and compatibility detail live in
[reference/other-agents.md](reference/other-agents.md).
