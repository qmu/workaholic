---
name: infinite-development
description: One tick of the development loop - watch the Slack channel and answer on it, then spawn the propose and implement runs as background subagents and end. It never waits for them.
skills:
  - workaholic:loops
  - workaholic:notify
---

# Infinite Development

<!-- workaholic:policy-lens — keep: hooks/policy-lens.sh matches this marker. -->

One tick. **Watch the channel, answer on it, start the work, end.** The tick never waits for
the work it started: the loop's responsiveness to a person is the point, and a five-minute
cadence is only a cadence if the tick itself is short.

Run it under `/loop 5m /infinite-development`, in **one** session. The premise, the subagent
contract and what was retired for it: `workaholic:loops`.

**Every skill section, reference file or command body this run consults is read with the Read
tool**, never with `sed`, `grep`, `cat` or `head` (2026-09-02, issue #865): a shell read under
the plugin cache is a permission prompt an unattended run cannot answer.

**Every free-text slot below is written in Japanese, and so is this run's own report** — labels,
status words, reason words, slugs, branch names, `<@U…>` tokens and URLs are never translated,
and a GitHub artifact stays English (`rules/interaction.md`). The Japanese must be **read on
first sight, not decoded**: a channel reader understands what is being said without opening the
English record behind the link. An established technical term keeps its ordinary katakana or
English form (ビルド, CI, デプロイ, PR); a title's **meaning** is translated, never its words.

## 0. The checkout the loop runs in

One read, before anything else: `git status --porcelain` in the repository root.

A **clean** tree says nothing. A **dirty** one is named in the report as `checkout_dirty` with
the file count, and the reason is not tidiness: the subagents this tick is about to spawn read
the plugin **out of this working tree**, so every uncommitted line here is behaviour the loop is
already running that sits on no base and that no pull request has reviewed. `/implement` writes
in a claim worktree and `/specificate` through a publish tree, and both leave the caller's
checkout byte-identical by design — which is exactly why nothing else in the loop will ever
notice this, and why it is the tick's to say.

It **blocks nothing and commits nothing**. The tree belongs to a person, half-finished work is
the normal state of one, and a loop that commits what it finds lying around is a worse failure
than the one it would cure. What was measured: `workaholic:loops`, *The record behind the tick*.

## 1. The Slack turn — the steering surface

Read `WORKAHOLIC_INBOUND_SLACK_CHANNEL` (default the repository's own name) through the **Slack
connector** over the last `WORKAHOLIC_SLACK_TURN_WINDOW_MINUTES` (default 10, so consecutive
five-minute ticks overlap and nothing falls between them), **in the concise format**: the tick
uses the author, the timestamp and the text, and the detailed format adds reactions and thread
metadata for every message on every tick that nothing here reads. Naming the format changes no
behaviour the tick depends on — the thread it must read before replying is fetched per message,
by the reply step that needs it, not by this listing. This is the one place the loop reads
a person, and it runs **before** anything is spawned — a redirection must not wait behind a
build.

Fetch the dedup ledger first: `bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/list-swept-slack-refs.sh`.
`ok: false` skips the capture half as `sweep_dedup_unreadable` — never file blind.

For each message a **person** wrote that the ledger does not already name, do exactly one of
three things. Skip the loop's own posts by shape (`📝 FB`, `🔎 Moderation`, `🔵 Proposed`,
`🟢 Implemented`, `📥 受理`, `💬`) — a machine's post is never an opinion to capture.

**A question the repository can answer** — what a command does, where something stands, why a
run did what it did — gets one reply in its own thread. **Read the thread first**; if a reply of
ours already follows that message, post nothing.

```
💬 [<the question, one line>]
<the answer, max 80 words, in plain Japanese, what the repository says and where>
<session URL>
```

**An ask** — something to build, change or fix, including a change of direction — is filed at
once through the one writer:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/file-inbound-ask.sh \
  --slack-ref <channel>:<ts> --permalink <url> \
  --subject 'person:<name>' --assignee <the running login> \
  [--feedback '<the direction's refs>'] <owner/name> "<title>" <body-file>
```

Then post one reply into **that message's own thread** — its `thread_ts` is the `ts` half of the
`slack-ref` just written, so run no lookup and no search — and add the reaction `:inbox_tray:`
on the same coordinate:

```
📥 受理 - [#123 [FB] Issue title](<repo-url>/issues/123)
<その人に話しかける言葉で、この依頼をどう受け取ったかと次に何が起きるか。最大80語、平易な日本語>
<session URL>
```

The middle line is a **reply, not a stamp**: say what the run took the ask to be and what
happens to it next, naming only what the filed issue already commits to (`/specificate` がこれを
読み、ミッションかチケットになります). It promises no schedule and no second act, asks nothing
back, and carries no mention token. When the run cannot tell what was asked, it says so there
rather than composing a confident paraphrase.

**An answer to one of the loop's own questions is not an ask.** A reply under a `🙋` question is
answering the tick that asked it, and `/moderate`'s `question-answers` step records it through
`record-answer.sh` — the one writer of an answer. The sweep must not open a second issue for it:
that turns one person's reply into a proposal nobody asked for, and the question stays `asked`
forever because nothing recorded the answer. Reacting to it is fine; filing it is not.

**Anything else a person wrote** gets the reaction `:eyes:` and no reply.

**Which direction an ask answers** rides the filed issue through
`feedback/scripts/ask-feedback-line.sh` — an explicit strategy slug first, else a judgement
against the `active` set, else no line at all. Report `direction:<slug>` or
`direction:unattributed` per filed issue.

Post nothing else and add no other reaction: not for an already-swept message, not for a
degradation, not for the spawns, not on an idle tick. A read or a post that fails is
`slack_turn_failed: <reason>` / `ack_failed: <reason>` and never blocks anything — the issue is
open before either is attempted. Degradations are named: `no_slack_transport`,
`channel_unreadable` (naming the channel it resolved — Slack answers *not found* for a channel
the token cannot see, so absent and invisible are one response), `sweep_dedup_unreadable`.

**And an ask whose work landed outside an `/implement` unit gets its finish line here** — the one step positioned to post it, because this tick already reads the channel and already resolves threads. Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/list-unannounced-closed-asks.sh`, and for each candidate resolve its thread by the `fb:<stem>` exact string, **read that thread first**, and reply once:

```
🟢 Implemented [<ask title>](<issue url>)
<one sentence, max 30 words, what landed and by whom.>
```

**It reuses `🟢 Implemented` and is marked by its sentence, never by a fifth colour** — the precedent `thread-reconcile` set for a merged item announced late. A channel reader's finish vocabulary stays at the colours it already has; a new colour for the same event, differing only in which reader noticed it, is a distinction only the loop cares about.

**The bounds, each of them a refusal rather than a preference:**

- **No mention token.** It is addressed to the thread, not to a person — the standing rule of this catalog, unchanged.
- **A reply, never a root.** The thread is resolved by the `fb:<stem>` **exact string** (SKILL, *One thread per feedback item*, case 2), and an item whose thread cannot be resolved — no match, or more than one — is **left alone** rather than announced somewhere else. Case 4's keyed root is deliberately **not** available here: a root would be a top-level post about an item whose own thread the run could not find, which is the wrong-thread outcome one step removed.
- **Once ever per item.** The dedup is **structural and read from the thread**: the thread is read before anything is posted, and a thread already carrying a finish line of ours for this item is skipped. No ledger, no cursor, no field on any artifact — a store would have to survive a fresh container, which is the property this loop has repeatedly failed to keep.
- **The connector carries it, and nothing else does.** It is the only transport that can **search**, so it is the only one that can resolve the thread at all; the tokened fallback posts nothing here, because a caller with no connector never resolved a thread to reply into.
- **What landed, or nothing about it.** The sentence is composed from the reader's `landed[]` — what merged and by whom — and an unresolvable field is **stated as unresolved**, never filled with a plausible name or time.

**The copy above lives in two files — `plugins/workaholic/skills/notify/reference/notifications.md` and `plugins/workaholic/commands/infinite-development.md` — and the two must stay byte-identical**, which the suite pins. The command is the ceiling a routine-fired session actually reads; the catalog is where the shape is decided. A diff between them is a drift to fix, never a second wording.


**Report one outcome per candidate, and naming a candidate without one is non-conformant on its face** — the enforcement every act in this repository carries, and for its reason: no mechanical check tells a real attempt from a claimed one.

| Outcome | What it means |
| ------- | ------------- |
| `announced` | the reply landed in that item's own thread |
| `already_announced` | the thread already carried a finish line of ours for this item — the whole dedup, read from the thread and stored nowhere |
| `thread_unresolved: <reason>` | the `fb:<stem>` search matched nothing, or matched more than one thread; the tie goes to silence and nothing is posted |
| `post_failed: <reason>` | the reply was attempted and refused; never load-bearing and never retried inside the turn |
| `held: <reason>` | the item is real but the sentence could not be made true — its `landed[]` was unreadable and the reply would have had to invent what merged |

**A tick that cannot see says so, and posts nothing.** Each of these is a behaviour with its own reported word, not a preference:

- **An idle tick** — no candidate — reports `no_candidates`, opens no root and says nothing in the channel about having nothing to say.
- **An unreadable candidate read** (`ok: false`) reports the reader's own reason **verbatim** and is **never** rendered as `no_candidates`. *Nothing finished* and *I could not see what finished* send a reader to different places, and this repository has twice measured a reader rendering its own blindness as *nothing found*.
- **An unresolved or ambiguous thread** — the `fb:<stem>` search matched nothing, or matched more than one — posts nothing and reports `thread_unresolved: <reason>`. **The tie goes to silence**: a wrong thread is worse than none (`workaholic:notify`, *Fuzzy matching is prohibited*), and case 4's keyed root is refused here by name.
- **A candidate whose `landed[]` could not be read** is announced only if the sentence stays true without the unresolved field; otherwise it is `held: <reason>` and left for a later tick. Never an invented name or time.

Report every held candidate with its own word, so a quiet tick and a blind one are distinguishable in the run report. The step costs the tick nothing that waits on work: it runs on the reads the turn has already made, before any subagent is spawned, and a failure anywhere in it blocks neither the sweep nor the spawns.

## 2. Spawn the work, and do not wait for it

Call `ListAgents` once. It answers **exactly one question**: is this loop still running.

**A loop whose subagent is still `running` is not spawned again.** That is the concurrency rule
and it has not moved.

**Every `idle` subagent is stopped at the HEAD of this tick, unconditionally** — `TaskStop` with
that loop's own name, before the cadence is read, before anything is spawned, and **whatever any
cadence says**. An idle agent is **not a corpse**: it is a resumable session holding its whole
transcript, and a send resumes it inside that context — measured twice in one session. Stopping it
is the only act that actually returns the context window, which is the operator's intent: a
finished run holds none. **Record each stop first** (below), then stop it; the listing that the
concurrency rule reads then carries **running runs only**.

**Record the finish before stopping it**, one line per loop, through the writer the tick log
already has:

```
bash ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/log-append.sh --tick <this tick's id>   --step loop-finish-<name> --status ok --summary "<name> finished"
```

It is written by the tick that **first observes the run idle** — the same tick that is about to
stop it — so there is no second walk and no new store. `log-append.sh` is idempotent per
`(tick, step)`, so observing the same idle agent twice in one tick writes one line.

**The cadence is read from that recorded finish, never from a live agent's `started` age**, which
is what used to make the idle agent load-bearing and force the reaping to wait for the next spawn:

```
bash ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/log-read.sh --step-prefix loop-finish-<name> --latest-tick
```

The tick id it answers **is** the finish time. A loop whose recorded finish is older than its
cadence is **due**; one younger is `not_due`. **No recorded finish means due** — a fresh session,
a first run, or a log this tick could not read, all of which must start the loop rather than
silence it. `started N ago` is read by nothing now, which also retires its stated cost: the
cadence measured the previous run's start **plus its whole duration**, so the fifteen-minute
`propose` loop respawned at ages of 21, 31 and 45 minutes.

| Name | Cadence | Preloads | Runs |
| ---- | ------- | -------- | ---- |
| `implement` | every tick | `workaholic:drive` | the **Unified Run**, unattended, with no prompt at any step |
| `propose` | `WORKAHOLIC_PROPOSE_CADENCE_MINUTES`, default **15** | `workaholic:propose`, `workaholic:specificate` | the strategy judgement, then ingest whatever is in the inbox |
| `moderate` | **30 minutes**, off its own tick log | `workaholic:moderate` | the maintenance tick |

`implement` carries no cadence because there is always more of its work to do and the claim
protocol already refuses what is taken. **`propose` carries one because its answer is a function
of what is queued**, and the queue moves only when `implement` lands something or a person
writes an ask — neither of which happens inside five minutes. `0` means every tick. What was
measured, and why a change-detector was refused: `workaholic:loops`, *The record behind the tick*.

Read claimable units with `bash ${CLAUDE_PLUGIN_ROOT}/skills/loops/scripts/claimable-units.sh` and
CPU facts with `bash ${CLAUDE_PLUGIN_ROOT}/skills/loops/scripts/read-machine-load.sh`. Spawn
`min(WORKAHOLIC_IMPLEMENT_FANOUT, claimable, bound − running)` implement runners; absent means one,
and `bad_fanout` or an unreadable claimable result falls back to one and is reported. Do not hand
a unit to a runner: each surveys and claims, and the claim arbiter settles any race.

**Both bounds are declared in `.claude/settings.json`'s `env` block**, beside `WORKAHOLIC_WIP_LIMIT`
and for its reason: a routine selects an account-level environment, so a per-repository number
lives in the repository rather than in a prompt. **`WORKAHOLIC_IMPLEMENT_FANOUT` absent means 1** —
the single runner — so a repository that declares nothing behaves exactly as it did before this
existed. A **non-numeric or non-positive** value is `bad_fanout`: it holds nothing, falls back to
1, and is reported by name, because a gate that cannot be read is not a gate. No default above 1
is picked here for any machine.

**`WORKAHOLIC_MAX_LOAD_PER_CORE` is the second bound on the same fan-out, and it is the machine's.**
Before each implement spawn **beyond the first**, when `read-machine-load.sh`'s `load_per_core`
already exceeds the declared ratio, **do not spawn another runner** and report the refusal by name:
`load_saturated: <load1>/<cores>` — the reading and the core count, the way every other refusal in
this loop is named rather than silent. The fan-out is therefore `min(declared bound, claimable
units, what the machine can carry)`.

- **Absent means no machine bound.** A repository that declares nothing is byte-identical to one
  before this existed, and no number is picked for any other machine: the operator who measured
  their own load average is the one who knows what it can carry. The ratio is **per core** so the
  same declaration means the same thing on a single-board computer and on a workstation.
- **The reading gates adding, never stopping.** No running unit is killed, paused or reaped for
  load — that throws away work in progress, the same mistake a too-eager staleness threshold makes.
- **The first runner is never refused.** A machine over its ratio with nothing running would
  otherwise stop the loop entirely, and a loop that will not start work because it is busy with no
  work is worse than the failure this cures.
- **A gate that cannot be read is not a gate.** `readable: false` holds nothing, the fan-out
  proceeds exactly as it would without this, and the reading is reported by its own reason
  (`no_loadavg`, `no_core_count`, `unparseable`). A non-numeric or non-positive declaration is
  `bad_load_ratio`, holding nothing and saying so.

Run ingest when this tick captured an ask even when the strategy cadence is closed. Defer the
strategy half only when its previous reported answer was `work_waiting`; lift that deferral after
an implementation lands and cap it at `WORKAHOLIC_PROPOSE_DEFER_MAX` (default 3).

Spawn each **due** one as `subagent_type: "general-purpose"`, in the **background**, under that
loop's own name. Give each the command body it answers to — `commands/propose.md` and
`commands/implement.md` are the ceilings for what those runs may post, and a subagent reads them
with the Read tool.

**`moderate`'s gate is read from its own tick log rather than from the listing**, because its
acts are hourly by nature and the log is a reader that already exists: run
`bash ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/log-read.sh --latest-tick` — which answers
that one timestamp and **carries no entries** — and spawn it only when the newest tick there is
**older than 30 minutes**. An empty `latest_tick` means *no such tick*, never *just now*. An unreadable log spawns it — over-reporting
beats a maintenance tick that silently stopped.

Then **end the turn**. Do not poll, do not await, do not summarise their work: their results
arrive as task notifications, and the next tick reports what landed. **A run's result reaches the
parent once**: the idle notification always arrives, so a subagent must not also be asked for a
summary message. The notification is the one that cannot be turned off, so it is the one that
stays. What was measured: `workaholic:loops`, *The record behind the tick*. A subagent tears down with
its own run; `/ship` and `/mission-close` already reap the claim worktrees they opened
(`cleanup-mission-worktree.sh`).

## 2b. The progress reading — start it, never wait for it

The tick says which loops it spawned; on its own that never says whether the work is
**moving**. `skills/loops/scripts/tick-progress.sh` answers that from readers this
repository already owns — per active mission the acceptance `checked/total`, the tickets
still queued against it, and whether anything has landed there at all; then the queue's own
total, how many missions carry queued work, and what the origination gate would therefore
answer next.

**Start it in the background and render the reading the PREVIOUS tick started.** It walks
every queued ticket through `read-relation.sh` and measured ~60s here — a tick that waits for
it is a tick that cannot answer a person for a minute, which is the one thing the cadence
exists to prevent. The cost is stated rather than hidden: the numbers a tick prints are up to
one tick old, and the render names when they were read.

It holds no cursor and no store, so a **trend** is the caller's to see: this tick's reading
beside the last one is what says *draining* or *stuck*. `draining` on a row is only the fact
that this mission's archive is non-empty.

## 3. Report, in one short block

- **The checkout**, when it is dirty: `checkout_dirty: <n> file(s)` and the one sentence that
  says what it means — the loop is running plugin behaviour that is on no base. A clean tree is
  not mentioned.
- **Per message**: `replied` / `reacted` / `swept` (with the issue URL, the receipt's reply and
  reaction each, and `direction:<slug>`) / `already_answered` / `skipped_own_post`, or the named
  degradation.
- **Per announced ask**: the issue and one of `announced` / `already_announced` /
  `thread_unresolved: <reason>` / `post_failed: <reason>` / `held: <reason>`. A tick with no
  candidate says `no_candidates`; a candidate read that failed says the reader's own reason and
  is never rendered as `no_candidates`.
- **Per loop, only when something happened**: `spawned`, or `reaped` when an idle agent was
  stopped. A loop that was `still_running` or `not_due` gets **no line** — the gate working is not
  news, and the majority of ticks are that. Where **every** loop was quiet, say so in one line
  (`loops: none due`) rather than three.
- **The allocation**: implement runners spawned, claimable units, declared bound, and `watching`
  when no runner was needed. Name `fanout_unreadable`, `bad_fanout`, and strategy deferral rather
  than rendering degraded inputs as a healthy zero.
- **The machine, beside the allocation and only when it has something to say**: a tick the machine
  held names the refusal, the load and the core count — `load_saturated: 7.99/4` — and a degraded
  reading is named by its reason and **never as headroom**: `the machine could not be read this
  tick (no_loadavg); the fan-out was not bounded by it`. **An unheld, readable machine adds no
  line**, because an unchanged answer restated every tick is what `📦 Release Preparation` was
  retired for, and a bound that fires silently is the failure this reading exists to end — a
  quieter loop must not be indistinguishable from a stopped one. The line carries **no identifier
  and no mention token** (it is a fact about the machine, addressed to nobody, and naming a unit
  would put a task on a line addressed to nobody), it says **what the machine was and whether it
  held the fan-out** and never what the tick would otherwise have spawned, and it **reaches Slack
  through nothing**: this is the tick's own run report, and the loop posts no status line about its
  own capacity.
- **Every reaping is named** — `reaped: <name>` — even on a tick that spawns nothing, because
  stopping a session is an act the tick took and the listing afterwards is the only other evidence.
- **The cadence's own source is named where a loop was skipped**: `not_due: <name> (finish
  recorded <age>)`, or `not_due: <name> (finish unrecorded — treated as due)` — which cannot occur,
  and saying so is how a later reader learns the absence means *due*. A log this tick **could not
  read** is named as unreadable (`cadence_unreadable: <reason>`) and the loop is spawned: a
  degraded read is never rendered as a healthy `not_due`, which is this loop's standing rule.
- **Progress**, from the reading that has landed: the queue total, then one line per active
  mission carrying queued work — acceptance `checked/total` and tickets left — and the
  origination gate's next answer with what has to clear for it to open. Name when the reading
  was taken. A reading that has not landed yet is named as pending, never rendered as zero.
- **Nothing else, and a tick that did nothing says one line.** A quiet channel, no candidate, no
  loop due and a clean checkout is `idle` and nothing further — the principle this plugin already
  holds one surface over (`/moderate`'s post gate makes an idle hour silent), applied to the tick's
  own report. What was measured: `workaholic:loops`, *The record behind the tick*.

Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or
guess retired namespaces.
