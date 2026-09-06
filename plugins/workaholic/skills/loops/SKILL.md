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
and never as commands — and Codex has no **detached** subagent whose parent ends first. It has
detached **processes**, which is what the port uses instead.

**In the ChatGPT desktop app, the clock is a Scheduled task inside the current chat.** It runs
one tick per invocation in the local project and returns the report to that chat; the durable
prompt and the local-project requirement live in `workaholic:work`. Scheduled tasks are an app
surface. They do not make `/work` a CLI command and do not change the tick below.

**In Codex CLI or the IDE, the clock remains external.** Those surfaces have no Scheduled
management interface; diagnosed 2026-09-03 with `codex-cli 0.149.1` and retained as the CLI
fallback:

```sh
sh <work-skill-directory>/scripts/codex-loop.sh         # one `codex exec` per interval
sh <work-skill-directory>/scripts/codex-loop.sh --once  # one tick for cron or systemd
```

The supervisor ships beside the installed `workaholic:work` skill, so no repository-local
wrapper is required. The supervisor is the clock and **`workaholic:work` is the contract both agents read** — the
operator's own shape: Claude Code calls the loop as a command, every other agent calls it as a
skill, and `build.mjs` publishes it. **The coordinator's tick is the channel turn and the
dispatch, never the work** (2026-09-05, issues #984 and #985): each due run starts as a detached
worker through `codex-loop.sh --dispatch <role>` and the tick never waits for one, while the
clock is anchored to **startup** rather than to the previous tick's finish, so a run lasting
longer than the interval costs the boundaries it overran and never delays the next channel turn.
A role already running is refused `already_running`, which is what `ListAgents` answers for the
Claude tick. `flock` refuses a second supervisor; the cadences are read
from the same tick log, which never depended on an agent listing. `.claude/settings.json`'s `env`
block is read and exported by the supervisor, so there is one declaration for both agents.

**What the port loses is stated rather than discovered**: the Claude-Code tool-level hooks, and
nothing else since 2026-09-05 (the script-level gates still hold; install the git-native
`commit-msg` hook for the rest). The five-minute answer to a person is **no longer** on that
list — it was, while the work ran inline, and both terms that cost it were repaired. **Codex CLI has no Scheduled management surface**; the desktop
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
(`moderate/scripts/log-read.sh --owner loop --step-prefix loop-finish-moderate --latest-tick`)
rather than from the listing: its acts — retirement, closable missions, standing rulings, findings
— are hourly by nature, and the log is a reader that already exists. An unreadable log spawns it.
**The step filter is what makes it *its own***: every loop's `loop-finish-<name>` line lands in that
one file under the coordinator's tick id, so an unfiltered read answers whichever tick wrote last
and the gate can read *moderate ran just now* indefinitely — silently, because the wrong answer is
a well-formed tick id (2026-09-07, ticket `20260907031134`). **And `--owner loop` is what keeps it
reading anything at all** (2026-09-07, ticket `20260907063154`): `log-read.sh` derives each entry's
owner from the step id and answers moderation by default, so the coordinator's own `loop-finish-*`
lines must be asked for by name. The two filters answer different questions — the owner says *whose
lines*, the prefix says *which loop* — and all three cadences carry both.

## A `running` runner is not necessarily a working one

`ListAgents` reports `running` for a runner executing a tool and for one blocked forever on a
permission dialog nobody will answer. **Measured 2026-09-06**: `implement-10` made its last tool
call at 05:42:49 UTC and was reported `running` by **nine** consecutive calls until the parent
stopped it by hand at 06:21:18 — 38m29s. The tick's reaping stops only `idle`, so a frozen runner
is never stopped, never records `loop-finish-<name>`, and stays counted by the fan-out.

`loops/scripts/read-runner-advance.sh` answers it, per running loop name, from the evidence the
localization proved and no other. **What moves during healthy work and is flat during a freeze is
the claim worktree's own files** — measured in one reading: a worktree mid-ticket had a newest
mtime 101 seconds old while three worktrees of stopped runs read 15, 17 and 18 hours. **What is
flat in both, and is therefore not read**: the claim tip and heartbeat (the beat is step 0 of every
ticket rather than a cadence, so a run legitimately mid-ticket carries an old tip — record
`20260906121540`, and `batch-20260831141002` resumed at 33 minutes while working; it is besides
that on a remote ref, and this reader makes no network call), and `loop-finish-<name>`, which is
written when a run is first observed **idle** and so says nothing during any run. `started` age
stays retired and does not come back here.

**Nothing this repository owns is keyed by loop subagent name** — a claim is keyed by unit, a
worktree by unit, `loop-finish-<name>` by role — so a name cannot in general be bound to the
worktree its runner writes in. The reader **refuses that binding by name** (`ambiguous_binding`)
rather than inventing it, and answers exactly where the binding is not needed: every name is
`advancing` when at least as many worktrees are advancing as there are runners, and every name is
`not_advancing` when none is and every claim was readable.

**An unreadable reading frees nothing**, in each of its forms — `no_claim_evidence` (no worktree
exists to have moved, so a runner still surveying is indistinguishable from a frozen one),
`claim_evidence_incomplete`, `role_holds_no_claim`, `bad_window`. `frozen_count` counts only the
names actually answered `not_advancing`, so no consumer can spend a reading the reader declined to
make; `running` and `advancing` ride beside it, leaving the gap visible without being spendable.
A wrong `not_advancing` sends the loop after a runner that is working, which is the one way this
reading can do harm. Drilled offline by `verify-runner-advance`.

**A `not_advancing` runner stops consuming a fan-out slot**, and that is the whole act. It is
subtracted from `running` **in the fan-out expression and nowhere else** — the concurrency rule's
other half is byte-identical, so a loop whose subagent is `running` and **advancing** is still not
spawned again. Measured with `WORKAHOLIC_IMPLEMENT_FANOUT=3` and one frozen runner: a 2-runner
loop for 38 minutes, with no tick report saying so.

**The slot is what recovers the work, and the claim protocol already owns the rest**: the frozen
runner's heartbeat lapses and `claim.sh resume` takes over one's **own** lapsed claim, so a runner
spawned into the freed slot picks the unit up. No second path to release a claim was added.

**Nothing is stopped or killed on this reading.** The unconditional `TaskStop` stays on `idle`, and
extending an unconditional stop to a *judgement* about advancement would kill work in progress —
the mistake the machine-load bound already refuses by name. The frozen session is the operator's to
end, or the next `idle` observation's. The reading is taken fresh each tick, as `claimable-units.sh`
and `read-machine-load.sh` are: no store, no cursor, no field on any artifact. The risk it carries
is a false `not_advancing` on a slow unit, which would spawn a second runner against a working one;
the claim arbiter settles that race and the loser refuses `claim_race_lost` holding nothing, so the
cost is bounded — but the reader's precision is the reader's obligation, not something compensated
for here.

## The allocation is decided from what the tick just read

Read independently claimable work with `loops/scripts/claimable-units.sh` and machine CPU facts
with `loops/scripts/read-machine-load.sh`. Both return null counts with a named degradation when
they cannot read; a missing reading never becomes a plausible zero. `implement` fans out to
`min(WORKAHOLIC_IMPLEMENT_FANOUT, claimable units, bound − (running − not_advancing))`, with an absent bound meaning
one and an invalid bound reported as `bad_fanout`. Each runner surveys and claims for itself, so
the claim arbiter remains the only allocator and a losing race holds nothing.

**The question that count answers is *is there work an `/implement` pass would act on*, which is
not *is there a new unit to claim*** (2026-09-06, mission
`finish-the-backlog-without-handing-it-back-to-the-operator`). Those two stopped being the same
question once the Unified Run grew its recovery and delivery acts, and until this the count read
only the survey's fresh units: **measured**, a repository whose only work was one
`report_undelivered` unit answered `claimable: 0`, byte-identical to one with genuinely nothing
to do, so no runner was spawned at all — while an `/implement` pass would have caught the branch
up and merged it. The operator's own report of the failure is 28 tickets waiting, zero units and
four conflicting pull requests with no pass ever run to inspect them. The count therefore
composes `plan-units.sh`'s own `undelivered[]`, `drive/scripts/list-catchable-claims.sh` and
`branching/scripts/list-stranded-publications.sh` — readers that already exist, no second walker,
no new field, no verdict re-derived.

**All of that recovery work is ONE unit**, for the reason all loose backlog is one: those three
are **once-per-run** acts, so a single pass walks every entry, and counting them per entry would
spawn N runners to do one runner's work and race each other on the same pull requests. The
per-term counts (`undelivered`, `catchable`, `stranded`) ride beside `recovery_units` so the
tick's report can name **which** term earned the runner. A unit appearing in two of the sets is
counted once. `parked_with_pr`, `awaiting_verification` and `superseded` are still not counted —
the first is reached through the catchable term where it is actionable at all, the second waits
on a declared verification this reader may not probe, and the third holds nothing to drive.

**A recovery component that could not be read answers `readable: false` with its own reason**
(`catchable_unreadable`, `stranded_unreadable`), never a zero: the caller's stated behaviour on
an unreadable count is to fall back to one runner and report it, so a named degradation still
spawns the pass that a zero would not. The cost is stated rather than tuned around — the two
readers add bounded REST reads of this repository's open pull requests, once per tick and never
once per entry, and `--recovery <path|->` lets a caller that has already made those readings hand
them in.

**Both bounds are declared in `.claude/settings.json`'s `env` block**, beside `WORKAHOLIC_WIP_LIMIT`
and for its reason: a routine declares no environment variables of its own — it *selects* an
account-level environment — so a per-repository number has to live in the repository
(`workaholic:workaholify`, *Where a routine's environment variables live*). **A fan-out needs a
number, and the rule for a number nobody can defend is to make the operator declare it**, which is
why this skill picks none for any machine.

| Declaration | Absent means | Invalid means |
| ----------- | ------------ | ------------- |
| `WORKAHOLIC_IMPLEMENT_FANOUT` | **1** — the single runner, so such a repository is byte-identical to one before this existed | `bad_fanout` on a non-numeric or non-positive value: it holds nothing, falls back to 1, and is reported by name |
| `WORKAHOLIC_MAX_LOAD_PER_CORE` | **no machine bound** — the fan-out is exactly what it would be without this | `bad_load_ratio` on a non-numeric or non-positive value: it holds nothing and says so |

**The machine bound is the second bound on the same fan-out**, making it `min(declared bound,
claimable units, what the machine can carry)`. Past the core count each added runner makes every
other runner slower — throughput per runner falls, wall-clock per unit rises, and the loop observes
only that units are still landing, which is the quiet kind of failure this repository takes most
seriously elsewhere. Measured mid-fan-out on the machine the loop runs on: three concurrent
`implement` runners on a **four-core** machine at loadavg `7.99 / 6.42 / 5.60`, with memory half
free and the SoC not throttling — CPU was the binding resource, which is why the reader answers
about CPU alone. **On exactly the same evidence it used to add the third runner it would have added
a fourth and a fifth.**

Before each implement spawn **beyond the first**, a `load_per_core` already over the declared ratio
refuses that spawn by name: `load_saturated: <load1>/<cores>`. Four bounds ride with it, each a
refusal rather than a preference. **The reading gates adding, never stopping** — no running unit is
killed, paused or reaped for load, because that throws away work in progress, the mistake a
too-eager staleness threshold makes (measured the same day: a unit that looked stalled for twenty
minutes was reading documents and landed shortly after). **The first runner is never refused**, or
a machine over its ratio with nothing running would stop the loop entirely. **A gate that cannot be
read is not a gate** — `readable: false` holds nothing and is reported by the reader's own reason.
And **the ratio is per core**, so one declaration means the same thing on a single-board computer
and on a workstation; the loop is meant to run forever on whatever machine its developer has. A
ratio above the core count is not an error — an operator who wants queueing gets it and the bound
simply never fires.

**A bound that fires silently is the failure this section exists to end**, so the tick's §3 report
carries one line about the machine **beside** the per-loop lines and never in place of them — and
**only when it has something to say**. A tick the machine held names the refusal, the load and the
core count; a degraded reading is named by its reason and never rendered as headroom (`the machine
could not be read this tick (no_loadavg); the fan-out was not bounded by it`); an unheld, readable
machine adds **no** line, because an unchanged answer restated every tick is what `📦 Release
Preparation` was retired for. It carries **no identifier and no mention token** — a fact about the
machine, addressed to nobody — and it says what the machine *was* and whether it *held* the
fan-out, deliberately not what the tick would otherwise have spawned, which would be a second
derivation of the allocation the tick already owns. **It reaches Slack through nothing**: this is
the tick's own run report, and the loop posts no status line about its own capacity, for the reason
the two retired status roots record.

The event-driven ingest half runs when this tick captured an ask, independently of the cadenced
strategy judgement. A prior strategy result may defer only its own reported `work_waiting`, is
lifted when implementation lands, and is capped by `WORKAHOLIC_PROPOSE_DEFER_MAX` (default 3).
Every allocation, deferral, and unreadable input is named in the tick report; watching is a
decision, not silence.

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
