---
name: work
description: Run the development loop — one tick every few minutes that answers the inbound channel and drives the queued work. Use when a session is asked to start, run, or perform one tick of the loop, on any agent.
---

# Work — the development loop

**One session, one loop.** A tick answers the inbound channel and moves the queued work, then
ends; the clock starts the next one. If this session is already looping, say so and start
nothing — a second loop would drive the same claim protocol twice.

## Starting it: the clock is the agent's, the tick is this skill's

The tick below is the same on every agent. **Only the clock differs**, and it differs because
it is a harness feature rather than anything this repository can ship:

| Agent | The clock |
| ----- | --------- |
| **Claude Code** | the harness's own `loop` skill — `/loop 5m /infinite-development`, which `/work` invokes for you |
| **Codex in the ChatGPT desktop app** | a Scheduled task **inside the current chat**, at the requested minute interval, running in the local project |
| **Codex CLI, IDE, and any agent with no Scheduled management surface** | an external one: run the `scripts/codex-loop.sh` beside this skill (or a cron entry / systemd timer running it `--once`) |

**Scheduled tasks are an app surface, not a Codex CLI subcommand.** The ChatGPT desktop app can
return to an existing chat on a minute interval, use its existing context, and run against the
local project. Create the schedule in this chat, select the local project rather than a fresh
worktree (the tick owns its own claim/publish worktrees and its local cadence log must survive),
and give it this durable instruction:

> Run the `workaholic:work` skill. This scheduled invocation is the clock: execute exactly one
> development-loop tick in the current local project, apply the non-Claude substitutions below,
> return the tick's report block to this chat, and end. Do not start `scripts/codex-loop.sh`, do
> not create another schedule, and do not wait for the next tick.

The computer and desktop app must remain running for a scheduled task that needs local files.
Use the requested cadence; when none was requested, retain `/work`'s five-minute default.

### Relaying a nested Codex worker through this chat

A chat that owns the Slack connector may delegate repository work to one nested `codex exec`
without delegating its connector. It invokes the installed launcher once with `--relay --once`,
waits for the returned envelope, validates it with `scripts/relay-contract.sh envelope <path>`,
then performs the ordered Slack intents itself under `workaholic:notify`. It writes one
acknowledgement per stable intent key and passes that file back with `--ack <path>`. The parent
resolves threads with the existing exact, private-inclusive lookup, uses supplied coordinates
directly, and reads before replaying a write. It never broadens the allowed shapes and never sends
OAuth material to the worker.

This handshake requires the owning chat to remain present until acknowledgement. A free-running
CLI supervisor has no parent and must report `relay_pending`/`parent_absent`; emitted intent is
never delivery. The closed envelope, acknowledgement outcomes, retry rule, and rejection cases are
defined in [reference/codex-slack-relay.md](reference/codex-slack-relay.md).

**The CLI itself still has no Scheduled management interface.** That boundary was measured
2026-09-03 against `codex-cli 0.149.1` and is also the current documented product boundary.
For a CLI-only environment, this skill's own `scripts/codex-loop.sh` supplies the clock: one `codex exec` per
interval, sequential, `flock`ed against a second supervisor, exporting `.claude/settings.json`'s
`env` block so both agents read one declaration.

The launcher is part of the full Workaholic plugin. From an installed skill, run
`sh <directory-containing-this-SKILL.md>/scripts/codex-loop.sh`; the repository-local
`sh scripts/codex-loop.sh` remains a compatibility shim. Startup names a missing clock wrapper,
work skill, tick command body, repository, or Codex CLI separately, and recommends a plugin
update only for a missing plugin-owned layer.

The supervisor completes and classifies the first tick before reporting ready. Every completion
atomically replaces `.codex-loop/status.json` with the outcome, blocked reason, report path,
transport verdict and next due time; `sh scripts/codex-loop.sh --status` reads that state without
starting another process. A failed first tick, missing report or absent report transport refuses
startup by name. Later failures update status and the sequential supervisor proceeds to its next
due time.

## The tick

**On Claude Code**, run `plugins/workaholic/commands/infinite-development.md` — that command is
the ceiling for what a tick may post, and it carries the Slack shapes byte-identical.

**On every other agent**, execute the same command body as a **file**: read
`plugins/workaholic/commands/infinite-development.md` and do what it says, with the
substitutions below. `commands/` is not a command surface off Claude Code — both
`.codex-plugin/plugin.json` manifests expose `"skills"` and nothing else — so the file is read
rather than dispatched. That is why this skill exists: a skill is published where a command is not
(`.codex-plugin/plugin.json` declares `"skills": "./skills/"` over the whole plugin), so the
loop reaches every agent through the plugin the marketplace already installs.

