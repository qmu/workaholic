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
| **Codex CLI, and any agent with no interval feature** | an external one: `sh scripts/codex-loop.sh` (or a cron entry / systemd timer running it `--once`) |

**Codex has no interval, loop, schedule or cron feature**, measured 2026-09-03 against
`codex-cli 0.149.1`: no subcommand across `codex {,exec,agents,features,queue,debug} --help`
and no feature flag in `codex features list`. The nearest, `goals`, is goal *continuation*
inside one thread — it keeps a run working toward an aim across turns and never starts a run.
So the clock is supplied from outside, and `scripts/codex-loop.sh` is that clock: one
`codex exec` per interval, sequential, `flock`ed against a second supervisor, exporting
`.claude/settings.json`'s `env` block so both agents read one declaration.

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
| `/loop 5m` keeps calling this | the external clock does; **execute one tick and end** |
| `/implement`, `/propose`, `/specificate`, `/moderate` | read `plugins/workaholic/commands/<name>.md` and execute it |
| spawn the runs as **background** subagents and do not wait | run them **inline, in sequence** — `implement` first, because it moves the queue every other reading is a function of |
| `ListAgents` answers *is this loop still running*; `TaskStop` reaps the idle ones | **nothing**. Sequential ticks cannot overlap, and there is no agent to stop |
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

## What the sequential form costs, stated rather than discovered

Under Claude Code a person's message is answered within five minutes **whatever the work is
doing**, because the work is detached. Run inline, the answer comes at the **top** of each tick
(the channel turn is the tick's first act), so the worst case is one tick's own work duration.
Do not buy the responsiveness back by skipping work, and **do not split it into two concurrent
loops** — that is the three-process premise this repository retired on 2026-09-03 after
measuring it: each loop was correct in isolation and none could see the whole loop.

Two further limits off Claude Code: **an absent channel transport is reported by name**
(`no_slack_transport`) and never worked around, and the **tool-level hooks do not fire** — the
script-level gates still hold, and `sh plugins/workaholic/hooks/install-git-hooks.sh` is the
repair for the rest.

The measurements, the full mechanism-by-mechanism comparison and the rejected alternatives:
[reference/other-agents.md](reference/other-agents.md).
