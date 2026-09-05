---
name: work
description: Run the development loop — one tick every few minutes that answers the inbound channel and drives the queued work. Use when a session is asked to start, run, or perform one tick of the loop, on any agent.
---

# Work — the development loop

**One session, one loop.** A tick answers the inbound channel and moves the queued work, then
ends; the clock starts the next one. If this session is already looping, say so and start
nothing — a second loop would drive the same claim protocol twice.

## Starting it: the mode is selected from what THIS SESSION can do

The tick below is the same everywhere. **Only the mode differs** — and the mode is a property of
**the session's own tool set**, never of the agent's name or its version string. It is re-derived
at every startup and cached nowhere: one product answers differently in its CLI, its IDE
extension and its desktop app, so a cached answer carries one surface's reading into another's
session.

**Four capability questions, and no others.** Each asks about a tool this session holds:

| # | Question |
| - | -------- |
| **C1** | Can this session **wait and be woken early** — a sleep that returns on user input? |
| **C2** | Can it **emit intermediate output without ending its turn**? |
| **C3** | Can it **start child work it does not have to collect** before returning — a child agent whose lifetime outlives the call, or a detached process? |
| **C4** | Is a **same-chat scheduler** callable — one that re-invokes this conversation on an interval? |

**The ordered selection table. Take the first branch whose terms hold:**

| Branch | Terms | The clock | What it does NOT promise |
| ------ | ----- | --------- | ------------------------ |
| **1. Native parent** | C1 **and** C2 **and** C3 | the coordinator's own turn (*The native-parent branch*). **Where the harness supplies an in-process recurring timer over this same session, that timer IS this branch** — on Claude Code it is the `loop` skill, `/loop 5m /infinite-development`, which `/work` invokes for you | continuation after an explicit stop, an app closure, a cancellation or a hard harness limit, unless a resumption mechanism has been **tested** and named beside it |
| **2. Same-chat schedule** | C4, and branch 1's terms do not hold | a Scheduled task **inside the current chat**, at the requested minute interval, running in the local project | anything while the app or the computer is closed |
| **3. External supervisor** | a shell and a CLI that can run one tick | an external one: the `scripts/codex-loop.sh` beside this skill, or a cron entry / systemd timer running it `--once` | **that its output reaches the invoking conversation.** The supervisor has no parent to call back into; a report that lands in `.codex-loop/` is not a report the person who started the loop will see |

**The resolved mode is reported at startup**, with the capability answers it was chosen on, so a
wrong selection is visible in the transcript rather than inferred from behaviour hours later.

**When no branch's terms hold, name the specific missing mechanism at startup and stop.** Say
which capability question went unanswered — *this session can start no child it does not have to
collect, and no scheduler and no shell are reachable* — and select **no substitute**: a
requirement reported unresolved is one somebody can supply, while a mode that delivers somewhere
else is a requirement reported met. **A capability that could not be read is named as unread,
never as absent** — a gate that cannot be read is not a gate.

What this rule exists for, measured: `reference/other-agents.md`, *Why the mode is read off the
session*.

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

**One measurement, dated and scoped, and it decides nothing on its own**: `codex-cli 0.149.1`,
2026-09-03, exposed no Scheduled management interface — a reading about **that surface at that
version**, never about a product or about non-Claude agents in general. It is evidence for how a
session lacking C4 will usually answer, and the answer is still the session's own.

Where branch 3 is selected, this skill's own `scripts/codex-loop.sh` supplies the clock: one
`codex exec` per interval, sequential, `flock`ed against a second supervisor, exporting
`.claude/settings.json`'s `env` block so both agents read one declaration.

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

**Where a slash-command surface dispatches `commands/*.md`** — Claude Code — run
`plugins/workaholic/commands/infinite-development.md`. That command is the ceiling for what a
tick may post, and it carries the Slack shapes byte-identical.

**Where none does**, execute the same command body as a **file**: read
`plugins/workaholic/commands/infinite-development.md` and do what it says, with the substitutions
below. Both `.codex-plugin/plugin.json` manifests expose `"skills"` and nothing else, so
`commands/` reaches such an agent as files that exist rather than as commands. That is why this
skill exists: a skill is published where a command is not (`.codex-plugin/plugin.json` declares
`"skills": "./skills/"` over the whole plugin), so the loop reaches every agent through the
plugin the marketplace already installs.