| What the command body says | Off Claude Code |
| -------------------------- | --------------- |
| `/loop 5m` keeps calling this | the Scheduled task or external clock does; **execute one tick and end** |
| `/implement`, `/propose`, `/specificate`, `/moderate` | read `plugins/workaholic/commands/<name>.md` and execute it |
| spawn the runs as **background** subagents and do not wait | dispatch each due one with `sh <this skill>/scripts/codex-loop.sh --dispatch <implement\|propose\|moderate>`, which starts a **detached** worker and returns at once. Never run the work inline, and never wait for a worker |
| `ListAgents` answers *is this loop still running*; `TaskStop` reaps the idle ones | `--dispatch` answers it by **refusing**: a role already running reports `already_running` and is not started twice. `--status` names each role's state. Nothing is reaped — a worker is a process that ends, not a session holding a transcript |
| a `${CLAUDE_PLUGIN_ROOT}`-rooted script path | the plugin directory: already rewritten to a relative path in this skill's published copy, and `plugins/workaholic` in this repository's own tree. Write the path out in full when composing a call |

Everything else in that body is unchanged, including the cadences, which are read from the tick
log and never depended on an agent listing:

```
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/tick-id.sh
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/log-read.sh --step-prefix loop-finish-<name> --latest-tick
```

(In the **published** copy of this skill that token is already rewritten to a real relative
path by the build, so an agent reading it there runs the line as written. In this repository's
own tree it is `plugins/workaholic`.)

Derive the tick id **once** at the top and use that one value. `latest_tick` is a
`YYYYMMDD-HHMMSS` UTC stamp and **is** the finish time: a loop is due when
`now - latest_tick >= its cadence`. An **empty** `latest_tick` means *no such tick* and is due —
never *just now*; `read: false` is a log this tick could not read and is **also** due, because
over-firing beats a loop that silently stopped. Record each finish with `log-append.sh` under
the same tick id, including for a run that failed — the cadence measures *when we last tried*.

## The coordinator owns the clock, and the work never holds it

**The channel turn happens on the interval, whatever the work is doing** — the property the
Claude tick has, and the one the inline form did not (2026-09-05, issues #984 and #985). Three
terms, and each is load-bearing:

1. **The cadence is measured from startup**, not from the previous tick's finish. Sleeping a
   whole interval after a completed tick makes the real period *tick duration + interval*:
   measured, a tick still running six minutes into a five-minute loop pushed the next channel
   turn past the eleventh minute. A boundary is the first `startup + k×interval` strictly after
   now, so a slow tick **costs the boundaries it overran** and never shifts the phase. Every lost
   boundary is named on stderr rather than silently absorbed.
2. **The work is dispatched, never awaited.** `--dispatch <role>` starts a detached worker and
   returns; the coordinator's tick is the channel turn, the dispatch and the report, so its
   duration is a function of the channel and nothing else.
3. **A role already running is refused by name.** `--dispatch` answers `already_running` and
   starts nothing — the same guarantee `ListAgents` gives the Claude tick, made by a lock rather
   than by a listing, so it holds across `codex exec` runs that cannot see each other's agents.

**This is not the retired three-loop premise, and the difference is the point.** What this
repository retired on 2026-09-03 was three *clocks*, three *views* and three places to look, none
of which could see the whole loop. Here there is **one** coordinator, **one** clock and **one**
tick log: the workers hold no clock, decide no cadence and report their finishes into the log the
coordinator reads. That is the Claude Code shape, reached with processes instead of subagents.

Two further limits off Claude Code: **an absent channel transport is reported by name**
(`no_slack_transport`) and never worked around, and the **tool-level hooks do not fire** — the
script-level gates still hold, and `sh plugins/workaholic/hooks/install-git-hooks.sh` is the
repair for the rest.

A connector-less worker with an explicitly waiting parent emits relay intents; a worker with no
such parent reports `no_slack_transport`. Do not infer a parent from a shell process. Only
`--relay` plus a matching parent acknowledgement proves the return path, and no acknowledgement
means `relay_pending`, never `notified`.

The measurements, the full mechanism-by-mechanism comparison and the rejected alternatives:
[reference/other-agents.md](reference/other-agents.md).
