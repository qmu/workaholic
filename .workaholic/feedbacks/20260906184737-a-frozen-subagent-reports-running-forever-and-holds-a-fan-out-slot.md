---
type: Feedback
title: A frozen subagent reports running forever and holds a fan-out slot
kind: instruction
source: development
subject: person:tamurayoshiya
created_at: 2026-09-06T18:47:37+09:00
author: a@qmu.jp
supersedes: 
---

# A frozen subagent reports running forever and holds a fan-out slot

Source: https://github.com/qmu/workaholic/issues/1036

**A subagent frozen on a permission dialog it cannot answer keeps reporting `running`.** It is
indistinguishable from a working runner, it holds a fan-out slot for as long as nobody notices,
and the tick that reads `ListAgents` reports a healthy loop the whole time. Measured in an
unattended `/work` loop on 2026-09-06; the operator noticed the dialog, not the loop.

## The measurement

One `implement` runner, `implement-10`, in session `621984ae-4f0b-4b42-a7ee-a7a64e11ac85`.

| When (UTC) | What |
| ---------- | ---- |
| `05:42:21` | it calls `slack_search_public_and_private`; the auto-mode classifier denies it — reported, harmless |
| `05:42:49` | it calls `Bash` with `bash /home/<user>/.claude/plugins/cache/workaholic/workaholic/1.0.288/skills/story/scripts/record-merge-outcome.sh` |
| — | **that call never returns a result.** The runner's transcript file is never appended to again |
| `05:42:29 … 06:20:10` | nine consecutive `ListAgents` calls report `implement-10 · general-purpose · running`, its `started` age counting up 33m → 39m → 42m → 47m → 52m → 57m → 1h → 1h → 1h |
| `06:15:54` | the parent notices by hand — "implement-10's heartbeat stopped 35 minutes ago while its work has already merged" — from the *absence of task notifications*, not from any status |
| `06:21:18` | the parent records `loop-finish-implement-10` and calls `TaskStop` |

**Frozen 05:42:49 → 06:21:18 UTC = 38 minutes 29 seconds**, every second of it reported as
`running`.

The trigger is the one already written down in this repository's own project rules: a shell read
under `~/.claude` is treated as access to Claude's own configuration and raises an approval
prompt an unattended run cannot answer. That part is known. **What is not written down is the
consequence**: the run does not fail, does not go `idle`, and does not report anything — it stops
existing while still being counted.

## Why the loop cannot see it

Three separate mechanisms all read it as healthy:

1. **`ListAgents` has no state for it.** `running` covers both "executing a tool" and "blocked
   forever on a prompt nobody will answer".
2. **`/infinite-development`'s reaping only stops `idle` agents.** A frozen runner is never
   `idle`, so it is never stopped and never gets a `loop-finish-<name>` line — which is also the
   cadence source, so nothing downstream notices either.
3. **The fan-out counts it.** `min(FANOUT, claimable, bound − running)` counts a corpse as a
   live runner, so the loop silently loses a slot. With `WORKAHOLIC_IMPLEMENT_FANOUT=3` and one
   frozen runner the loop is a 2-runner loop and says nothing.

It was caught only because a person was watching and because this particular runner's work had
already merged, so its silence was conspicuous. On a longer unit it would have read as an
ordinary long build. This is the same shape as the already-recorded "the routine stops there and
every later tick looks healthy doing nothing", but one level down: the *tick* stays healthy and
it is the *runner* that is gone.

## What would fix it

Any one of these is enough; they are listed cheapest first.

1. **A last-activity time per agent in `ListAgents`**, beside `started`. The parent already
   derives this by hand from missing task notifications; exposing it makes the derivation
   mechanical. A runner whose last activity is older than its own work would plausibly take is
   then reportable — `stalled: <duration>` — rather than guessed at.
2. **Report a pending-approval state.** The harness knows a tool call is waiting on a permission
   decision. Surfacing that as its own status (`awaiting_approval`) makes the difference between
   "building" and "blocked on a human" readable by the loop instead of by the operator.
3. **Do not count a non-advancing runner toward the fan-out bound.** Whatever the diagnosis, the
   slot should come back.

Separately, and smaller: **the plugin's own scripts should never be invoked through a
`~/.claude/plugins/cache/...` path by a runner**, because that path is the trap. The runner here
composed it itself, having earlier resolved its plugin source to the cache; a resolver that hands
back a cache path hands back a path that will freeze whoever uses it.
