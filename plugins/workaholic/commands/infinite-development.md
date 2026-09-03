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
than the one it would cure. Measured 2026-09-03: an entire change — this command's own first
version, the retirement it performed, and the environment declaration beside it — sat
uncommitted in the loop's checkout across every tick of its first hour, driving the loop's
behaviour the whole time, and no step anywhere was looking at it.

## 1. The Slack turn — the steering surface

Read `WORKAHOLIC_INBOUND_SLACK_CHANNEL` (default the repository's own name) through the **Slack
connector** over the last `WORKAHOLIC_SLACK_TURN_WINDOW_MINUTES` (default 10, so consecutive
five-minute ticks overlap and nothing falls between them). This is the one place the loop reads
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

## 2. Spawn the work, and do not wait for it

Call `ListAgents` once. It is the whole record — no cursor, no lock file, no stored state — and
it answers every question below, because a finished subagent stays listed as **idle** carrying
the age it started at.

**A loop whose subagent is still `running` is not spawned again** — for `propose`, `ingest` and
`moderate`. **`implement` is the exception**: it fans out to a declared bound, and only its
`running` runners count against that bound (below).

**An `idle` one is a finished run, and it is reaped before anything is spawned** — `TaskStop`
with that loop's own name. Nothing is discarded: the run is over and its result already arrived
as a task notification. A tick that skips this leaves one corpse per tick in the very listing
the concurrency rule has to read, and the next spawn cannot even take its own name (measured
2026-09-03: three ticks, three idle `propose` agents, the third spawned as `propose-3`).

**An idle one is also this loop's own clock**, which is why it is reaped at the spawn and not at
the finish. `started N ago` is when that run began, so a loop with a cadence needs no timestamp
of its own: an idle agent **younger** than the cadence is left standing and the loop reports
`not_due`; an **older** one is reaped and respawned. Stated cost: the age is measured from the
start of the previous run rather than its finish, so a run that took four minutes is respawned
four minutes sooner than the cadence reads. Absent listing — a session just restarted — means
every loop is due.

| Name | How many, how often | Preloads | Runs |
| ---- | ------------------- | -------- | ---- |
| `implement-<n>` | every tick, **up to the fan-out** | `workaholic:drive` | the **Unified Run**, unattended, with no prompt at any step |
| `propose` | `WORKAHOLIC_PROPOSE_CADENCE_MINUTES`, default **15**, plus the deferral below | `workaholic:propose` | the strategy judgement |
| `ingest` | whenever §1 filed an issue this tick; otherwise the same cadence | `workaholic:specificate` | ingest whatever is in the inbox |
| `moderate` | **30 minutes**, off its own tick log | `workaholic:moderate` | the maintenance tick |

### The fan-out

**One agent per name capped `implement` at one whatever the queue held.** Measured over two hours:
54 tickets across 8 active missions, one runner by construction, about seven hours of serial
queue — adding capacity was not merely un-attempted, the concurrency rule forbade it.

Read how much independently claimable work there is:
`bash ${CLAUDE_PLUGIN_ROOT}/skills/loops/scripts/claimable-units.sh`. It composes
`plan-units.sh` — the executor's own survey, which partitions into PR-units, resolves ownership
and subtracts everything a claim holds — and derives nothing of its own. **Cost, measured and
stated rather than worked around**: 68–73 seconds on this machine, roughly a quarter of a
five-minute tick. A lighter count that the executor would then refuse is not a saving.

Spawn `min(WORKAHOLIC_IMPLEMENT_FANOUT, claimable, bound − running)` runners, each under its own
name (`implement-1`, `implement-2`, …). **Absent means 1** — the present single runner — so a
repository declaring nothing is byte-identical to one before this existed. A non-numeric or
non-positive value is `bad_fanout`: it holds nothing, falls back to 1, and is reported.

**No runner is handed a unit.** Each runs its own survey and claims what it can, and the claim
arbiter settles a race — since 2026-09-02 `claim.sh` wins one ref per claimed artifact before it
creates anything, so two runners that survey together cannot both take one unit and the loser
refuses `claim_race_lost` holding nothing. Assigning units at the tick would put a second
allocator beside `plan-units.sh`'s order, and a tick that names a unit is naming an identifier it
cannot see the state of. **Stated cost**: a losing race spends an agent run that produces nothing,
and that is the price of not assigning, bounded by the declared number.

**Only `running` runners count against the bound**, so a fan-out does not compound across ticks.
A degraded claimable reading — the survey was not `current`, was `shallow`, or read
`owner_unresolved` / `placeholder_identity` — yields **no fan-out**: one runner is spawned exactly
as before, and the reading is reported as `fanout_unreadable: <the reader's own word>`. A gate
that cannot be read is not a gate, and an allocation decided on a blind survey is worse than the
fixed one it replaces.

### The ingest half runs on the tick's own capture

`propose` bundled an event-driven half with a state-gated half behind one number, so a captured
ask waited up to fifteen minutes for a clock. They are split at the spawn: the **strategy
judgement** keeps the cadence, and the **ingest** is spawned whenever §1 filed at least one issue
this tick. It is keyed on the tick's own act — the count of issues §1 filed — and on nothing else:
no queue reading, no inbox poll, no change detector.

The ingest also keeps running on the cadence, because an ask a person files directly on GitHub is
one §1 never sees. The capture is an **additional** trigger, never a replacement. **When both run
in one tick the strategy judgement is spawned first**, so the issue it opens is in the inbox the
ingest reads — the ordering the merged routine bought, preserved.

### A runner whose last answer cannot have moved is skipped

The strategy half produced zero proposals on every run of a two-hour session, each time
re-deriving a gate whose inputs could not have moved: `work_waiting` clears only when `implement`
drains the queue.

Read the **previous strategy run's own reported refusal** from the tick log
(`bash ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/log-read.sh`) — the gate's last answer, never
a recomputation of it. When every direction was refused `work_waiting`, defer the strategy half.
Four bounds, each a refusal in its own right:

- **Lift it on the one event that can clear that refusal** — an `implement` run landed a unit
  since, which the tick learns from its own task notifications and from no queue reading.
- **Cap it.** After `WORKAHOLIC_PROPOSE_DEFER_MAX` skipped cadences (default **3**) the strategy
  half runs regardless. A brake with no ceiling is how the one routine that originates work stops
  silently, which this repository has measured twice.
- **Defer only on `work_waiting`.** `arrived`, `observing`, `past_target_date` and `not_active`
  each clear through a person's act that leaves no trace the tick reads, so a direction refused
  for one of those keeps walking on its cadence.
- **An unreadable log defers nothing** and is reported `cadence_unreadable`.

`survey-strategies.sh` is untouched and no gate is duplicated: what is read here is a previous
run's reported answer, not the ladder.

Spawn each **due** one as `subagent_type: "general-purpose"`, in the **background**, under that
loop's own name. Give each the command body it answers to — `commands/propose.md`,
`commands/specificate.md` and `commands/implement.md` are the ceilings for what those runs may
post, and a subagent reads them with the Read tool.

**`moderate`'s gate is read from its own tick log rather than from the listing**, because its
acts are hourly by nature and the log is a reader that already exists: run
`bash ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/log-read.sh` and spawn it only when the
newest tick there is **older than 30 minutes**. An unreadable log spawns it — over-reporting
beats a maintenance tick that silently stopped.

Then **end the turn**. Do not poll, do not await, do not summarise their work: their results
arrive as task notifications, and the next tick reports what landed. A subagent tears down with
its own run; `/ship` and `/mission-close` already reap the claim worktrees they opened
(`cleanup-mission-worktree.sh`).

## 3. Report, in one short block

- **The checkout**, when it is dirty: `checkout_dirty: <n> file(s)` and the one sentence that
  says what it means — the loop is running plugin behaviour that is on no base. A clean tree is
  not mentioned.
- **Per message**: `replied` / `reacted` / `swept` (with the issue URL, the receipt's reply and
  reaction each, and `direction:<slug>`) / `already_answered` / `skipped_own_post`, or the named
  degradation.
- **Per loop**: `spawned` / `still_running` / `not_due` (naming the age it read), each with
  `reaped` when an idle agent was stopped first.
- **The allocation, as one decision**: how many `implement` runners were spawned, out of how many
  claimable units, against what bound. A tick that spawned none because every runner was busy and
  nothing was captured reports **`watching`** with that reason — a decision the tick made, never
  silence, and never the residue of three gates all answering no.
- **The deferral by name** when the strategy half was skipped: the refusal it read and how many
  cadences it has been deferred.
- **Every reading that could not be made**, by its own word: `fanout_unreadable` (carrying the
  claimable reader's own reason), `bad_fanout`, `cadence_unreadable`. A degraded reading is never
  rendered as a healthy one.
- Nothing else. A tick that read a quiet channel and spawned nothing says exactly that — in **one
  line**. An allocation of zero is one line, not five.

Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or
guess retired namespaces.
