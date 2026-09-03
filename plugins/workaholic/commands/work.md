---
description: Start the development loop in this session — one tick every five minutes until you stop it.
---

# Work

Start the loop. Invoke the **`loop` skill** with the arguments `5m /infinite-development`,
and let it run.

That is the whole command. `/work` exists because the loop is the thing a developer starts
most often and `/loop 5m /infinite-development` is three pieces of syntax to remember for one
intention; the cadence and the tick live behind it so a person types neither.

**One session, one loop.** If this session is already looping, say so and start nothing —
a second loop would spawn a second `implement` against the same claim protocol, and the
listing is the only record either of them reads.

To stop it, the developer stops the loop the `loop` skill created; `/work` does not take a
stop argument, because a command whose behaviour depends on the first word of its argument is
the shape this repository refuses (`rules/general.md`, *One behaviour per command*).

**The loop is `workaholic:work`, and this command is a thin alias onto it** — which is what
lets the same loop run off Claude Code, where `commands/` is not a command surface and only
skills are published. That skill carries how the loop is started from a chat-bound Scheduled
task in the ChatGPT desktop app and from an external clock in CLI-only environments. The tick,
the subagent contract and what the cadence buys: `workaholic:loops`
and `plugins/workaholic/commands/infinite-development.md`.
