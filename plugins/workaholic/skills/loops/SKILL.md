---
name: loops
description: Use when a session runs `/infinite-development`, or needs to know how the development loop is executed — one session, one five-minute tick that answers on Slack and spawns the propose and implement runs as background subagents without waiting for them.
user-invocable: false
metadata:
  internal: true
---

# Loops

**One session, one loop, and it never waits.**

```
/loop 5m /infinite-development
```

Each tick reads the inbound Slack channel and answers on it, spawns `propose` and `implement`
as background subagents, and ends. The tick is short by construction, so a person's message is
answered within five minutes whatever the work is doing.

**The clock is a recorded finish, not a live agent** (2026-09-03, mission
`stop-a-finished-subagent-and-take-the-loop-s-clock-off-it`). `ListAgents` answers **is this loop
still running** and nothing else; every `idle` subagent is stopped at the **head** of the tick,
unconditionally, because an idle agent is a **resumable session holding its whole transcript** and
stopping it is the only act that returns the context window. The tick that first observes a run idle
records `loop-finish-<name>` on the tick log and every cadence is read from that. **An `/implement`
run takes one PR-unit and ends**, so no context spans two missions.

**The tick's own measurements, rejected alternatives and history live in
[reference/tick-record.md](reference/tick-record.md)**, not in the command body (2026-09-03,
mission `pay-only-the-operative-cost-on-every-tick`). The command runs in one session that never
resets, so every byte of it is re-paid on every five-minute tick — a run applying a rule needs the
rule, and a person deciding whether to *change* a rule needs the record. **No operative instruction
moved and nothing was replaced by a summary**: `workaholic:notify` states that *the command is the
ceiling*, and a rule the run must read to act stays inlined there byte-identical while a provenance
citation stays a citation.

## The same loop on Codex

`/work` and `/infinite-development` are **not reachable from Codex** — both `.codex-plugin`
manifests expose `"skills"` and nothing else, so `commands/` reaches Codex as files in the tree
and never as commands — and Codex has no **detached** subagent whose parent ends first.

**In the ChatGPT desktop app, the clock is a Scheduled task inside the current chat.** It runs
one tick per invocation in the local project and returns the report to that chat; the durable
prompt and the local-project requirement live in `workaholic:work`. Scheduled tasks are an app
surface. They do not make `/work` a CLI command and do not change the sequential tick below.

**In Codex CLI or the IDE, the clock remains external.** Those surfaces have no Scheduled
management interface; diagnosed 2026-09-03 with `codex-cli 0.149.1` and retained as the CLI
fallback:

```sh
sh scripts/codex-loop.sh            # the clock: one `codex exec` per interval, sequential
sh scripts/codex-loop.sh --once     # one tick, for a cron or systemd timer
```

The supervisor is the clock and **`workaholic:work` is the contract both agents read** — the
operator's own shape: Claude Code calls the loop as a command, every other agent calls it as a
skill, and `build.mjs` publishes it. The work runs **inline and in sequence** off Claude Code,
because there is nothing to detach it to.
Ticks cannot overlap by construction; `flock` refuses a second supervisor; the cadences are read
from the same tick log, which never depended on an agent listing. `.claude/settings.json`'s `env`
block is read and exported by the supervisor, so there is one declaration for both agents.

**What the sequential port loses is stated rather than discovered**: the five-minute answer to a person
(here the Slack turn is the tick's first act, so the worst case is one tick's work duration) and
the Claude-Code tool-level hooks (the script-level gates still hold; install the git-native
`commit-msg` hook for the rest). **Codex CLI has no Scheduled management surface**; the desktop
app does, and a chat-bound task restores the missing report path without changing the tick. The
measurements, the rejected two-loop split and the full substitution table:
`workaholic:work`'s `reference/other-agents.md`.

## Why the tick does not wait

The loop's job is two things at different speeds: **advancing the work**, which takes minutes to
tens of minutes, and **following a person's steering**, which must take seconds. A tick that ran
the work inline would answer a redirection only after the run it was redirecting had finished —
the loop would be least responsive exactly when a person was trying to change its mind.

So the main agent owns **Slack and nothing else**, and the work runs beneath it as subagents. A
person's ask becomes an `[FB]` issue in the same tick it was written; the propose subagent
ingests it on the next one.

## The tick reads its own checkout, because nothing else will

Every other part of the loop is careful to leave the caller's checkout alone: `/implement` drives
each unit in a claim worktree, `/specificate` writes through a publish tree at `<root>/.publish`,
and both leave the tree they were called from byte-identical. That is right, and it has one
consequence nobody had drawn: **no part of the loop ever looks at the tree it runs in.**

It matters because a subagent reads the plugin **out of that tree**. Uncommitted lines there are
not pending work — they are behaviour the loop is already executing, on no base, reviewed by no
pull request. Measured 2026-09-03, the loop's first hour: this command's own first version, the
retirement it performed and the environment declaration beside it were all sitting uncommitted
in the checkout, driving every tick, and nothing anywhere was looking.

So the tick reads `git status --porcelain` once, before anything else, and **names a dirty tree
in its report**. It blocks nothing and commits nothing: the tree belongs to a person, half a
change is the normal state of one, and a loop that commits what it finds lying around is a worse
failure than the one it would cure.

## The listing is the whole record

Before spawning, the tick calls `ListAgents`. No cursor, no lock file, no stored state — the
listing answers everything, because a subagent that finished stays listed as **idle** carrying
the age it started at.

