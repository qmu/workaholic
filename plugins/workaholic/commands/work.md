---
description: Start the development loop in this session — one tick at the requested interval (default five minutes) until you stop it.
---

# Work

Run the **`workaholic:work` skill**, carrying `$ARGUMENTS` and any interval in the person's
instruction into its startup interval resolution and capability selection. With no requested
interval the default is five minutes; `/work 1m` requests one minute. Where the selected native
mode uses the `loop` skill, invoke it with `<resolved interval> /infinite-development`.
The command chooses neither a mode nor a second default of its own.

**One session, one loop.** If this session is already looping, say so and start nothing —
a second loop would spawn a second `implement` against the same claim protocol, and the
listing is the only record either of them reads.

To stop it, the developer stops the loop the `loop` skill created; `/work` does not take a
stop argument, because a command whose behaviour depends on the first word of its argument is
the shape this repository refuses (`rules/general.md`, *One behaviour per command*).

**The loop is `workaholic:work`, and this command is a thin alias onto it** — which is what
lets the same loop run off Claude Code, where `commands/` is not a command surface and only
skills are published. That skill carries how the loop is started from a chat-bound Scheduled
task in the ChatGPT desktop app and from an external clock in CLI-only environments, including
the CLI clock's first-tick readiness gate and read-only `scripts/codex-loop.sh --status` surface —
which answers the **whole** loop from the state directory alone: the supervisor's own liveness,
every worker's state and last outcome, and the last tick, with `--status --json` rendering the
same reading for a machine and every unreadable part named by its own reason rather than omitted
or rendered as healthy. It starts nothing, writes nothing, takes no lock and needs no `codex`
CLI. The tick,
the subagent contract and what the cadence buys: `workaholic:loops`
and `plugins/workaholic/commands/infinite-development.md`.
