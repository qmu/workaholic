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

## The allocation is decided from what the tick just read

**The tick's allocation was a constant and the loop's state was not** (2026-09-03, mission
`decide-each-tick-s-allocation-from-what-the-tick-just-read`), so the bottleneck never got
capacity and a runner with nothing to do was walked anyway. Measured over two hours: 54 tickets
across 8 active missions, **one** `implement` runner by construction — the concurrency rule
forbade a second — about seven hours of serial queue; and `propose`'s strategy half produced no
proposal on any run, each time re-deriving a gate only `implement` could clear.

**The concurrency rule is narrowed, not dropped.** `propose`, `ingest` and `moderate` stay one
agent per name. `implement` fans out to `min(WORKAHOLIC_IMPLEMENT_FANOUT, claimable units, bound
− running)`, each runner under its own name, and only `running` runners count against the bound
so a fan-out does not compound across ticks. **Absent means 1** — the present single runner — so
a repository that declares nothing is byte-identical to one before this existed.

**No runner is handed a unit.** Each surveys and claims for itself, and the claim arbiter settles
a race (`claim.sh` §3b wins one ref per claimed artifact before it creates anything, so the loser
refuses `claim_race_lost` holding no branch, worktree or commit). Assigning units at the tick
would put a second allocator beside `plan-units.sh`'s order. The stated cost is that a losing race
spends an agent run that produces nothing, bounded by the declared number.

**Two readers, and both answer `null` rather than a plausible number when they cannot read:**

| Reader | Answers | Degradation |
| ------ | ------- | ----------- |
| `loops/scripts/claimable-units.sh` | how many PR-units are independently claimable — `claimable`, `missions`, `backlog_units`, `resumable` | `readable: false` with `not_current` / `shallow` / `backlog_error` / `owner_unresolved` / `placeholder_identity` / `survey_unreadable`, and **null** counts |
| `loops/scripts/read-machine-load.sh` | the machine it is about to start runners on — `cores`, `load1`, `load_per_core` | `readable: false` with `no_loadavg` / `no_core_count` / `unparseable`, and **null** counts |

`claimable-units.sh` **composes `plan-units.sh`** and derives nothing of its own — counting
`todo/` files would ignore missions, claims, ownership and every exclusion the survey already
makes, and would hand the tick a number the executor would then refuse. It counts all loose
backlog as **one** unit, because the batch partition is a judgement made at §2 of the Unified Run:
under-counting spawns fewer runners than the queue could carry, over-counting spawns runners that
find nothing. **Cost, measured and stated rather than worked around**: 68–73 seconds on this
machine, three consecutive warm runs — roughly a quarter of a five-minute tick.

`read-machine-load.sh` exists because the tick decided how many runners to start and read nothing
about the machine it started them on. Measured mid-fan-out here: three concurrent runners on a
**four-core** machine at loadavg `7.99 / 6.42 / 5.60`, the fifteen-minute figure saying it had
been over capacity for a while rather than spiking. Memory was half free and the SoC was not
throttling, so **CPU was the binding resource** — the reader answers about CPU alone and says so
rather than claiming a verdict about the machine's health. It answers **`null`, never `0`**: a
zero load reads as *an idle machine*, the one answer that would make a consumer fan out hardest at
exactly the moment it must not.

**`readable` is absent on a completed read** on both — the `merge_policy` / `status:` convention
this repository already holds — so a consumer tests `readable == false` and never `readable //
true`.

**The ingest half runs on the tick's own capture.** `propose` bundled an event-driven half with a
state-gated one behind a single number, so a captured ask waited up to fifteen minutes for a
clock. They are split at the spawn: the strategy judgement keeps
`WORKAHOLIC_PROPOSE_CADENCE_MINUTES`, and the ingest is spawned whenever §1 filed an issue this
tick — keyed on the tick's own act and on nothing else, with no queue reading, inbox poll or
change detector. The ingest still runs on the cadence too, because an ask filed directly on GitHub
is one §1 never sees; and when both run in one tick the strategy judgement is spawned first, so
the issue it opens is in the inbox the ingest reads.

**A runner whose last answer cannot have moved is skipped.** The strategy half's deferral reads
the *previous* strategy run's reported refusal from the tick log — the gate's last answer, never a
recomputation of it — and fires **only** on `work_waiting`, the one refusal `implement` can clear.
It is lifted the moment an `implement` run lands a unit, capped at `WORKAHOLIC_PROPOSE_DEFER_MAX`
skipped cadences (default 3) after which the strategy half runs regardless, and an unreadable log
defers nothing. A brake with no ceiling is how the one routine that originates work stops silently,
which this repository has measured twice.

**Every allocation is reported, and a tick that chose to watch says so.** The tick's §3 report
names how many runners were spawned out of how many claimable units against what bound;
`watching` with its reason where it spawned none; the deferral with the refusal it read and how
many cadences it has held; and every unreadable input by its own word (`fanout_unreadable`,
`bad_fanout`, `cadence_unreadable`). A tick that did nothing still reports **one line** — an
allocation of zero is one line, not five. Nothing here reaches Slack: this is the tick's own run
report, which the operator reads in the session, and the loop posts no status line about its own
capacity, for the reason the two retired status roots record.

## Permission prompts are off in this session

An unattended run never waits for a person (`rules/interaction.md`). The session runs with
`--dangerously-skip-permissions` on the developer's own server, in a checkout the developer
owns; an allowlist would have to enumerate every read the loop will ever make, and the measured
failure of that approach is issue #865.