| What the command body says | Where no command surface dispatches it |
| -------------------------- | -------------------------------------- |
| `/loop 5m` keeps calling this | the branch's own clock does — *What "end" means* below renders this per branch, because it is the one row that differs between them |
| `/implement`, `/propose`, `/specificate`, `/moderate` | read `plugins/workaholic/commands/<name>.md` and execute it |
| spawn the runs as **background** subagents and do not wait | **branch 1**: dispatch each due role as a **bounded native child** (*The workers*). **Branches 2 and 3**: `sh <this skill>/scripts/codex-loop.sh --dispatch <implement\|propose\|moderate>`, which starts a **detached** worker and returns at once. Never run the work inline, and never wait for a worker |
| `ListAgents` answers *is this loop still running*; `TaskStop` reaps the idle ones | **branch 1**: the coordinator's own **role-to-child map** answers it, and its listing rediscovers after a compaction. **Branches 2 and 3**: `--dispatch` answers it by **refusing** — a role already running reports `already_running` and is not started twice — and `--status` names each role's state. Nothing is reaped there: a worker is a process that ends, not a session holding a transcript |
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

### The native-parent branch: the coordinator holds its own turn

Branch 1 of the selection table. **The three terms above are the clock and are composed here, not
restated**: the cadence is measured from startup, the work is dispatched and never awaited, and a
role already running is refused by name. What this branch adds is the one thing no repair to an
external supervisor can reach — **the coordinator keeps its turn**, so each tick's report lands in
the conversation the loop was started in.

1. **Derive the startup anchor once**, at the loop's start, and never re-derive it. Every later
   deadline comes from it, so an early wake, a slow tick and a question answered mid-loop all
   leave the phase exactly where it was.
2. **Run a short first tick and emit its report immediately**, so the operator sees the loop
   working before the first full interval has elapsed.
3. **Emit every tick report as commentary, not a final response** — what the tick did, what was
   dispatched, and what came back.
4. **Wait interruptibly between boundaries, in waits of at most 60 seconds** and shorter when the
   next deadline is nearer. **A five-minute blocking wait in the coordinator is refused by name**:
   it makes a person's question unanswerable for the length of the wait, which is the one thing
   the cadence exists to prevent.
5. **An early wake is not a tick boundary.** Recompute the remaining time, process what the wake
   brought — the operator's steering, a child outcome now available — report it, and return to
   waiting for the **same** deadline.
6. **At each boundary run the channel turn and the dispatch decisions whether or not any worker
   has finished**, then emit the tick report and return to waiting. **Never synchronously await a
   worker across the next boundary.**

What this branch restores that the external supervisor cannot, and what is not yet claimed for it:
[reference/other-agents.md](reference/other-agents.md), *What the native-parent branch restores*.

### The workers: bounded children the coordinator never awaits

1. **A role-to-child map lives in the coordinator** — role → child identifier → dispatched-at.
   **A role with a live entry is not dispatched again**, and the refusal is named in the tick
   report.
2. **Each due role is dispatched as a bounded child**: it performs that role's work **once** and
   returns. It reads no channel, decides no cadence, starts no other worker, and **never loops**.
   A child that looped would be a second coordinator, which is the shape this repository retired.
3. **The concurrency bound is the harness's own capacity, read before dispatching beyond the
   first role** — never assumed unlimited. A dispatch that would exceed it is **held**, and the
   hold is named with the capacity. **A capacity that cannot be read holds nothing** and is named
   as unread: a gate that cannot be read is not a gate.
4. **Collect newly available child outcomes at each wake, without blocking**, and report each
   completion or blocker **once** — a role reported once is not reported again.
5. **The cadence does not move.** Each child records `loop-finish-<role>` into the same tick log
   the coordinator already reads, so there is **no new store, cursor or field**.

**The native-child branch and the detached-process branch answer the same two questions by
different mechanisms, and neither is a second clock.** *Is this role running* — the role map here,
the per-role lock there. *When did it last finish* — the same `loop-finish-<role>` line in the
same tick log, on both. The claim protocol remains the only allocator of repository work: the role
map bounds **dispatch**, never claims, and a duplicate dispatch would be refused by the claim
arbiter anyway.

