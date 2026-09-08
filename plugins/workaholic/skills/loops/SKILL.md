---
name: loops
description: Execution model for the Workaholic coordinator and its background roles.
user-invocable: false
metadata:
  internal: true
---

# Loops

The operative tick is `commands/infinite-development.md`; startup and cross-agent behavior
are in `workaholic:work`. Keep this file as an index rather than a second copy of either
contract.

One coordinator owns communication and two clocks. The anchored work clock advances
implement, propose/specificate, and moderate. The adaptive observation clock reads Slack and
assigned feedback issues, responds quickly after activity, and backs off through sustained
silence. Neither clock waits for worker completion.

Workers are bounded background children or detached processes. One role has at most one live
worker. Every result distinguishes process exit, command execution, work outcome, and delivery.
The claim protocol remains the allocator when several implement workers race.

The coordinator reports completed children once, keeps waits interruptible, and rediscovers
live children after compaction. Historical measurements, rejected designs, and compatibility
evidence live in `work/reference/other-agents.md`.
