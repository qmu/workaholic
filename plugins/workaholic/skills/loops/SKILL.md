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

Native coordinators cap total live workers across roles with `WORKAHOLIC_MAX_WORKERS` (default
2), intersected with runtime capacity. Due roles waiting for a slot remain due and precede extra
implement runners. `scripts/allocate-implement.sh --input FILE` computes implement allocation
from formation, the claimable reading, fanout and remaining capacity; unreadable work grants at
most one runner, never a claim that the queue is empty. This cap does not count other sessions.

A reading the coordinator could not make never becomes zero capacity. Load already carried that
rule; `loops/scripts/claimable-units.sh` now carries it too — `readable: false` falls back to one
runner and names the reason, which is what its `null` counts exist to make possible. And a tick
that ends having spawned no runner because something it needed was degraded posts
`workaholic:notify`'s precondition-stop shape under its own signature, so a coordinator-level stop
reaches the channel rather than only the tick's own report. Measured 2026-09-08: 100 minutes over
21 ticks with an unreadable claimable reading, zero runners, and nothing said anywhere.

The coordinator reports completed children once, keeps waits interruptible, and rediscovers
live children after compaction. Historical measurements, rejected designs, and compatibility
evidence live in `work/reference/other-agents.md`.