### Cutting over from the external supervisor

**Never run two coordinators against one repository** — the rule this skill already holds for the
desktop schedule and the CLI supervisor, holding for this pair for its reason. Starting branch 1
beside a supervisor that is still running is exactly that state.

1. **Identify the one coordinator being replaced, through the supervisor's own reading** —
   `sh <work-skill-directory>/scripts/codex-loop.sh --status`, which reads state and starts
   nothing — and **account for the workers it started**. Retire **that** coordinator: never a
   broader sweep of processes, and never a silent start beside one still running.
2. **A worker still running at cutover is named in the startup report and left to finish**, and
   **its role is not dispatched natively until it has**, so no unit is driven twice.
3. **The external supervisor is not deleted.** It stays as an explicitly different mode, and its
   row in the selection table says on its face that its output is **not** claimed to reach the
   invoking conversation — a cron or systemd environment with no conversation at all is exactly
   what it is for.
4. **No continuation is promised** after an app closure, a cancellation or a hard harness limit
   unless a resumption mechanism has been **tested**; an untested resumption is named as
   untested, never assumed.

`codex-loop.sh`'s own behaviour is unchanged by any of this: the cutover reads it and retires a
process, and rewrites nothing.

### What survives a compaction, and what is rediscovered

A long conversation is compacted, and the native-parent branch holds its state in the parent's own
turn. **Three things survive, and nothing else** — this is not a new store for the loop's whole
state, and **no file, field or store is introduced to hold them**:

1. the **startup anchor**;
2. the **running child identifiers**, with their roles;
3. the **outcomes already reported**.

**Compaction stops nothing: a running child keeps running.** Inferring otherwise is forbidden by
name here, because each of the three has a distinct failure if it is lost — a re-derived anchor
moves the phase, a lost map re-dispatches work that is still running, and a lost outcome set
re-reports what the operator has already read.

- **On resuming, rediscover the actually running work through the harness's own listing before
  dispatching anything**, and reconcile it with the carried map.
- **A child the rediscovery cannot find is reported unresolved and asked about.** It is **not**
  assumed finished, and its role is **not** re-dispatched on that assumption alone.
- **The anchor after a resume is the anchor before it** — the original, never a fresh derivation
  from the resume time, so the phase does not move.
- **An outcome already reported is not reported again**; the carried set is what makes *report
  each completion once* hold across a compaction.

A duplicate dispatch would be bounded by the claim protocol, which refuses a taken unit — but the
wasted run and the duplicated report are real costs, which is why rediscovery **precedes**
dispatch rather than relying on that refusal.

### What *end* means, and the two events that earn a final response

`commands/infinite-development.md` tells the tick to **end**. What that renders to is the
**branch's**, not the agent's — and reading it as *emit a final answer* is what killed the loop
once: the session ran its tick, ended its turn, and the operator's next status arrived only
because they asked for it.

| Branch | What *end* means |
| ------ | ---------------- |
| **1. Native parent** | **return control to the coordinator's own loop**, emitting nothing final. The clock is this turn, and a final response ends it |
| **1. Native parent, harness timer** | end the tick; the harness's own in-process timer calls it again in the same session |
| **2. Same-chat schedule** | end the run; the schedule re-invokes it and returns the report to this chat |
| **3. External supervisor** | end the process; the supervisor's clock re-invokes it |

**Under branch 1 a final response is reserved for exactly two events, and no others:**

- **an explicit stop from the operator** — which stops further dispatch and **states what remains
  running**, the roles still in flight and their child identifiers, rather than ending silently;
- **a named inability to continue** — the missing mechanism the startup report already named.

**An ordinary question or correction during the loop is answered in commentary.** It neither
cancels the loop nor resets the anchor: the following boundary lands where the original anchor
puts it. This **adds nothing to the tick's ceiling** — the shapes it may post are unchanged, and
**commentary in the originating conversation is not a Slack post**.

Where the clock re-invokes the tick — the harness timer, the schedule, the supervisor — the
existing wording is already correct and is deliberately not rewritten around this: the distinction
is only meaningful where a final response ends the turn.

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