**A loop whose subagent is still `running` is not spawned again.** That is the concurrency rule,
and it has not moved.

**An `idle` one is a finished run, and the tick reaps it — `TaskStop` on that loop's own name —
immediately before it spawns.** Nothing is discarded: the run is over and its result already
arrived as a task notification. Measured 2026-09-03, the first hour this loop ran: three ticks
left three idle `propose` agents standing, and the third could not even take its own name and
was spawned as `propose-3`. At a five-minute tick that is roughly a hundred corpses a working
day, accumulating inside the one listing the concurrency rule itself has to read.

**And the idle agent is each loop's own clock**, which is the reason it is reaped at the spawn
rather than at the finish. `started N ago` is when that run began, so a loop with a cadence
needs no timestamp anywhere: an idle agent younger than the cadence is left standing and the
loop reports `not_due`; an older one is reaped and respawned. The age is measured from the start
of the previous run and not its finish, so a run that took four minutes comes back four minutes
early — stated, because it is the price of having no store. An empty listing — a session that
just restarted — means every loop is due.

`implement` runs every tick: there is always more of its work to do, and the claim protocol
already refuses what another runner has taken.

**`propose` runs on a cadence — `WORKAHOLIC_PROPOSE_CADENCE_MINUTES`, default 15 — because its
answer is a function of what is queued.** The queue moves when `/implement` lands something or a
person writes an ask, and neither happens inside five minutes. Measured 2026-09-03: three
consecutive ticks, three full agent runs, every one answering `work_waiting` / `nothing_in_hand`
and writing nothing anywhere — the gate was correct each time and the question was the waste. A
change-detector was refused by name: *has the queue moved* is a second derivation of the ladder
`/propose` already owns, and a rule this repository keeps in one place does not get a second
home in the tick that calls it. `0` means every tick.

`moderate` runs on a **30-minute** gate read from its own tick log
(`moderate/scripts/log-read.sh`) rather than from the listing: its acts — retirement, closable
missions, standing rulings, findings — are hourly by nature, and the log is a reader that
already exists. An unreadable log spawns it.

Beneath all of that, nothing else needed arbitrating: `/implement` drives every unit in its own
claim worktree and the claim protocol arbitrates the remote (`workaholic:drive`, *Claims*);
`/specificate` writes through a publish tree at `<root>/.publish`. Two subagents of one session
share a checkout, and the two that share it never write the same tree at the same time because
each holds its own.

## What this replaced, and what went with it

**The three-tmux-session premise is retired** (2026-09-03, the developer's instruction). It ran
`propose`, `implement` and `moderate` as three interactive Claude Code sessions in tmux, each in
its own clone under `~/.workaholic/loops/<repo>/<loop>`. Measured: the split was the defect. The
propose loop reported `work_waiting` every five minutes for hours while the implement loop
reported nothing claimable, each correct in isolation and neither able to see that five pull
requests had been sitting conflicted since the previous day. Three sessions meant three places
to look and no place that held the whole loop.

Deleted with it, and **not to be reintroduced**: `/spawn-loops`, `loop-status.sh`,
`stop-loops.sh`, `spawn-loops.sh`, the loop table, one clone per loop, the trust-dialog write
into `~/.claude.json`, and the `no_tmux` refusal that named the Web routines as a fallback.
The Claude Code Web routines survive as their own premise (`workaholic:workaholify`, *Routines*)
and the two must not run against one repository at once.

**The Slack turn and the inbound sweep moved out of `/propose`** into the tick itself. They were
there because `/propose` was the first thing a routine ran; now the first thing is the tick, and
the reading belongs to the agent that can act on it immediately. `workaholic:propose` keeps the
sweep's **scripts** (`list-swept-slack-refs.sh`, `file-inbound-ask.sh`) — moving them would be
churn for nothing — and `commands/infinite-development.md` is the one place their use is
specified.

**And the tick announces what finished, in the same turn** (2026-09-03, mission
`announce-an-ask-that-landed-outside-a-unit-route-in-its-own-thread`). `🟢 Implemented` is a
**per-unit** post of `/implement`'s route step, so an ask whose work landed through a session
working it directly reaches no route step and its thread ends at the `📥 受理` receipt — from the
channel, an ask that shipped hours ago and one nobody started are byte-identical. Measured
2026-09-02: three merged pull requests, the issue closed, and the operator found out by asking a
session.

The tick is the one place positioned to close that: it already reads the channel and already
resolves threads, so the step costs it no read it was not making. `list-unannounced-closed-asks.sh`
names the candidates from the repository and the issues alone — **never a channel scan** — and the
tick replies once into each item's own thread, resolved by the `fb:<stem>` exact string. **The
dedup is the thread itself**: the thread is read before anything is posted, and one already
carrying a finish line for this item is skipped. No ledger, no cursor and no field on any
artifact — a store would have to survive a fresh container, which is the property this loop has
repeatedly failed to keep. The shape and its bounds are `workaholic:notify`'s, carried
byte-identical into `commands/infinite-development.md`, which is the ceiling the run reads.

## Permission prompts are off in this session

An unattended run never waits for a person (`rules/interaction.md`). The session runs with
`--dangerously-skip-permissions` on the developer's own server, in a checkout the developer
owns; an allowlist would have to enumerate every read the loop will ever make, and the measured
failure of that approach is issue #865.
