# The twenty-one-step contract — reference

Companion to [`../SKILL.md`](../SKILL.md). One section per step: what it reads, **what it may
write**, what it returns in `needs_agent`, and the reasons it aborts with. The step ids are the
tick log's keys and `run.sh`'s step list — they are stable, and a step is renamed only with its
log history in mind.

Every step returns one JSON line:

```json
{"step": "<id>", "status": "ok|filed|skipped|degraded|blocked", "reason": "<stable cause>",
 "summary": "<one line for the log>", "needs_agent": []}
```

`status` is the tick log's closed vocabulary. `reason` is free-form but **stable per cause**, so a
report can be read by grep: `not_implemented`, `budget`, `requested`, `step_missing`, `step_error`,
`no_output`, `bad_output`, `no_connector`, `no_credentials`, `no_strategies`, `unreadable_inbox`,
`quiet_hours`, `already_filed`.

**`needs_agent` is the seam between the script and the model.** A step script is non-interactive
and composes no prose: it probes, it decides, and where the action is mechanical it files through
an existing seam itself. Anything that needs *composition* (an issue body, a question, a proposal)
or a *human surface* (Slack) is returned here, and the agent acts on it afterwards through the
seam this file names for that step — recording what it actually did under the step id `<step>-filed`.

---

## 1. `open-log` — open the tick's log

- **Reads**: the layout allowlist; `.workaholic/moderations/`.
- **Writes**: nothing. The log line `run.sh` writes for it *is* the open.
- **Aborts**: `no_workaholic_dir` (nothing here to keep), `area_unregistered` (this checkout's
  plugin predates the area — the tick still runs, its log does not), `unwritable`.
- **Never**: creates the area behind the layout gate's back. A step that made its own directory
  would be routing around the gate rather than reporting it.

## The route a record takes to the base

A record the tick writes reaches the base **on the log's own commit** (2026-08-23).
`feedback/scripts/create.sh` stages a file and stops, and a routine's container is discarded, so
before this a finding the sweep or the triage wrote was reported filed and then lost.

```bash
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/persist-log.sh --tick <id> --record <repo-relative-path> [--record ...]
```

- **The same seam, widened by one argument.** No `work-*` branch, no claim, no pull request, no
  merge — exactly how the log itself travels, and every heavy prohibition is unmoved.
- **Scoped to the tick's own records**, named one by one. Never a sweep of whatever is staged: that
  would let an unrelated container file ride an unattended commit to the base, which is the one
  thing this seam must never become.
- **A record already on the base is left untouched** — a feedback record is immutable by its own
  skill's rule — so "already there" is success and two concurrent ticks both land.
- The report names each record's state: `carried`, `already_on_base`, `missing`, `unreadable`.

**A `<step>-filed` line proves nothing on its own.** Measured: the persist reported both records
`filed` and `persisted` and the log reached the base, while the base carried the log section and
**not one record** — and the next tick read those lines, concluded both findings were captured, and
did not re-derive them. The dedup keyed on a *claim* rather than on the artifact the claim names.

```bash
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/filed-records.sh --step <step-slug> [--root <repo-root>]
```

It reads the paths a `<step>-filed` line names and asks the tree whether they are there: `landed`
dedups, **`unlanded` is treated as not filed so the next tick re-derives the finding**. A container
is a fresh clone of the base, so present-in-the-tree is on-the-base. **`readable: false` is not an
empty set** — a caller must not read "could not look" as "nothing was filed", which is the same
conflation. The writer's half of the contract: a `<step>-filed` summary **names the repo-relative
path** of each artifact it filed; a line naming none proves nothing and is not honoured.

The log stays append-only throughout: nothing rewrites a line already on the base, and what changed
is only what a line is allowed to prove.

## 2. `inbound-sweep` — Gmail, Drive, Slack and GitHub

- **Reads**: GitHub itself, through `gather/scripts/gh-rest.sh` — repository-scoped, `since`-filtered,
  pull requests dropped (they share the issue numbering space, and a sweep that kept them would
  re-file the loop's own work). Slack, Gmail and Drive are **connectors held by the session, not by
  the script**, so they come back in `needs_agent` as `probe_connector` entries carrying the bound
  each is read under.
- **The window is the last sweep, not a clock**: `--since` defaults to the previous tick that
  recorded an `inbound-sweep` line, read out of the tick log; with no such tick, this tick's own UTC
  day start. Anchoring to a fact in the log avoids `date -d`/`date -v`, which differ between the
  developer's laptop and the routine's container.
- **Writes**: nothing. The agent applies the **materiality bar** — a genuine problem or improvement
  idea, or something that must not be overlooked; a passing remark is not filed — and writes what
  passes as a **feedback record** (`feedback/scripts/create.sh`, `--subject` naming *whose* opinion
  it is: `person:<them>` for a message someone wrote, `observer_ai:<identity>` for what the tick
  noticed itself, **never** defaulted to the runner). What it filed is recorded as
  `inbound-sweep-filed`, which the next tick's dedup reads.
- **It does not open a GitHub issue** (resolved 2026-08-17, the ticket's first Open Decision). The
  crossing flow is gated on a verbatim human confirmation an unattended tick cannot give, and a
  self-filed *assigned* issue would be re-discovered by `[Specificate]` every hour forever — a record
  written before the issue can never name it, which is the measured reason issue #443's auto-file
  option was refused on 2026-08-14.
- **Quoting rule: pointer and subject line only** (resolved 2026-08-17, the second Open Decision).
  A candidate carries its surface, a stable identifier or permalink, and the title as written —
  never a message body, an attachment, or a Drive file's contents. `.workaholic/` history is durable
  and the leak scan matches only a hand-maintained denylist, so a `pass` there never means "no
  sensitive content"; a pointer leaves the content behind its own access controls.
- **Slack's bound is not advice**: exact-string search, at most two queries, **no channel history
  read at any point** (`workaholic:notify`).
- **Aborts**: `gh_unavailable` (GitHub named as unreadable while the three connector surfaces are
  still handed over — three of four working is not "nothing found").
- **Dedup**: an issue a feedback record already names, or one an earlier tick logged under
  `inbound-sweep-filed`, is skipped and counted in the summary.

## 3. `workload-logs` — environments whose credentials are here

- **Reads**: `.workaholic/deployments/*.md`. A target declares its log source with the optional,
  **non-secret** frontmatter locator `log_locator:` (a URL, endpoint or command *template*,
  alongside the existing `url` / `endpoint` / `command`) and, when reading it needs a credential,
  `log_credential_env:` — the NAME of an environment variable, never its value.
- **It runs nothing** (decided 2026-08-17). A deployment record already carries executable prose,
  and `/ship` runs it **only on the developer's instruction** (§5-D). An hourly unattended tick that
  executed a repository-declared command would move that boundary quietly — arbitrary code out of a
  file, every hour, with nobody watching. The step resolves *which* targets are readable *here* and
  hands them to the agent, which reads them with the tools the session actually has.
- **Writes**: nothing directly; a finding becomes a feedback record exactly as step 2's does, under
  the same pointer-only quoting rule (the failing signal, never a log body, never a credential).
- **Aborts**: `no_targets` (no deployment records), `no_log_source` (records exist, none declares a
  locator this environment can read). **`no_credentials` is a checked claim**: it is reported per
  target only after the named variable was looked for and found absent, and the report names the
  variable — never "probably missing credentials".

## 4. `merge-conflicts` — pull requests whose merge is blocked

- **Reads**: open pull requests through `pulls-state.sh`, the one reader steps 4 and 6 share.
  Mergeability lives only on the single-pull endpoint, so the per-pull reads are bounded by
  `--limit` (default 10) and the cap is **reported** — a busy repository is never silently
  half-read. GitHub's lazily-computed `mergeable: null` is `unknown`, never `clean`.
- **Writes**: **nothing to any branch, and no post of its own.** The finding rides step 6's
  reminder; two Slack lines about one pull request in one tick is the noise a gated post exists
  to prevent.
- **It does not rebase** (resolved 2026-08-17, the ticket's Open Decision). A `work-*` branch
  **is** a claim — the heartbeat is its tip and `archive.sh` pushes it after each archive commit —
  so a third party rebasing it races the claim holder's own pushes and can strand or duplicate a
  unit; it is one of the three unit-less writer designs `workaholic:ship` §7 measured and refused.
  Rebasing only *unclaimed* branches would need a staleness rule the claim protocol deliberately
  refuses to have (it reports staleness and never acts on it), and rebasing anything accepts the
  race knowingly. The drive loop already assigns this repair to its owner: a merge-conflict notice
  tells the **claim holder** to resolve it, which is the person who knows which side keeps its
  behaviour.
- **Aborts**: `gh_unavailable` — conflict state unknown is reported as unknown.

## 5. `issue-triage` — stale issues, and GitHub↔`.workaholic/` drift

- **Reads**: open issues over REST (oldest-updated first); `.workaholic/tickets/archive/`,
  `stories/`, `feedbacks/`.
- **Three mechanical facts, no verdicts**: `landed_but_open` (an open issue an archived ticket or
  a story names — the work landed), `never_ingested` (an open issue no feedback record names —
  `[Specificate]` only takes issues assigned to the running identity, so someone else's issue lands
  here legitimately), and `oldest` (the least recently updated, with dates, for the agent to judge
  staleness against).
- **Writes**: nothing. **It closes nothing and merges nothing** — an issue is somebody's words,
  and a machine that closed them hourly would be deciding what the project heard. Consolidation is
  a judgement: propose it, never perform it. "Remove" is never delete; the repository's history is
  the durable record.
- **Aborts**: `gh_unavailable`.

## 6. `stuck-prs` — what failed to auto-merge, and what it needs

- **Reads**: `pulls-state.sh`, as step 4 does — resolved once per tick, used twice.
- **Every row names the decision, not the colour**: `conflict` → the claim holder must resolve it
  and nobody else may push to that branch; `review` → a required review or gate is unsatisfied;
  `checks` → the author must fix a failing check or say it is expected; `draft` → mark it ready or
  close it; `behind` → the claim holder must update it; `unknown` → GitHub has not computed
  mergeability yet, re-read before acting.
- **The heading names the kind, the key does not move** (2026-08-18, issue #513). `headline` is
  derived from the same `blocked_by` set — `conflicting with main`, `waiting on review`, `with a
  failing check`, `still in draft`, `behind main`, `with mergeability not yet computed`, and
  `stuck: <kind>, <kind>` when one post covers several — and the `🔧` post's first line carries it,
  so a conflict finding and an un-run auto-merge no longer share a heading. It is **wording only**:
  the digest, the two gates and the post's frequency are untouched.
- **One reminder per distinct state.** The key is `stuck:<digest>` over the sorted
  `<number>:<blocked_by>` set, so an unchanged answer is never repeated while a new pull request or
  a changed reason earns a post. **Two gates, both required**: something actionable, and no earlier
  post for this exact state — the tick log answers the second, and `workaholic:notify`'s stateless
  lookup answers it again on the wire. The key is deliberately distinct from `[Prepare Release]`'s
  `deploy:<digest>`: one reports what is waiting to deploy, this what is waiting on a human, and a
  shared key would let either dedup the other away.
- **Aborts**: `gh_unavailable`. Already-posted state is `ok`/`already_filed`, not a second post.

## 7. `doc-drift` — the documentation against the current concept

- **Reads**: `story/scripts/doc-drift.sh` (structural presence changes versus the documents that
  enumerate them) and `story/scripts/area-freshness.sh` (a hand-maintained record naming something
  this repository retired). Reused, not re-implemented.
- **The window is a git question**: the base is `git rev-list -1 --before=<the previous doc-drift
  tick, as ISO> HEAD`, so no `date -d`/`date -v` arithmetic is involved. `no_baseline` when nothing
  precedes that boundary — comparing against nothing would report every document as drifted.
- **Writes**: nothing. Drift becomes a **ticket**, because fixing documentation is work and work
  has a queue; an hourly agent rewriting `main`'s documents is the unattended-write class this
  project has refused twice.
- **Dedup is not optional here.** `terms/retired-terms.md` is a glossary *of* retired terms, so it
  names retired terms by construction and `area-freshness.sh` reports it truthfully and forever.
  A finding an earlier tick logged under `doc-drift-filed` is counted and dropped.
- **Aborts**: `no_repo`, `no_baseline`, `drift_unreadable`.

## 8. `release-status` — what is waiting to reach a deployment target

**Inputs**: `ship/scripts/report-deploy-status.sh`, which freshens the base branch and tags
before deriving the boundary from them and reports `refs: fresh|stale|skipped`.

**May write**: nothing. This is a read.

**Where it came from**: the `[Prepare Release]` routine, merged into this tick on 2026-08-19.
The question it answers — what has landed and not shipped, and on whom that waits — is the
same question the rest of this tick asks about the repository's progress, so it stopped being
a routine of its own.

**It posts nothing.** The retired routine's `📦 Release Preparation` root did not come with
it. Measured on `#dev-workaholic` the same day: ten `📦` lines in ten consecutive hours for
one unchanged request, the count rising 10 → 12 → 14 → 16 → 18 → 22 → 30, none answered by
anyone. Its two gates (`deploy:<digest>` and `deploy-day:<day_token>`) worked exactly as
designed and were beside the point — **a status line addressed to nobody is noise at any
frequency**. What is worth a person's attention becomes a question at step 10, addressed to
somebody, with the options named; what is not stays in the log.

**Abort reasons**: `reader_missing` (the script is not in this checkout), the reader's own
`reason` when it could not read, and `doubtful` — the boundary was derived from refs the
reader could not freshen, so **the count is withheld rather than rendered**. Two containers
holding different stale refs would otherwise report two different truths about one base.

## 9. `note-cadence` — where each target's draft release note stands

**Inputs**: `ship/scripts/run-note-cadence.sh`, **without `--write`**.

**May write**: nothing, and not by convention — by construction. `--write` is passed by the
`Release Note Draft` GitHub workflow and by nothing else. A routine's container cannot write
a release at all (`gh release` is refused as GraphQL; REST answers *"Creating, editing, or
deleting releases is not permitted for this session type"*), which is why the 2026-08-17
design that put the write on a tick failed on every tick until it was corrected.

**It posts nothing**, for the same reason as step 8.

**Abort reasons**: `reader_missing`, and the reader's own `reason` when the cadence could not
be read.


## 10. `strategy-pace` — a direction that will not arrive, said to its owner

```bash
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/step-strategy-pace.sh --tick <id> [--root <repo-root>]
```

Reads `propose/scripts/survey-strategies.sh` — a pure read of the same script `/propose` uses,
with no stored state and no second derivation — and returns every surveyed strategy whose `pace`
is `late`: nothing landed over a period as long as the one that remains
(`workaholic:propose`, *Pace: the one reading that is not a brake*).

**It reads `eligible` and `refused` both.** A direction that will not arrive *and* is gated
produces no proposal at all, and that is exactly the case that starves — a consumer reading only
the eligible rows would never see it.

**It asks; it never proposes and never lifts a gate.** A late direction that is `work_waiting`
stays `work_waiting`: the answer to *the work is in flight but not moving* is a person, not
another proposal. The candidate goes to step 11 as `needs_agent`, one question per strategy,
addressed to its assignee.

**`unknown` is not asked about.** A pace that could not be read is counted in the summary and
nothing else — spending a person's attention on our own degradation is not a question.

**Why this step and not `/propose`'s own report** (the ticket's Open Decision, ruled while
driving it): an hourly routine's run report is read by whoever opens the session, which on the
day it matters is nobody — measured with `over_cap`, which named itself on every single tick and
still hid a day of starvation. Carrying the reading on the proposal issue was refused for the
opposite reason: it says nothing precisely when the direction is gated.

A survey that refuses, or a missing script, is `degraded` with the reason named — never an `ok`
step that found nothing.

## 11. `stalled-units` — what is claimed, and how long it has not moved

```bash
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/step-stalled-units.sh --tick <id> [--root <repo-root>]
```

Reads `drive/scripts/list-claims.sh` — the claim oracle, a pure read over unmerged remote
branches — and returns, per claimed unit: the unit, its branch, **who holds it**, **how many hours
since the branch last moved**, and **whether it ever reached a pull request**.

**Why the step exists** (2026-08-23, issue #584): a consuming repository's loop stopped for eleven
consecutive ticks. Every tick ran, reported `blocked` correctly, and spent agent-hours; the only
outbound signal was a mention-less reply in a feedback thread from the previous day, so Slack
notified nobody. `/implement` cannot ask — no `AskUserQuestion` anywhere, at any step — and this
tick's check-in, the one surface here that names a person, asked only about what its own steps had
found. **No step read the state of claimed work**, so the surface that could ask never learned
there was anything to ask about.

**The coupling is a reader, not a handoff** — the same shape as `strategy-pace`. A `/implement`
run's container is discarded and it writes nothing into the tree about its own blockers, so it
could not hand anything over; this step calls the oracle itself. Two readers of one script is not
two sources of truth.

**The age comes from the claim branch tip and nowhere else.** The heartbeat already advances that
tip, so the protocol already records when a unit last moved; a second notion of last activity
would give the claim protocol two clocks. It is computed with `date`, not jq's
`fromdateiso8601` — the oracle emits git's `%cI`, which carries the committing machine's offset,
and parsing those in jq reported five of seven live claims as *unknown age* on this step's first
run.

**It reports every claim and narrows only what it asks about.** The summary counts every claimed
unit whatever its age; the `needs_agent` candidates are the **stale** ones, and the narrowing is
visible in the same line as the total.

**The threshold is the claim protocol's own `stale`** — `WORKAHOLIC_CLAIM_STALE_HOURS`, default 24
— and none of the three the ticket offered (ruled 2026-08-23 while driving it). `lib/claims.sh`
already decides when a claim branch has not moved long enough that a human should look, and states
the meaning in the words this step needs: *a tip older than the threshold says "look at this", not
"take it"*. Asking a person to look **is** that. A fixed tick count was refused for inventing an
arbitrary constant beside a justified one; a working-day boundary for making a unit that stalls at
09:05 wait nearly a full day, when the measured failure *was* a day of silence — `stale` has that
option's shape without its cliff, and the working-week half of it survives downstream, in step 13's
own weekend hold; two-ticks-plus-an-open-decision for naming one blocker class when a missing
credential stalls a unit exactly as hard.

**It asks; it never claims, drives or resolves.** The candidate goes to step 13 as `needs_agent`,
keyed `stalled-unit:<unit>` — stable across ticks, which is what lets `ask-question.sh`'s ledger
ask exactly once — with the claim holder's email to address it to. Nothing here touches a claim.

**A `superseded` claim is a fact, not a question** (2026-08-26). Its work already reached the
base, so there is nothing for a person to look at and nothing for them to decide; it is counted
in the summary as a finding and never reaches the question set. The cost of getting this wrong is
not neutral: the asked-once ledger means the one *real* stalled unit then arrives inside a stream
a person has learned to skip. Measured — three merged pull requests were each being asked about.
The keying is untouched: `stalled-unit:<unit>` still keys a genuine stall, and only which rows
reach it moved.

**The summary carries no age, and that is a correctness requirement** (same change). The root
calls a step changed when its summary differs from the same step's an hour ago, and
`render-tick-post.sh` normalises out a timestamp, a bare hex object name and a clock time — and
**only** those. `oldest stopped 27h` increments every tick, so it made this step changed *hourly
by construction* and the root restated the same stalled units four times in one day: the shape
`📦 Release Preparation` was retired for. The age is still computed and still reaches the person,
in the question that names the unit; the `event` carries none either, for the same reason.

**`🔴 Blocked` and `↳ still failing` are unchanged**, and that is the decision rather than an
omission: they are the run's record of an outcome, and this question is a demand on a person's
attention. Making the record louder is the direction this repository has retired twice — the
failure was never volume, it was that nothing addressed anybody.

**`has_pull_request` is offline.** It is the claim oracle's own `reported` field, derived from the
story file `/story` commits when it opens the pull request, so a tick with no GitHub reach still
answers. That field was hoisted onto every claim row in the same change: it had been consulted
only where the resumable verdict forked, so `queue_drained` — the commonest state of a
finished-but-unmerged unit — short-circuited before it and a reader could not tell a unit parked at
a pull request from one that never opened any.

**A degraded read is named, never rendered as calm.** `origin_unreachable` (`fetched: false`) means
the only claim oracle could not be reached — not that nothing is stalled; `shallow_history` means a
merged unit is indistinguishable from a held one. A missing or unparseable reader is `degraded`
with its reason.

It posts nothing itself and touches no claim: the post is step 13's, through the `🙋 <@U…>` shape
that already names a person, rides the tick's own thread, carries the session URL and is asked
once.

## 12. `closable-missions` — finished, and still open

```bash
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/step-closable-missions.sh --tick <id> [--root <repo-root>]
```

`archive.sh` closes a mission `achieved` when it archives the mission's **last** ticket. That seam
cannot catch a mission that reached full acceptance any other way — items ticked by a different
seam, tickets archived before the seam shipped, a branch that never ran the gate. **Eleven such
missions had accumulated and nobody was told**; they were found because the mission lens — the
always-on hook retired on 2026-08-26, once this step owned the job — printed all of them on every
prompt and the list had grown long enough to read as wrong. This step makes the residue legible
before it is large.

- **Reads**: three **pure** readers — `summary.sh` (the active set with its `checked`/`total`),
  `progress.sh` (`unlinked`) and `queue-size.sh` (the queue count, which is the reader
  `plan-units.sh` itself uses for that number). No new parser of the many-valued `mission:`
  relation, which `read-relation.sh` owns.
- **`plan-units.sh` was the obvious composition and is refused**: its `queue_drained` exclusion is
  exactly this candidate set, but the survey runs the living migrations and **stages** what they
  change — measured by this step's own test, which caught the report leaving a modified mission in
  the index. A step whose contract is *writes nothing* may not reach it through something that
  writes.
- **Writes**: nothing in the step script — the step stays the pure read it was; what changed on
  2026-08-24 is what the agent does with its report (below).
- **Reports** each entry with the two facts that make it closable, `checked/total` and the queued
  count, and nothing else.

**The tick closes what the step proved** (2026-08-24, the developer's ruling, reversing the
2026-08-23 report-only stance — its reasoning is answered, not dropped). The old rule was *two
writers of an end state is what the single-writer rule exists to prevent*; the answer is that the
single **writer** never multiplied — every close still goes through `mission/scripts/close.sh`,
and what multiplied is the *proof sites*, which was already true the day the archive gate shipped.
The proof is the same arithmetic the archive gate runs (`checked == total`, `unlinked == 0`,
`todo == 0`), the verdict is always `achieved` and never an intent word, and the measured cost of
report-only was eleven finished missions accumulating while a question about them was asked and
re-asked — the developer's ruling is that a proof this mechanical needs no human turn. The agent
acts on the step's `needs_agent`: for each candidate it re-proves through the same three readers
in a **publish tree**, runs `close.sh <slug> achieved` there, and lands the closes through
`publish-tree-pr.sh` (the ordinary auto-merge proposal path — a scan finding leaves it open). A
candidate the re-proof rejects is reported, never closed; `abandoned` and `carried` stay
`/mission-close`'s alone.

**Why this tick and not `/story`** (ruled 2026-08-23 while driving it; the ticket required the home
to be decided and recorded). `story/scripts/area-freshness.sh` is the exact precedent for a
reporting-only upkeep seam and was the other candidate. This tick wins on audience and on shape:
the residue accumulates over **time** rather than at a merge, so a per-merge report names it only
when somebody happens to merge something unrelated — which is how eleven went unseen; closing a
mission is the operator's act and this is the surface that reaches an operator hourly with a dated
log; and it is silent by construction when the set is empty, because it contributes a report line
and never a question.

A survey that could not be read, or a backlog it could not read, is `degraded` **by name** — it has
not found "nothing waiting to be closed", it has found nothing at all. A mission whose progress
cannot be read is skipped rather than reported closable, and the scanned count says the rest.

### A question has three states, and an answer is one of them

```bash
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/record-answer.sh --tick <id> --key <content-key> --answer "<their words>" [--root <repo-root>]
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/question-state.sh --key <content-key> [--root <repo-root>]
```

The developer's flow ends where the plugin had nothing (2026-08-23, issue #584): they open the
session link on the question and answer **inside the moderator's own session**. The tick had no
notion of an answer — `ask-question.sh` recorded that a key *was asked* and refused to ask it
again, and nothing recorded that it was *answered* — so an answered question and one nobody will
ever answer were the same state, and the person's words died with the container. That is the same
shape as the defect that made the tick's own feedback records evaporate.

| State | In the log |
| --- | --- |
| `never_asked` | no `human-checkin-ask-<slug>` line |
| `asked` | that line, and no answer beside it |
| `answered` | `human-checkin-answered-<slug>`, whose **summary is the person's words** |

**No new store.** The answer rides `log-append.sh` — the log's only writer, append-only,
idempotent per (tick, step) — and `persist-log.sh` carries it to the base with no branch and no
claim, exactly as it carries every other line. Recording twice in one tick is a no-op; a
correction in a later tick appends its own line and the reader takes the newest, so nothing on the
base is ever rewritten and both remain as the audit trail.

**One derivation of the id**, in `lib/question-id.sh`, sourced by the gate, the writer and the
reader: a question whose id differed between them would silently be a different question, and an
answer filed under one id would never clear a gate reading another.

**`answered` is its own refusal at the gate**, not a kind of `already_asked`. Both refuse and
neither holds, so volume behaviour is unchanged — but the caller, the run report and the log can
now tell *a person resolved this* from *nobody ever will*, and the refusal carries the words so the
next run can act on them. **Nothing parses the answer**: it is a person's prose, and acting on it
stays the next run's judgement. What this owes is that the words survive and are found.

**An empty answer is refused** (`no_answer`) rather than recorded: "answered with nothing" is
indistinguishable from a mis-click, and it would clear the gate on a question still open. A missing
log reads `never_asked` — a repository with no tick history has asked nothing — while a log that
exists and cannot be read is `unreadable`, named, because only one of those is calm.

### An outstanding question is asked once more, and only once

```bash
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/question-liveness.sh --key <content-key> --step <owning-step-id> --run <run-report.json|->
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/ask-question.sh ... --run <run-report.json> --asked-step <owning-step-id>
```

The gate could not tell **asked and settled** from **asked and still blocking**: it read one fact,
was this key asked before, and refused. Measured: a question saying the loop could not start went
unanswered for twenty hours across twenty ticks, every tick reporting itself healthy, with no
surface anywhere carrying its age.

**Liveness is re-derived, never stored** (the ticket's step 3, ruled here): the owning step ran
this tick, so its `needs_agent` *is* the set of subjects still live. `question-liveness.sh` reads
the tick's own run report and answers `live` / `settled` / `unknown`. No log field, nothing to keep
in sync, no append-only line rewritten, and **no repository scan** — re-reading the tree per asked
key is what turns an hourly tick into a scan. The owning step is an **argument**, not a guess from
the key's prefix: `stalled-unit:` is not the step id `stalled-units`, and a wrong guess would answer
`settled` about a subject nobody looked at. **`unknown` is load-bearing** — a step that degraded or
was never reached cannot report its finding, and treating that as `settled` re-creates the exact
silence this exists to end.

**The shape, ruled: (a) re-ask on persistence, bounded — not (b) a standing outstanding line.** The
ask named both and declined to recommend one. The one property both retired status roots lacked is
being **addressed to a person**, and (b) — `N questions outstanding, oldest <age>` on the root —
reproduces exactly that lack; putting an age on a line addressed to nobody does not change who it
reaches. Only a mentioned reply reaches anybody, and the measured harm was twenty hours with
nothing carrying the question at all.

**The interval is the smallest that answers the measurement**: one re-ask, at the **next working
day**, then never. Ticket `20260819061902` removed *unbounded* re-asking and that removal stands —
this is at most one extra ask, ever, logged under its own step id
(`human-checkin-reasked-<slug>`) so a third is impossible by construction. The boundary is the
working day the quiet-hours gate already owns, so no constant is invented. The day is read from the
**tick id**, not the wall clock, so a re-entered tick answers the same way twice.

**Only a `live` subject is re-asked.** `unknown` is a reading that could not be made, and spending a
person's attention on our own degradation is the rule `strategy-pace` already applies to its own
`unknown`.

**A `settled` subject is confirmed where it was asked — once** (2026-08-24, the developer's
instruction: *if it is resolved, moderate should catch that and signal it in the thread*). A
question with state `asked` (never `answered` — the person already knows) whose liveness reads
`settled` this tick gets **one reply into the thread that asked it**:

```
✅ 解消を確認 - <the question's subject, one line>
<one sentence: what the tick measured that says it settled>
```

The thread is found the way every reply thread is found (`workaholic:notify`'s exact-string
search over the question's own first line, at most two queries, never a similarity match); a
lookup that finds no thread posts nothing and reports `thread_not_found` — a confirmation in the
wrong thread is worse than none. It is logged under `human-checkin-confirmed-<slug>` so a second
confirmation is impossible by construction, it carries **no mention token** (it closes a loop
rather than demanding attention), and it is exempt from nothing: the off-day and quiet-hours
holds apply, held is not dropped. An `answered` question is never confirmed — the person's own
words already closed it — and `unknown` never confirms, for the reason above.

**The hold gates come first.** `already_asked` returns before the off-day and quiet-hours checks, so
a re-ask decided there would post at 03:00 on a Sunday. It is gated on both, and held is not
dropped: the re-ask is logged only when actually asked, so it waits for the next eligible tick and
is still bounded to one.

**It adds no posting rule and no new shape.** A re-ask is a question, so it rides the existing
"post when there is at least one question" gate — an hour with nothing to ask stays silent by
construction — and it goes out as the same `🙋 <@U…>` reply, with its age in the question's own
sentence (`first_asked` rides the gate's answer). The root's wording does not move, so the copy in
`notify/reference/notifications.md` and the routine template stay byte-identical.

## 13. `human-checkin` — the tick's voice: one root, up to five questions inside it

- **Reads**: the tick log (held questions, what was already asked today) and the clock in the
  workspace's timezone.
- **Writes**: nothing to the repository. Questions are **Slack posts** — a routine-fired session
  has no `AskUserQuestion`, and this skill's standing rule forbids one anyway.
- **The script is the gate and the ledger; the agent composes and posts.** *Which* items are worth
  asking is a judgement (`rules/interaction.md`'s Recommended-label test: an item you could
  honestly mark "(Recommended)" is decided and recorded, never asked). *How many*, *when*, and
  *was this asked before* are mechanical, and live in `ask-question.sh`, which answers
  `ask: true|false` and hands back the `log_step` to record the ask under.
- **Five gates, each its own refusal**: `off_day` (the working-week gate, `WORKAHOLIC_WORK_DAYS`, default `1-5`), `quiet_hours`, `already_asked`, `tick_cap` (5), `day_cap`
  (10 — the bound the per-tick cap must not aggregate past; five an hour is 120 a day at the
  ceiling, and the cap alone protects nobody's attention).
- **`day_cap` counts *today*, and a spent day holds** (2026-08-28, mission
  `deliver-what-the-loop-already-knows-to-the-person-who-can-act`). It counts the
  `human-checkin-ask` lines on the current **`WORKAHOLIC_QUIET_TZ` day** — derived once in
  `ask-question.sh`, from the tick id where there is one, and passed to `log-read.sh`'s
  existing `--since`, so the loop has one notion of a day and there is no second reader and
  no cursor. A spent cap **holds** rather than drops, and a held question is **re-offered on
  the next eligible tick, oldest-held first**.

  It counted every day the log had ever held: `asked_today` was the unbounded prefix count,
  the log is append-only and never pruned, so once the all-time total crossed `max_per_day`
  every question was refused `day_cap` forever. Measured — `count: 12, days: 5` against a cap
  of 10, a fresh key at 14:00 on a working weekday refused with `asked_today: 12`, the same
  reader bounded to the current day answering `count: 0`, and eight consecutive ticks
  reporting `ok` while posting nothing. **The repair was a bound passed to a reader that
  already accepted one** — not a raised cap, not a second reader, not a stored cursor, not a
  second notion of a day. The `outstanding` re-ask branch printed that same unbounded number
  into **both** `asked_this_tick` and `asked_today`; they are now the tick count and the
  day-bounded count.

  **The day boundary moves in `WORKAHOLIC_QUIET_TZ` while the log's *files* are keyed by UTC
  day**, so near the boundary the bound can include a UTC file whose later entries belong to
  the local next day. That **over-counts rather than under-counts** — it holds a question
  rather than asking a duplicate — which is the safe direction. Stated rather than repaired
  with per-entry timestamp filtering, so a later reader does not fix it the other way.
- **Quiet hours: one gate per tick, in the workspace's timezone** (resolved 2026-08-17), default
  `Asia/Tokyo` 22:00–08:00, both overridable (`WORKAHOLIC_QUIET_TZ`, `WORKAHOLIC_QUIET_HOURS`).
  The per-recipient alternative — each addressee's Slack profile timezone — is more precise and
  was not taken: it costs a profile read per person per tick against a surface this project keeps
  to exact-string queries, and it buys little, because a suppressed question is **held, not
  dropped**. The gate is one function reading one zone, so it stays swappable.
- **Held is not dropped**: a suppressed question is recorded as `human-checkin-held-<slug>` and
  handed back by this step on the next eligible tick; it drops out once it has been asked.
- **And the arrears come back oldest-held first** (2026-08-28, the same mission). The held set
  was collected with `sort -u` — alphabetical, an arbitrary order over a set whose only
  meaningful axis is age — which had never mattered while the day cap was jammed and nothing
  drained. `held` is ordered by the day each key was **first** held (a key held across several
  ticks is as old as its first hold), tie-broken on the tick id within the day and then on the
  key, so the order is total and a re-entered tick produces a byte-identical sequence. The day
  is already in the log this tick keeps, so this adds **no second ledger, no cursor and no
  field on any artifact**.

  **The step orders; it neither caps nor asks.** `max_per_tick` is enforced per candidate by
  `ask-question.sh`, `held_count` counts the **whole** held set rather than the ordered prefix
  (the count is what tells a reader how deep the arrears are), and the order is a **proposal**
  to the agent: the Recommended-label test still applies per candidate, so an older question
  that is no longer worth asking is dropped by judgement rather than asked because it sorted
  first. **Age, not urgency** — a severity ranking across the step vocabularies is a judgement
  no script can make, and the verdicts call for different acts by different people, which is
  why one unified "what the loop is blocked on" report was refused. The day grain is coarse
  (a whole day's holds sort together); the tick id is already the tie-break and carries
  `HHMMSS` if a finer grain is ever wanted.
- **It reports what it delivered, not what it was permitted to** (2026-08-28, the same
  mission). The summary read `up to 5 questions may be asked this tick; 22 held from an
  earlier tick` with `status: ok` — a **permission**, equally true of a tick that asked five
  and a tick that asked none, so eight consecutive delivering-nothing ticks were
  indistinguishable from eight healthy ones in the only record that survives the container.
  The step now reports `delivered`, `held_count` and `candidates`, and names why a tick
  delivered nothing:

  | `delivery` | Means |
  | ---------- | ----- |
  | `cap_spent` | `max_per_day` questions were asked **on this day**. The mechanism worked; the budget is spent and the rest are held |
  | `cap_unbounded` | the day count could not be bounded. **Our own degradation** — never rendered as `cap_spent`, which is the whole point of the split: one says the budget worked, the other says the loop has stopped |
  | `all_held` | every candidate is refused by `quiet_hours`, `off_day` or `tick_cap` |
  | `all_asked_before` | every key that was ever held has since been asked |
  | `no_candidates` | the genuinely quiet hour |

  **Whether the tick could deliver is asked of the gate, not re-derived here**: one
  `ask-question.sh` probe with a key unique to the tick, recorded nowhere, so the day's
  arithmetic keeps one home and this step cannot disagree with the gate the agent is about to
  run. **`ask-question.sh` is not modified by the reading.**

  **What `delivered` honestly is.** The agent asks and records under `human-checkin-ask-<slug>`
  *after* `run.sh` returns, and **there is no post-agent seam in `run.sh`** to move the reading
  to — the agent's turn happens after the run and only `persist-log.sh` is re-invoked. So the
  reading is *candidates and holds now, delivery from the log*: on the step's own pass
  `delivered` is zero by construction, and the reason words are the ones the step can
  **observe** — the caps and the holds — never a prediction of the agent's judgement. It is
  read from the log rather than assumed precisely so a second, read-only invocation after the
  agent's turn reports the real number.

  **A degraded read is named, never rendered as a delivery**: an unreadable log is
  `status: degraded` with the reader's own reason and **no `delivered` claim**. An *absent* log
  area is a readable answer — nothing has ever been held — the split `unanswered-asks` draws.
- **And a tick that reached nobody supplies an `event`** (2026-08-28, the same mission). This
  step supplied **no `event` field at all**, so a tick with 22 candidates and zero delivered
  posted nothing and total silence was byte-identical to a quiet hour — eight consecutive
  ticks, with a red base, a 31-hour declared handoff, three undeletable branches and seven
  undrivable units all held behind it. A delivery failure **is** the event the root exists to
  carry.

  It is supplied **only** for `cap_spent` and `cap_unbounded` — the two states where the tick
  was eligible to ask and structurally could not. Every other case supplies none and therefore
  renders no line: a quiet hour, an off day and the quiet window are the *designed* hold and
  are already named in the log, and a tick that delivered questions needs no event because the
  questions are the delivery. `cap_spent` is worth a line even though the budget worked,
  because a reader has to be able to tell it from `cap_unbounded`. The line names **no dedup
  key and no mention token**.

  **It is the root's third gate**, added beside the morning digest on that gate's own
  precedent: the question gate's expression is untouched and a second condition is OR'd next
  to it (`render-tick-post.sh`). It is **not** the retired changed-step half, which let *any*
  changed step earn a question-less root — this fires only when the check-in itself supplied
  an event, and `delivery_failure` is set **inside the diff loop**, so an unchanged reading an
  hour later is suppressed by the same derivation that suppresses every other restatement. It
  stops entirely once the channel is delivering. The renderer's own skip of `human-checkin`
  was **removed rather than narrowed**, because the guard that replaces it already exists — *a
  step with no event renders no line* — and the check-in supplies one only on a delivery
  failure, so every other tick behaves exactly as it did.
- **Silence is not consent, and it is not a reason to ask again** (resolved 2026-08-17). An
  unanswered question is never re-posted. The red-alert `↳ still failing` precedent covers a
  machine-observable state that persists; a question is a demand on a person's attention, and
  repeating it hourly turns asking into nagging. The unanswered set stays visible where humans
  already look — the tick log and the run report — and the post is still sitting in its thread.
- **Mentions**: a resolved `<@U…>` from the owner's email, never a bare `@name` (it pings nobody),
  and never a Claude mention token on a routine's own post (it re-triggers the app).
- **Aborts**: `quiet_hours`. An answer that resolves something durable is recorded as a
  `kind: answer` feedback record, which is what closes the loop the question opened.

---

### The post this step produces

**One root per tick, questions as replies inside it** (2026-08-21). The step no longer replies each
question into the thread of the item it concerns; it posts the tick's own root and hangs its
questions under it.

1. Render the root: `run.sh`'s JSON | `render-tick-post.sh --tick <id> --root <repo-root> --questions <n>`.
   It returns `post`, a `reason`, the `changes[]` it found and the `root_text` to post verbatim.
2. `post: false` ⇒ **post nothing**, whatever the reason (`idle`, `no_previous_tick`, `no_log`,
   `no_rows`). Report the reason in the run.
3. `post: true` ⇒ post `root_text` as a top-level message carrying `` `tick:<tick-id>` `` and the
   session URL, then post each cleared question as a **reply into that root**, carrying the
   person's `<@U…>` and `` `ask:<key>` `` — and no session URL, which the root already carries.

**A change is a diff against the previous tick**, read from the log; no step declares its own
novelty and no cursor is stored. **The gate is `questions >= 1`** — the changed-step half was
retired on 2026-08-22 (issue #569), because with `0 question(s)` the root is a status line
addressed to nobody. Two narrow conditions sit beside it, each OR'd next to that untouched
expression: the **morning digest** (2026-08-24) and a **check-in that reached nobody**
(2026-08-28, above).

**This step is exempt from `--deadline-seconds`.** The deadline cuts steps in order and this one is
last, so a slow tick used to read nine things and say nothing — the one step whose absence nobody
can see was the first to go. By the time it runs the other steps have handed it their findings, and
asking with nine of them beats asking with none.

## 14. `strategy-digest` — the integrated standup, on the morning root

```bash
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/step-strategy-digest.sh --tick <id> [--root <repo-root>]
```

The per-strategy morning digest, integrated into this tick (2026-08-24, the developer's ruling —
the separate `[Standup]` routine they had already deleted was mistakenly re-created that day, and
the digest belongs in the one thread they read). Once per Asia/Tokyo day, on the first tick at or
after 09:00 (both read from the **tick id**, never the wall clock), the step reads
`standup/scripts/digest.sh` — the same pure read `/standup` uses, one derivation with two
consumers — and hands the digest to the agent to render at the **top of the Moderation root**, in
the developer's specified form: numbered strategies, bold title on its own line, headline is
`commit_count`, honesty line naming tickets and the window. The render is logged
(`strategy-digest-rendered:<jst-day>`) so a second morning render is impossible; before 09:00 the
step reports `before_morning`; a no-op digest (`no_strategies` / `no_activity`) rides nothing; an
unreadable digest is `digest_unreadable`, named rather than rendered as a quiet morning.

**The digest is the root's second gate**: a morning tick with a digest posts its root even with
zero questions — the day's opening statement, the exception the developer asked for — while every
other hour the question gate stands alone.

## 15. `direction-health` — a direction out of date, with nothing answering it, or with its work all in

```bash
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/step-direction-health.sh --tick <id> [--root <repo-root>] [--open-proposals <file>]
```

**It runs beside `strategy-pace`** — tenth in `run.sh`'s `STEPS`, immediately after it and well
before `human-checkin`, which must stay last. (The numbering of these sections is the order they
were written in, not the run order; `STEPS` is the contract.)

Reads `strategy/scripts/direction-state.sh` — the one lifecycle reader, which composes
`survey-strategies.sh` and re-derives nothing — and hands every **non-`live`** reading to the
check-in as a question addressed to that direction's assignee:

| Reading | Question key | Addressed to |
| ------- | ------------ | ------------ |
| `arrived` | `direction-arrived:<slug>` | the strategy's `assignees` |
| `overdue` | `direction-overdue:<slug>` | the strategy's `assignees` |
| `dormant` | `direction-dormant:<slug>` | the strategy's `assignees` |
| `none` (repository-level) | `direction-none` | nobody — there is no direction to own |
| **the last live direction** (repository-level, 2026-08-28) | `direction-last:<slug>` | the strategy's `assignees` |
| `unreadable` | — | **never asked about** |

**Why the step exists** (2026-08-26, mission `say-when-the-loop-has-run-out-of-direction`): three
states of the direction layer were silent and each was byte-identical to a healthy idle hour — a
direction past its date (refused `past_target_date` while `pace` reads `on_course`, because work
*did* land), a live direction nothing is answering (`no_evolutionary_move`, into a run report
nobody opens), and a repository with no live direction at all (`no_strategies`, a no-op
everywhere).

**A fourth reading since 2026-08-27** (mission `say-when-a-direction-has-arrived`): a direction
whose work is **all in**. Every reading above answers *is this direction in trouble*; none
answered *has it arrived*, so a finished direction looked exactly like one still running — and
once its date passed, the loop reported that **success** as an hourly `direction-overdue`
question. `arrived` outranks `overdue` in the reader's precedence for that reason
(`workaholic:strategy`), so a direction that finished late asks the arrival question rather than
the lateness one.

**The `arrived` body is a description of the reading, never an assertion that the direction is
finished** — the discipline `dormant` is already held to. A strategy's "Reached when" is prose no
script reads, so the reading is a **candidate**: the body says everything attributed has landed
and nothing is waiting, names **what landed and the date**, and asks. The operator answers by
announcing that it ended, or by saying it still stands; **the tick closes nothing** either way.

**And since 2026-08-28 it names what the reading could not see** (mission
`say-what-the-direction-could-not-see-before-calling-it-arrived`): the **unattributed active
missions**, by slug, each with its queued-ticket count — three names then `and N more`, so a long
residue is bounded and what is cut is **counted** rather than silently truncated. *Everything
attributed has landed* was true and partial, and the operator had no way to see which half they
were being asked to rule on; measured, a strategy read `quiescent: true` with 125 landed items
while four active missions and ten queued tickets belonged to no direction at all. The residue is
**carried** from the survey row through `direction-state.sh` — the step never calls
`unattributed-work.sh` itself, because two readings of one fact drift. **A degraded residue read
produces no `arrived` reading at all** and therefore no question (`workaholic:propose`), so this
body is only ever rendered over a residue the loop actually read. The register does not move: the
question says *this looks finished, and here is what I could not see*, and the residue is the
reason to check rather than evidence not to. The key, the asked-once gate, the addressee and the
per-tick cap are unchanged — changing a body does not re-ask a question, since the ledger keys on
the step id derived from `key`.

**And since 2026-08-28 both the `arrived` and the `overdue` question name the whole leaving**
(mission `make-a-direction-s-end-a-turn-of-the-loop-not-its-stop`): **what it never reached**
beside **what no direction claimed**. The residue was half of it, and the half that is about the
**repository** rather than about this direction — a person asked to close a direction also needs
to see the work of its **own** that never landed, and `overdue` had neither half. Asking before
the decision is the whole point: after the close it is a post-mortem, here it is evidence in the
one place a person is being asked to rule.

**Carried, never composed in the step.** `direction-state.sh --with-leaving` attaches
`strategy/scripts/closing-residue.sh`'s composition to each row, and the step reads that field —
it calls none of the three readers itself, which the suite pins. It costs **no extra read and no
extra network call**: the composer takes the lifecycle, the residue and the waiting grains off
the row the survey already produced.

**The named detail is in the heading; only the size is in the body.** `workaholic:notify` bounds
the body to one sentence of 25 words and reserves it for the operator's act, so the slugs and
counts ride the heading — where the residue already rode — and the body gains one short clause
saying how much is at stake. Bounded the same way: three names, then `and N more`.

**A leaving we could not compose renders nothing and suppresses nothing.** The question that
would have been asked is asked, without its evidence, and the degradation is counted in the
log-facing summary. Our own blindness never silences a question somebody needs, and is never
dressed up as an empty leaving.

**And `direction-last:<slug>` is the reading one step earlier** (2026-08-28, the same mission).
`direction-none` fires only once **every** direction is already closed, and it is addressed to
**nobody** — the loop announcing its own silence after the fact, to no one. So the **last live**
direction is named to the person who owns it, while they can still act, with the same leaving
beside it and a body saying what closing it means: the loop originates nothing after it, and a
successor announced at the close carries this direction's own refs forward
(`workaholic:specificate`). It is derived from `active_count`, which the reader already emits —
no new counter, no field on any artifact. It is **silent with more than one live direction** (a
general "how many directions" report is the status line addressed to nobody this repository has
twice retired) and **silent for a direction that already has a non-`live` question this tick**,
because one direction drawing two questions is the doubling `handoff-units` and `stalled-units`
were split to avoid. `direction-none` is byte-identical, and this asks and nothing else: nothing
closed, nothing proposed, no gate lifted.

**The coupling is a reader, not a handoff** — the same shape as `strategy-pace` and
`stalled-units`. `/propose` writes nothing into the tree and could not leave a finding here; this
step calls the reader itself. Two readers of one script is not two sources of truth.

**It asks; it never closes, never proposes, never amends, never lifts a gate.** The strategy
artifact has three writers and this is none of them: a dormant direction stays eligible, an
overdue one stays refused, and *ending* or *revising* a direction is announced by the operator
and reaches `close.sh` or `amend.sh` through `/specificate`. Since 2026-08-27 the `overdue`
question names re-dating as one of the operator's three acts; the `dormant` one deliberately does
not, and the question keys, the asked-once gate and every hold are byte-identical. **`unreadable` is not asked about** — counted in the summary and nothing else, the
rule `strategy-pace` already applies to its own `unknown`.

**The check-in's machinery applies unchanged**: the working-day and quiet-hour holds, the per-tick
cap of five and the daily bound of ten, the asked-once ledger, the three-state answer reader and
the once-more re-ask. This step supplies subjects and their content keys; the gate and the ask
stay with `ask-question.sh` and `step-human-checkin.sh`. The cap is a **latency cost here, not a
loss** — a repository with several expired directions can fill a tick and hold the rest to the
next hour, and held is not dropped; no cap of this step's own is invented for a load nobody has
measured.

**What it puts on the root.** `event` names a repository event — *a direction has its work in*,
*a direction has run past its
date*, *the repository has no live direction* — never a counter of what the step examined, and it
**links each direction it names** (the base URL is derived from the local remote, so no network
call; an absent remote degrades to the repo-relative path rather than to a broken link). A tick
on which **every** direction reads `live` supplies the empty string and therefore renders no line
at all — the independent guard against a "nothing happened" line reaching the root even when the
change diff calls the step changed. **So does a tick whose only non-`live` reading is
`unreadable`**: that is our own degradation rather than something that happened to the
repository, the same reason it is never asked about, and it stays in the log-facing `summary`,
which keeps every count.

**`arrived` leads the phrase**, in the reader's own precedence order. *A direction's work is all
in* is a repository event in the fullest sense — something finished — and reading it after a
lateness clause about a different direction is how a success gets read as a failure, which is the
defect the reading exists to remove.

`/standup`'s `no_strategies` no-op is left untouched, and the asymmetry is written down in
`workaholic:standup` rather than left to be re-derived: this tick turns *no live direction* into a
question addressed to a person, while a daily digest about nothing teaches its readers to skip the
surface.

A reader that refuses, or a missing script, is `degraded` with the reason named — never an `ok`
step that found nothing.

## 16. `unanswered-asks` — a message on the channel that nobody has answered

```bash
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/step-unanswered-asks.sh --tick <id> [--root <repo-root>]
```

**It runs immediately before `human-checkin`** — fifteenth in `run.sh`'s `STEPS`, which is the
contract; the numbering of these sections is the order they were written in.

**Why the step exists** (2026-08-26, mission
`answer-what-is-waiting-and-stamp-what-was-accepted`): the tick's question set was bounded by
what its **own** steps found. `stalled-units` reads claims, `direction-health` reads strategies,
and nothing read the channel — so a question, request or opinion written on `#dev-<repo>` reached
a person only if one of the tick's readers happened to produce a row about it. Measured: the tick
of 19:18 JST saw the developer's message in its inbound sweep, filed nothing, deferred to the
`:40` sweep, and told nobody; the developer asked in session why it had not been handled.

**No mention is required, anywhere** — the same premise the inbound sweep was rebuilt on. A person
writing in the repository's own channel does not have to summon a bot for what they wrote to
count.

**The split is `inbound-sweep`'s, for `inbound-sweep`'s reason.** Slack is a connector held by the
**session**, not by a script, so this step owns the mechanical half and hands the judgement half
back in `needs_agent`:

| Half | Owner | What it is |
| ---- | ----- | ---------- |
| which channel, which window | the script | `WORKAHOLIC_INBOUND_SLACK_CHANNEL` (default `<repo_name>`), `WORKAHOLIC_INBOUND_SLACK_WINDOW_HOURS` (default 26) |
| which refs an earlier tick asked about | the script | its own `unanswered-asks-filed` lines, read through `log-read.sh` |
| is this a question, a request, an opinion — and has anything answered it | the agent | the probe returned in `needs_agent` |

**The channel and the window are the inbound sweep's own, unchanged.** One channel and one window
mean the two readings cannot disagree about which messages the loop had a chance to see; a second
pair of variables is exactly how they would. The cost is stated rather than hidden: a message
already older than the window when this step first runs is never asked about, and nothing
backfills it. Every message arriving afterwards is asked about exactly once.

**The ledger is the tick log and there is no second one.** The already-asked refs are an
optimisation handed to the agent so it does not re-derive them; the **gate** is
`ask-question.sh`'s own asked-once ledger, keyed mechanically on `unanswered-ask:<channel>:<ts>`,
which is what guarantees "exactly once". Nothing here re-implements the per-tick cap of five, the
daily bound, the quiet hours or the working-day hold.

**An absent log and an unreadable one are different answers.** `no_log_area` is *readable* —
there is definitively nothing recorded — and yields an empty set. Any other refusal from the
reader, a missing reader, or unparseable output is `degraded` with the reason named and **asks
nothing**: filing against a ledger that could not be read is how one person is asked the same
question every hour. The Slack-side degradations belong to the agent and are named by it —
`no_slack_transport`, `channel_unreadable` — never rendered as a channel with nothing waiting.

**It asks; it never answers, files or captures.** Turning a channel message into an `[FB]` issue
is the `:40` sweep's job (`workaholic:propose`) and stays there. The two overlap by design — the
sweep runs at `:40` and this at `:50`, so a message captured this hour normally already has an
issue — and that is a reason to read **whether anything answered it**, not a reason to skip it:
an issue nobody has replied to is still a person waiting.

**Its `event` is always the empty string, and that is a deliberate divergence** from
`direction-health` and `stalled-units`, which settle their readings in the shell and can name a
repository event. This one cannot: at the moment `run.sh` reads its line, nobody has looked at
the channel yet, so any event would be a claim about a reading it has not made. A step with no
event renders no root line — which is right here, because the finding's whole delivery is the
question, and a question is already a reply inside that root.

**The ask said "reacted to".** The tick's way of reacting to something is to ask a named person
about it inside its root; a second status surface would be the line addressed to nobody this
repository has retired twice.

## 17. `undrivable-units` — work the loop wrote and cannot drive

```sh
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/step-undrivable-units.sh --tick <id> [--root <repo-root>]
```

Queued work whose owner is an address **no entry of the committed `.claude/git-identities`
mapping names**. Such a unit is undrivable by every runner: `owns.sh` answers `other` for an
address it cannot resolve to the person asking, so the survey excludes it as
`owned_by_other` — correctly, and forever.

**There was no path from *the loop cannot drive its own output* to *a person is told***
(2026-08-26). `plan-units.sh` learned to report `backlog_all_excluded` in the same change,
which puts the fact in a run report; a run report is read by nobody on the day it matters,
the same reason `/propose`'s report was refused as the surface for `strategy-pace`. And
`/implement` may not ask. Measured on this repository: ten units sat undrivable for five
days while every hourly tick reported a clean, current survey — including the mission whose
own job was to repair the other half of the defect.

**A colleague's queue produces no question**, and that is the step's whole care. Work owned
by somebody the mapping *names* is a colleague's queue working exactly as designed; an
hourly complaint about ordinary team ownership is muted within a day, and the one real
finding then arrives inside a stream a person has learned to skip. The mapping is what tells
the two apart, which is why the step reads `gather/scripts/identity.sh` rather than the raw
address. `assignees: []` is team-owned work naming nobody and is never a candidate.

**It does not read `plan-units.sh`, and the ticket that asked for this named it as "a pure
read".** It is not one: the survey reaches the mission readers, which carry this repository's
living migrations and **stage** what they converge — the same composition
`closable-missions` refused, for the reason its header records (*a step whose contract is
writes nothing may not reach it through something that writes*, caught by that step's own
test leaving a modified mission in the index). The candidate set is derived instead from the
readers the survey itself uses for ownership — `gather/scripts/owners.sh` over
`identity.sh` — walking `tickets/todo/` and `missions/active/` directly. No ownership rule
is re-implemented; only the enumeration is, which is what keeps the contract true.

**The finding is about the repository, not the runner**, so the runner's own identity is
never consulted: an owner no entry names is undrivable by every account, and this tick is
repository-scoped — one copy for the whole team. Keying it on `owns.sh`'s three-way answer
would make an hourly repository-wide question depend on which container asked it.

**It asks and nothing else** — no reassignment, no artifact, no claim touched, no gate
lifted. The repair is one line in the mapping, and `/workaholify`'s coverage audit
(`workaholify/scripts/audit-identity-coverage.sh`) proposes it with the address already
filled in. Each candidate is keyed `undrivable-unit:<artifact path>` through
`ask-question.sh`, so the asked-once gate, the per-tick cap, the quiet hours and the
working-day hold all apply unchanged and no second ledger exists.

**The summary carries no age and no timestamp**, for the correctness reason
`stalled-units`' header records: the root calls a step changed when its summary differs from
the same step's an hour ago, and a summary that moves every tick marks the step changed
hourly by construction. It counts **every** owned artifact and narrows only what it asks
about, so the whole picture and the narrowing sit on one line.

A tree with no `.workaholic/` is an ordinary `ok`; readers absent from the skill are
`degraded` by name. A queue every owner of which the mapping names supplies **no `event`**,
so the root renders no line: nothing happened to the repository.

## 18. `undelivered-units` — a unit the loop finished and could not deliver

```sh
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/step-undelivered-units.sh --tick <id> [--root <repo-root>]
```

Every claim the oracle reads **`report_undelivered`**: a unit the loop drove to a green pull
request whose **merge the transport refused**. Its work is pushed, its story is committed, its
pull request is open — and nothing will pick it up, because a drained claim is excluded at every
later survey.

**No step saw this shape** (2026-08-27). `stuck-prs` and `merge-conflicts` read pull requests and
find one that is open and green; `stalled-units` reads the claim oracle's **stale** rows and this
claim is not stale — its heartbeat advanced right up to the moment it finished. So an undelivered
unit reached a person through nothing at all, while `/implement`, which may not ask anyone
anything, reported `ok` over it. Measured 2026-08-27: four pull requests (#622, #625, #633, #635)
green and unmerged, offered by no survey and told to nobody.

**Which sibling it follows, on each axis:**

| Axis | Follows | Why |
| ---- | ------- | --- |
| whose question | `stalled-units` | the **claim holder** is a real person who drove this unit and can retry its merge |
| the running identity | `undrivable-units` | never consulted — the claim's own `author` is the addressee, so an hourly repository-scoped question does not answer differently per account |
| what it may read | `undrivable-units` | `list-claims.sh` is a pure read; **`plan-units.sh` is refused**, because the survey reaches the mission readers, which carry the living migrations and **stage** what they converge — the composition `closable-missions` already refused |

**The candidate set is the split reason, not a re-derivation.** `report_undelivered` is the claim
oracle's own verdict and the refusal rides on the row as `merge_outcome`, read off the branch
story the run recorded it in (`story/scripts/record-merge-outcome.sh`). Two readers of one script
is not two sources of truth, and a second opinion about whether a pull request is held by a gate
or by a transport is exactly the disagreement that would reintroduce the silence.

**The pull request's coordinates cost one lookup per candidate**, through `claim-merged.sh` — the
claim protocol's one network read. It is three-valued, and an `unanswerable` read **does not drop
the candidate**: the finding is that the unit is undelivered, which the oracle already
established offline; the URL and the age are simply left unstated, which is the honest rendering
of a read we could not make.

**The summary carries no age and no timestamp**, for the correctness reason `stalled-units`'
header records: the root calls a step changed when its summary differs from the same step's an
hour ago, and an incrementing age would make this step changed hourly by construction. The age
still reaches the person, in the question that names the unit.

**It asks and nothing else.** It never merges, never retries, never drives and never resolves the
blocker itself. Each question is keyed `undelivered-unit:<unit>` through `ask-question.sh`, so
the asked-once gate, the per-tick cap, the quiet hours and the working-day hold all apply
unchanged and no second ledger exists. A degraded read (`no_claim_reader`, `claims_unreadable`,
`claims_unparseable`, `origin_unreachable`, `shallow_history`) is named and asks nothing — a scan
that could not reach the remote has not found *nothing undelivered*, it has found nothing at all.

## 19. `retire-claims` — a claim proved empty, taken off the table

```sh
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/step-retire-claims.sh --tick <id> [--root <repo-root>]
```

Every claim the oracle reads **`superseded`**: the unit's content already reached the base, so
the branch can never land and holds no work. The step hands each to
`drive/scripts/retire-claim.sh` — its **only** caller, deliberately, because one caller is what
keeps the retirement's bounds checkable — which closes the pull request, deletes the remote
branch and reaps the worktree.

**Why it exists** (2026-08-27, mission `deliver-and-retire-what-the-loop-already-proved-finished`).
`superseded` has been *reported, never acted on* since it shipped, so nothing retired the **claim
itself** and the claim table only ever grew. Measured 2026-08-27 on this repository: 7 claims, **4
of them `superseded`**, two naming missions archived days ago, the oldest branch last touched
2026-08-21. The verdict's standing did not move; one act now follows from it.

**It asks nobody anything about a retirement that *succeeded*, and `needs_agent` is empty for that
reason.** A completed retirement is not a person's business: the claim is *proved* empty, so there
is no judgement to make and nothing for a human to weigh. That is the sharpest contrast with
`stalled-units`, `undrivable-units` and `undelivered-units` beside it — each of those hands a
person a reading it cannot act on, while this one acts and reports. Spending a question on a fact
nobody needs to rule on is what `strategy-pace` already refuses to do.

**And it asks the claim holder about a retirement blocked on the delete** (2026-08-27, mission
`finish-the-retirement-the-loop-cannot-complete`) — **narrowed, not reversed**. The rule above was
written when every retirement either succeeded or was refused on a **judgement**, and it is wrong
the moment a **proof** the loop acted on leaves one act undone. Act 2 is refused in the container
the loop runs in — both `git push --delete` and the REST ref-delete answer 403, and the connector
has no ref-delete surface at all (`drive/reference/claims.md`, *When an act of the retirement is
refused*) — so the branch stays on origin, the claim never leaves the table, and this step
reported `0 retired` hour after hour with nobody told. The unit is then exactly the shape
`undelivered-units` and `handoff-units` exist for: a reading the machine cannot act on, addressed
to one person.

One question per blocked unit, keyed **`retire-blocked:<unit>`** so `ask-question.sh`'s
asked-once ledger holds it to exactly one ask, naming the unit, the **exact branch** left on
origin, the refusal, and the acts that already stand — a question that does not name the branch
does not say what to delete. Which half moved and which did not: a retirement that **worked**
still asks nothing at all.

**Whose question it is**: the **claim holder**'s, following `stalled-units` and
`undelivered-units` — a real person who drove the unit and can delete its branch. The **running
identity is never consulted**, following `undrivable-units`: a branch left on origin is a fact
about the repository, so an hourly question that depended on which container asked it would answer
differently per account.

**Narrowed to the delete, and one unit never draws two questions.** A refused *reap* is local to
this runner and tells its holder nothing they can do remotely; a refused *close* is a different
act with a different repair. And every candidate here reads `superseded`, which `stalled-units`
already filters out of its own candidates and counts as a finding instead — so the pair was
already honest and nothing new had to be filtered; the other two claim-reading steps key on
`report_undelivered` and `awaiting_verification`, which no `superseded` row can also be.

**It asks and nothing else**: no claim released, no pull request reopened, no delete re-run on the
strength of an answer, and the `superseded` proof gate and the retirement's other two acts are
exactly what they were.

**And the question narrows once more, to what CI could not take either** (2026-08-28, mission
`finish-a-proved-retirement-where-the-write-is-permitted`). Act 2 now runs in
`.github/workflows/claim-retirement.yml`, where the write is permitted, so a blocked unit whose
branch a workflow is about to delete must draw **no** question: asking a person, once per unit and
forever, for an act CI was about to perform is not merely noisy — the ask is wrong.

The reading is `drive/scripts/ci-retirement-turn.sh` and it is **store-free**, which is the
constraint that shaped it. CI *deletes* the branch when it succeeds, and unmerged remote branches
are the only claim oracle, so a successful turn removes the claim row and the candidate with it. A
**completed run at the base tip this tick is reading** therefore means CI saw exactly this tree and
the branch survived it — the matching is on `head_sha`, which needs no clock, no timezone and no
date parsing, and answers the question actually being asked rather than a proxy for it. Three
values, each with its own consequence:

| Reading | What it means | What the tick does |
| ------- | ------------- | ------------------ |
| `taken` | a completed run at this tip left the branch standing | ask — the unit is blocked at **both** executors |
| `pending` | no completed run at this tip yet | ask nobody **this tick**; the asked-once ledger keys on the unit, so a branch that outlives CI's turn is still asked about later |
| `unavailable` | the workflow is not present in this repository | ask — CI will never take the act here |

A read the step could not make leaves the question exactly where it was, on the same rule: an
over-eager question is better than a silently dropped one, and this repository has measured the
cost of a blocked act nobody was told about.

**Everything else about the question is byte-identical** — the key `retire-blocked:<unit>`, the
asked-once gate, the addressee, the per-tick cap, the quiet hours and the working-day hold. Only
the candidate set narrows, and the **summary carries no CI term**, deliberately: every term of it
stays a function of the claim set and the act states, so a held block keeps rendering identically
tick after tick and a newly blocked unit still moves it. The narrowing is not a suppression list.

**And which executor took a delete is now rendered, from two states that already exist.**
`deleted` means this tick performed the delete; `already_gone` means the ref was not on origin
when this tick looked, and asserts nothing about who removed it — so the two render as *branch
deleted here* and *branch removed elsewhere*. `already_gone` keeps rendering as the **success** it
is, `failed` and `not_attempted` are untouched, and `retire-claim.sh`'s output shape and its four
Act-2 words are byte-identical. A `deleted_by: ci|container` field is refused: the answer is
already derivable, and a stored one eventually disagrees with the derived one.

**It acts directly rather than handing off**, which is where it diverges from `closable-missions`.
That step hands its act to the agent because `close.sh` **writes into the tree** and needs a
publish tree to do it. `retire-claim.sh` writes nothing into the tree at all — one REST `PATCH`,
one branch delete, one local worktree reap — so there is no tree seam to cross, and the tick's
*writes nothing but its own log line* contract is intact.

**The re-proof is the writer's own, at the moment of the act.** This step reads `list-claims.sh`
once for candidates; `retire-claim.sh` then re-reads the oracle and re-derives the verdict before
touching anything, so a row that went stale between the two reads is refused by the writer rather
than acted on from this step's snapshot. That is the `closable-missions` precedent (2026-08-24)
applied where it belongs — the proof re-taken where the act happens, not trusted from an earlier
read. **A row the re-proof rejects is reported, not retired.**

**It reads `list-claims.sh`, never `plan-units.sh`** — `undelivered-units`' and
`undrivable-units`' rule, first recorded by `closable-missions`: the survey reaches the mission
readers, which run the living migrations and **stage** what they converge, and a step whose
contract is *writes nothing into the tree* may not reach it through something that writes.

**The per-row detail lives in `summary`**, the log-facing field, because the tick log is the audit
trail and these outcomes are what somebody diagnosing a retirement needs. A retired row names all
three acts (`pr closed, branch deleted, worktree reaped`) and a **refused row now names them too**,
beside its reason (2026-08-27) — it rendered `<unit> refused (<reason>)` until then, dropping the
acts that **succeeded**, so a re-run of one act read as a re-run of three and three units whose
pull requests had been closed days earlier still read as bare refusals on every tick. The states
are already on the writer's row, so this reads them and derives nothing: `already_closed`,
`already_gone`, `absent` and `none` render as the **successes** they are, and `not_attempted`
stays distinct from `failed` — a gate that never ran made no finding about the world. Neither
count is a bare number to go digging behind. `needs_agent` is still not the home for that detail:
it carries the blocked units and only them, because that field is a **request** and a payload with
no action would be read as one.

**A degraded read retires nothing.** Unmerged remote branches are the only claim oracle, so a scan
that could not reach the remote has not found *nothing to retire* — it has found nothing at all,
and a proof that could not be read is not a proof (`no_claim_reader`, `no_retirement_writer`,
`claims_unreadable`, `claims_unparseable`, `origin_unreachable`, `shallow_history`).

**A retirement is a repository event, and a tick that retired nothing supplies none.** The step
names what it retired — a pull request closed, a branch deleted — because it knows what its
finding means and the renderer does not; a tick whose re-proofs all *rejected* is in the same
class as one that found nothing, because a refusal is the step's own bookkeeping and belongs in
the log. **The line is not a posting gate**: the root posts only when the tick has at least one
question, and this step never has one, so its line rides a root some *other* step's question
opened. On a tick with no questions the retirement is visible in the log alone — which is
correct, because a retirement addressed to nobody is exactly the status line two keyed roots were
retired for.

**The summary carries no age and no timestamp**, for the correctness reason `stalled-units`'
header records. A count of what was retired this tick is stable when nothing happens, which is
what the root's hour-to-hour diff needs.

**And a standing blocked retirement must not read as an hourly change** (2026-08-27). `0 retired`
over a unit already asked about is a **held** condition, not a new one, and this repository has
measured the same shape three times: a status restated hourly is read by nobody by the second day.
Every term of the summary is a function of the **claim set and the act states** and of nothing
else, so the same units with the same acts standing and the same refusal render the same string
tick after tick — and with `event` empty on a tick that retired nothing, no root line at all.
Those are **two independent guards**, and neither is a suppression list: a **newly** blocked unit
moves the unit set, so the summary moves and the block is visible the hour it happens. Suppress by
nothing; let the diff work. A per-unit suppression list was refused — the diff already answers the
question, and a second ledger beside `ask-question.sh`'s asked-once gate is how the two drift.

**Drilled, not asserted.** `sh scripts/e2e/loop-drill.sh verify-retire` builds the blocked-delete
shape over a local bare origin whose own `update` hook refuses one ref's deletion — the same
receive-side path a remote refusal takes, with no network — and covers the named word, the acts
that stand, the question and its key, the asked-once gate over two ticks, that nothing already
done is undone, and that the summary is stable across two ticks. Its breaker row carries a unit
that was **retired** and one **refused on another act** in the same tick, so a candidate set
widened either way fails the drill.

## 20. `base-health` — did the base survive what the loop merged?

```sh
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/step-base-health.sh --tick <id> [--root <repo-root>]
```

The base's own checks, read once per tick through `drive/scripts/attribute-base-red.sh` — which
composes `drive/scripts/read-base-checks.sh`, the one derivation of a commit's check state. A red
base is handed to the check-in as **one question addressed to the attributed merge's author**.

**A red base reached a person through no path at all** (2026-08-27). `/implement` may not ask
anyone anything; `stuck-prs` and `merge-conflicts` read **pull requests** and find nothing wrong
with one that already merged; `stalled-units` reads stale claims and a red base has no claim. The
loop merges its own work onto `main` every half hour and never learned what the base's checks then
said, so a green base and a base nobody looked at were one reading.

**Which sibling it follows, on each axis:**

| Axis | Follows | Why |
| ---- | ------- | --- |
| whose question | `stalled-units` | the **attributed merge's author** is a real person who made the change and can act on it |
| the running identity | `undrivable-units` | never consulted — a red base is a fact about the **repository**, so an hourly question that answered differently per container is exactly the failure that axis exists to prevent |
| what it may read | `undrivable-units` | the ticket-2 walk and nothing else; **`plan-units.sh` is refused**, because the survey reaches the mission readers, which carry the living migrations and **stage** what they converge — the composition `closable-missions` already refused |

**The key is the commit, not the tick and not the day.** `base-red:<commit>` is what makes *exactly
once per broken commit* mechanical rather than a rule somebody remembers: twenty-four ticks may see
one red base and exactly one question goes out. The overlap with a person already watching CI is
deliberate and cheap for the same reason.

**`unattributable` still asks, keyed on the tip.** The base is red and that is worth a person's
attention whether or not the walk could name a culprit — but the question says plainly that the
attribution failed and why, so nobody is sent after a merge this step did not identify. Left silent
it would be a real finding with no path to a person, which is the shape the step exists to remove.

**The addressee is an address, not a login.** The walk names the pull request's GitHub login;
`gather/scripts/identity.sh` — the one mapping reader — converts it, and a login the mapping does
not name leaves the question addressed to nobody rather than stamping an address nobody verified.
That gap is `undrivable-units`' finding, not this step's to guess at.

**A degraded read asks nothing** and is named (`no_walker`, `walk_unreadable`, `walk_unparseable`,
`base_unreadable:<reader reason>`). `unanswerable` is a reading **we** could not make, not a
finding about the repository — the rule `direction-health` already holds for `unreadable` and
`strategy-pace` for our own degradation.

**It asks and nothing else.** It never re-runs a failing check ("flake" is not a root cause and a
re-run is an *act*), never reverts, never merges, never touches a claim, and writes nothing
anywhere but its own tick-log line. What it reads is a **judgement**, not a proof: a re-run can
turn a red check green (`drive/reference/claims.md`, *Proofs and judgements*), so acting on it is
forbidden and reporting it is the whole job.

**It is placed before `human-checkin`**, like every question-producing step. Note that
`human-checkin` is exempt from `--deadline-seconds` and this step is not: a slow tick may not reach
it, which is reported as unreached — never as green.

**The summary carries no timestamp**, for the correctness reason `stalled-units`' header records.
It names the reading and the failing checks; the commit sha it carries is normalised out of the
root's hour-to-hour diff, so two ticks over one unchanged red reading do not read as two changes.

**Only a red base supplies an `event`**, and it names the repository event rather than the tick's
bookkeeping: *the base went red at `<commit>` — `<checks>` failing, from that merge*, with the
commit linked (and the pull request too, when the walk named one) so the root line is followed
rather than merely read. A green base and a degraded read supply **none**, so a healthy hour
renders no line at all — the renderer's own rule, *a step with no event renders no line*, is the
independent guard against a nothing-happened line reaching the root even on a tick whose diff
calls this step changed. An `unattributable` red base supplies a line too, saying in words that
the merge could not be attributed. **It is not a second posting gate**: the root posts when the
tick has at least one question, and on a red tick this step has already supplied one. The base URL
is derived from the **local** remote (`step-direction-health.sh`'s precedent) — no network call —
and an absent remote degrades to the bare short sha rather than to a broken link.

## 23. `thread-reconcile` — a finished item whose thread still calls it in flight

```bash
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/step-thread-reconcile.sh --tick <id> [--root <repo-root>]
```

- **Reads**: `reconcile-candidates.sh` (the section below) and the tick log. Nothing else.
- **Writes**: nothing itself — no post, no merge, no branch, no artifact. The agent writes, and
  its only write into the tree is this step's own `thread-reconcile-filed` log line.
- **Its `event` is always empty**, deliberately and for `unanswered-asks`' and `question-answers`'
  reason: when `run.sh` reads this step's line nobody has read a thread yet, so any event would be
  a claim about a reading not made. **A step with no event renders no root line**, which is the
  independent guard against a tick that reconciled nothing announcing itself.

| Half | Owner | Why |
| ---- | ----- | --- |
| Which candidates, which bounds, what an earlier tick settled | the **script** | mechanical, offline, and the same answer from every session |
| The thread lookup, the thread read, the reply | the **agent** | Slack is a connector held by the session, not by a script |

**It is registered beside `handoff-units` and `undelivered-units` deliberately**: all three read a
unit the loop *finished*, and the three next actions differ — satisfy a declared verification,
retry a refused merge, correct a false last word. Keep the three vocabularies separate; a single
"what the loop is blocked on" report addressed to nobody is what two roots were retired for.

**The set is bounded and the remainder is reported**: `WORKAHOLIC_RECONCILE_READ_MAX` (default 10,
in line with `WORKAHOLIC_ANSWER_READ_MAX` rather than a new constant), **newest first** — the
thread a person is plausibly still reading — with `beyond_bound` carrying the rest.

**The `<step>-filed` line is an optimisation the agent is handed, not the gate.** The real dedup is
**structural**: the agent reads the thread *before* writing, so a thread already carrying its finish
is never touched however many ticks run. The ledger only saves a lookup on a candidate an earlier
tick already settled. **Do not add a cursor or a second ledger on the strength of it.**

**An absent log and an unreadable one are different answers.** `no_log_area` is a **readable**
answer — nothing has ever been reconciled — and yields an empty already-done set. Any other refusal,
or a missing reader, is `degraded` by name and hands back **nothing**: filing against a ledger that
could not be read is how one thread gets a second reply.

**It must not read `plan-units.sh`.** The survey runs the living migrations and **stages** what they
change — the composition `closable-missions` and `undrivable-units` both refused for a step whose
contract is *writes nothing*.

### The agent's half, per candidate

1. **Find the thread** through `workaholic:notify`'s stateless lookup: exact-string searches only,
   **at most two queries**, cases 2 and 3 only, **no channel-history read anywhere**, fuzzy matching
   prohibited by name. **Case 4 does not apply here** — a lookup that finds no thread means the loop
   never announced this item at all, so there is nothing stale to correct. Posting a description
   root would announce a merge nobody was ever told about, which is `[Consent]`'s retired job.
2. **Read that thread before writing anything**, and make the bar conservative. Only a **latest**
   status reply of `🔵 Proposed` or `🟡 Handoff` is a candidate; a latest status of `🟢`, `🚀`,
   `🔴`, or a reconciliation this loop already posted, is **not**. **When unsure, post nothing and
   say what made you unsure** — the standing bar, and here it costs one tick rather than a duplicate
   announcement in a person's thread.
3. **Post the catalog's shape** for the state the reader gave: `🟢 Implemented` with the sentence
   naming that it merged outside the loop, **by whom and when**, for a merge; `⚫ Closed` for a pull
   request closed without merging. **Never invent an author or a time** — an unresolved one is
   *stated* as unresolved, never omitted silently and never guessed.
4. **Record one `thread-reconcile-filed` line per candidate** through `log-append.sh`, naming the
   key and the outcome, then persist again through `persist-log.sh --tick` — the **second** persist,
   without which the line dies with the container.
5. **One outcome per candidate, or the other**: `posted`, or a named not-posted reason —
   `no_thread`, `already_finished`, `unsure`, `no_slack_transport`, `thread_unreadable`,
   `post_failed`. **A candidate handed back with no outcome is non-conformant on its face**: this is
   a prose contract, not a script gate — no mechanical check tells a real thread read from a claimed
   one — and what it buys is that a report naming no outcome is visibly wrong.

**The lookup is `workaholic:notify`'s, unchanged, and no coordinate is in hand.** Unlike
`question-answers`, nothing recorded where the `🔵`/`🟡` line was posted — another container posted
it, in another run — so the thread is found the way everything else finds it: the **stateless**
lookup, private-inclusive (`slack_search_public_and_private`, `include_bots: true`, so the routine's
own prior posts are visible to it), **two queries at most**, and **fuzzy matching prohibited by
name**. Cases 2 and 3 only. **The inbound sweep's case 1 does not apply either** — that post has its
coordinate as its own input; this one has none.

**The post carries no mention token.** It is addressed to whoever follows the item, not to a person,
and the standing rule forbids mentioning the identity it is posted as.

**The idempotence is structural, and that is the ask's own promise made mechanical**: *the step reads
the thread before writing, so never re-announcing a merge the channel already carries is satisfied by
construction*. Two ticks over the same item produce one reply, because the second reads a thread that
now ends in `🟢` or `⚫` and stops at step 2. Resist adding a cursor or a second ledger.

**What it never does**: never merges, closes or reopens anything, never touches a claim, never posts
a root, never posts into any thread but the item's own, never posts a description root, and never
posts twice.

**Degradations, named one by one**: `no_log_reader`, `ledger_unreadable`, `no_candidate_reader`,
`candidates_unreadable`, `candidates_underivable`, and `candidates_<the reader's own reason>` when
the candidate read itself refused — *nothing was looked at* is never rendered as *nothing is stale*.

## The reader behind the thread reconciliation — `reconcile-candidates.sh`

```bash
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/reconcile-candidates.sh [--window-days <n>] [--limit <n>] [--root <repo-root>]
```

**Why it exists** (2026-08-28, mission `reconcile-a-stale-thread-with-the-unit-s-real-state`). A
finish line is posted by the run that **finishes** a unit (`workaholic:notify`, *Which thread an
`/implement` unit's posts land in*), so a pull request a person merges by hand gets its finish
posted by nobody: the item's thread keeps `🔵 Proposed` or `🟡 Handoff` as its last word while the
work is long merged. **No existing step can see it** — `stuck-prs` and `merge-conflicts` read
**open** pull requests and find nothing wrong with one that already merged, `handoff-units` reads a
claim that is still standing, and `stalled-units` reads a stale tip. All four are about a unit that
has **not** finished; this is about one that has.

**Measured on this repository, 2026-08-28.** Over a 3-day window: 53 closed `work-*` pull requests,
21 resolving to a feedback stem, none of them merged by a person. Over 7 days: 90 closed, 40 with
stems, and **19 merged by a person rather than by the loop** — the set whose threads the agent half
must actually read. The two human merges inside the 3-day window (#646, #626) resolve to **no**
feedback record at all: they are hand-written `/ticket` units, which the loop keys on `unit:<id>`
and which therefore have no thread to reconcile. That distinction is why the reader reports them
rather than dropping them.

- **Reads**: GitHub's closed pull requests through `gather/scripts/gh-rest.sh` — the one transport
  (`rules/shell.md`) — and the local tree. **Writes nothing**: no file, no commit, no branch, no
  comment, no merge, no claim touched.
- **The candidate set is repository-derived, never a channel scan.** `workaholic:notify` bounds
  every thread lookup at two exact-string searches with **no full-channel read at any point**, so
  deriving candidates from the channel would break that bound outright and make the reader's cost
  grow with the channel rather than with the work. The drill carries a breaker row wiring it at the
  channel for exactly this reason.
- **It does not decide whether a thread is stale.** That needs the thread, and Slack is a connector
  held by the session rather than by a script (`step-unanswered-asks.sh`'s split, for its reason).
  It answers *which items to look at*, and nothing more.

**A candidate carries what the lookup and the reply need**: the feedback `stems`, the pull request's
`number` / `title` / `url`, whether it `merged` or `closed` unmerged, and the `merged_by` /
`merged_at` the reply's sentence names. `merged_by` comes from the single-pull GET, the only
endpoint that carries it; that read is bounded by `--limit` exactly as `pulls-state.sh` bounds its
own. **An unresolved author or time is emitted empty and stated as unresolved — never invented.**

**Three local sources resolve a branch to its artifacts, and no network is spent on any of them**:
the branch's own **merge commit diff** (which is what resolves a `/specificate` proposal, whose
mission and tickets carry the record's refs by the carry floor), the **branch-keyed ticket archive**,
and the **story's `mission:` relation** read through `mission/scripts/read-relation.sh`. A ticket
written to `todo/` by one merge and archived by another is at neither path the diff named, which is
why the archive is consulted too. The artifacts then go to `drive/scripts/unit-feedback-stems.sh` —
**the one translation** from a unit's artifacts to its thread key, never re-parsed here.

**One case the local sources cannot cover, and one extra call for it.** A pull request **closed
without merging** has no merge commit, its story never reached the base and it archived nothing, so
every local path is silent about it — and `⚫ Closed` would be a shape nothing could ever reach.
Only for a candidate the tree could not answer, the reader asks GitHub for that pull request's own
changed files and resolves those paths against the base: a mission published by an earlier merge is
there, and the unit resolves. It is one call, bounded by `--limit` like every other per-pull read,
and it is **never** spent on a candidate the tree already answered.

**Both bounds are configurable and both are reported.** `--window-days`
(`WORKAHOLIC_RECONCILE_WINDOW_DAYS`, default 3) and `--limit` (`WORKAHOLIC_RECONCILE_MAX`, default
10, with `truncated` and `beyond_bound`); the list itself is read in
`WORKAHOLIC_RECONCILE_PAGES` pages of 50 (default 3) and **`list_capped` says when that bound, rather
than the repository, ended the read** — one page cannot serve the window on a repository closing
twenty-five pull requests a day, and a single page would have answered "nothing merged" for anything
older than yesterday.

**A candidate whose artifacts resolve to no feedback stem is reported in `unresolved` under
`stems_unresolvable`, and is never keyed on `unit:<id>` here.** This reader answers *which item*, and
an item with no feedback record has no thread to reconcile at all.

**Degradations, named one by one**: `gh_unavailable`, `list_failed`, and the per-candidate
`stems_unresolvable`. An unreadable read is `ok: false` with its reason and **exit 0**, carrying **no
candidate list at all** — never an empty one, which would render our own blindness as "nothing to
reconcile".

## What `run.sh` guarantees around the steps

- **Every step is invoked and every step reports.** Missing script → `degraded`/`step_missing`;
  non-zero exit → `degraded`/`step_error`; empty or unparseable output → `degraded`/`no_output` or
  `bad_output`; a status outside the log vocabulary → `degraded`/`bad_output`. A step never
  disappears from the report.
- **One writer.** Step scripts write no log line; `run.sh` does. Two writers would race on
  `(tick, step)` and make idempotence a property of caller discipline instead of of the code.
- **`--only` / `--skip` are for the operator and the tests**, and a skipped step is still a
  reported line (`skipped`/`requested`) — an unreported skip is the failure this whole design is
  built against.

---

## The closing act — `persist-log.sh`

Not a step at all: the twenty-one above are the contract and the log's step keys, and this is the
run's own bookkeeping. It runs **after** the last step has had its turn, so a tick that dies
half-way still persists what it recorded on its next run, and it reports under the run's top-level
`persist` key while logging under the step id `persist-log`.

- **Reads**: the checkout's `.workaholic/moderations/<UTC-day>.md`, and the base's copy of the
  same path.
- **Writes**: that one file, on the base, through the publish tree — `open-publish-tree.sh` →
  `publish-tree-commit.sh` → `close-publish-tree.sh`. Nothing else, anywhere. The caller's checkout
  is byte-identical afterwards: no branch, no worktree, and no `publish-main` ref on origin, so the
  claim protocol's branch scan never sees it.
- **Who commits the log, and when**: this script, **twice** per tick. `run.sh` runs it as its
  closing act, and the agent runs it again after recording its `<step>-filed` lines (`SKILL.md`,
  *The run*) — the agent acts on `needs_agent` only after `run.sh` has returned, so the closing act
  alone can never carry what the tick filed. It is the only writer to the base in the whole skill,
  and it carries **every** section the checkout has and the base does not — so a tick whose persist
  failed is carried up by the next tick in the same container.
- **Concurrency is a union, not a rebase.** Two containers ticking on the same day both append to
  the same file, and a textual rebase of two end-of-file appends conflicts. So each attempt
  re-opens the publish tree at a freshly fetched base and appends only what the base is missing; a
  rejected push re-unions rather than replaying a patch. Attempts are bounded (default 3) because
  sustained divergence is something a human should see.
- **The union is by `(tick, step)`, not by `(tick)`** (2026-08-18, PR #489). A `## <tick-id>`
  section the base lacks is appended whole (`sections`); a section it already carries is merged
  **entry by entry**, appending only the steps its copy lacks, in the checkout's order, at the end
  of that section (`lines`). Nothing is rewritten, reordered or removed — a `(tick, step)` the base
  already has wins over a differing local copy, the same append-only-in-substance rule
  `log-append.sh` applies within a run. By section alone, the second persist above was inert: it
  asked only whether the base had the section, it did, and every `<step>-filed` line died with the
  container while the script reported `already_current` and was correct by its own rule.
- **Aborts, each by name**: `not_a_repo` and `root_not_repo_root` (a `--root` outside the
  repository — the drill's throwaway root — is never published into whatever repository the cwd
  happens to be), `no_log` (nothing was recorded), `no_origin` (`skipped`: a local-only checkout
  has no base, so nothing went wrong), and `origin_unreachable` / `base_unresolved` /
  `dirty_publish_tree` / `diverged` / `push_failed` / `commit_failed` (`degraded`: the base exists
  and the log did not reach it). A failed persist leaves the log in the checkout and says so; it
  never half-writes.
- **The last persist's own log line is not on the base, deliberately.** The outcome is known only after the push,
  so recording it, pushing again, and recording *that* does not terminate. The base already carries
  the answer: the tick's section is there iff its persist succeeded, and when it did not, the run
  report names the reason. Full rationale, including the rejected pull-request-per-tick
  alternative and the point-by-point contrast with the three writer designs `workaholic:ship` §7
  refused, is in the script's header.

## 21. `handoff-units` — a finished unit waiting on a verification only a person can run

```sh
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/step-handoff-units.sh --tick <id> [--root <repo-root>]
```

Every claim the oracle reads **`awaiting_verification`**: a reported unit whose still-**queued**
work was *declared* unverifiable in an unattended environment at creation
(`verification_handoff:`). `workaholic:drive` §6 routes such a unit to the **handoff** route on
purpose — the pull request opens and stays open, the claim stands — and the one act that moves it
is a person running the declared verification.

**Nothing read the verdict again** (2026-08-27, mission
`ask-for-the-one-act-a-declared-handoff-is-waiting-on`). `awaiting_verification` appeared nowhere
outside `drive/`, so the only surface in this plugin that reaches a person by name never learned
there was anything to say; and once the tip went stale, `stalled-units` asked the *wrong*
question about it — *a claimed unit has not moved for a day or more*, which sends somebody to
look at a claim rather than telling them the act. Measured: three units parked on a human act,
queued since 2026-08-18, 2026-08-19 and 2026-08-26, none mentioned to the account holder since
the hour each routed.

**Which sibling it follows, on each axis:**

| Axis | Follows | Why |
| ---- | ------- | --- |
| whose question | `stalled-units` | the **claim holder** drove this unit and is the person who can run the declared verification or hand it on |
| the running identity | `undrivable-units` | never consulted — the claim's own `author` is the addressee, so an hourly repository-scoped question does not answer differently per account |
| what it may read | `undrivable-units` | `list-claims.sh` is a pure read; **`plan-units.sh` is refused**, because the survey reaches the mission readers, which carry the living migrations and **stage** what they converge — the composition `closable-missions` already refused |

**The question names the declared reason verbatim**, which is the whole point of the step: a
boolean says a unit is waiting, only the string says what for. It is resolved per candidate by
`drive/scripts/declared-handoff-detail.sh`, which composes `verification-handoff.sh` — still the
**one** reader of the field — over the set `claims_remaining_tickets` already derives, so this
reading and the oracle's cannot answer from two different ticket sets. Resolving it **per
candidate rather than on every claim row** is deliberate: `stalled-units`, `undelivered-units`
and `retire-claims` all read `list-claims.sh` and none of them wants the string.

**The pull request's coordinates cost one lookup per candidate**, through `claim-merged.sh`. An
`unanswerable` read leaves them unstated and **keeps** the candidate — the unit waits on a person
whether or not we could name its URL. A candidate whose declared **reason** could not be resolved
is counted in the summary and **not** asked about: asking somebody to satisfy a verification
nobody named is worse than not asking.

**The summary carries no age and no timestamp**, for the correctness reason `stalled-units`'
header records: an incrementing age would make this step changed hourly by construction.

**The event is supplied only where a standing handoff was found**, and it names the repository
event rather than the step's counters: *a finished unit is waiting on a verification only a
person can run*. The `ok`-with-nothing path and every degraded path leave it **empty**, so the
renderer emits no line at all — the independent guard against a nothing-happened line reaching
the root even when the diff calls the step changed. The declared reason and the pull request stay
**out** of it: the root line links the item and the question beneath it carries the detail, and a
root line that restated the question is the duplication the two-speech-act design exists to
avoid. Once the `handoff-unit:<unit>` key is spent, later ticks still see the finding — and
render nothing, because a change is a **diff** against the previous tick's summary for the same
step, and an unchanged standing handoff produces an unchanged summary. That is what keeps a
standing handoff from becoming the hourly restatement `📦 Release Preparation` was retired for.

**It asks and nothing else.** `awaiting_verification` is a **judgement**
(`workaholic:drive`'s `reference/claims.md`, *Proofs and judgements*), so nothing here clears a
handoff, retries a verification, merges or closes the pull request, touches the claim, or
withdraws the declaration — and the field keeps its two writers, `/ticket` and `/specificate`,
with a run never declaring it for its own unit. Each question is keyed `handoff-unit:<unit>`
through `ask-question.sh`, so the asked-once gate, the per-tick cap, the quiet hours and the
working-day hold all apply unchanged and no second ledger exists. `stalled-units` filters the
same verdict out of its own candidates and counts it instead, so one unit never produces two
questions in two vocabularies. A degraded read (`no_claim_reader`, `claims_unreadable`,
`claims_unparseable`, `origin_unreachable`, `shallow_history`) is named and asks nothing.

## 22. `question-answers` — the answer a person wrote in a question's own thread

```bash
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/step-question-answers.sh --tick <id> [--root <repo-root>]
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/ask-question.sh --record-ask --tick <id> --key <key> [--log-step <step>] [--coordinate <channel>:<ts>]
```

- **Reads**: the tick log — which questions are outstanding, and the coordinate each was posted
  at. Nothing else, and no network.
- **Writes**: nothing itself. The agent writes, through `record-answer.sh` and
  `file-inbound-ask.sh`, both of them existing single writers.
- **Its `event` is always empty**, deliberately and for `unanswered-asks`' reason: when `run.sh`
  reads this step's line nobody has read any thread yet, so any event would be a claim about a
  reading not yet made. A step with no event renders no root line.

**Why it exists** (2026-08-28, mission
`let-an-answer-in-the-thread-turn-back-into-the-loop-s-work`). `record-answer.sh` had been the
only writer of the answered line since 2026-08-23 and **nothing reached it**: its documented
flow was the developer opening the session link and answering inside the moderator's own
session, which costs a session per answer. A reply typed into the `🔎 Moderation` thread —
where the question actually is — reached no writer at all. It is not a channel message, so
`unanswered-asks` cannot see it; the `:40` inbound sweep excludes answers to the tick's own
questions by rule; and `question-state.sh` therefore read `asked` forever while the person's
words sat in Slack.

**The coordinate is recorded when the question is posted, and never searched for later.** The
agent knows the `(channel, ts)` at the moment it posts, so after posting it hands that back and
`ask-question.sh --record-ask` writes the `human-checkin-ask-<slug>` line with it. That is the
same property the inbound sweep's receipt relies on — the coordinate is an input, not a lookup.
**No new store and no new field on any artifact**: both the coordinate and the content key ride
that summary as fixed tokens whose format has one home (`lib/question-coordinate.sh`), written by
`ask-question.sh` and read by `question-state.sh`. The key is recorded because the step id is a
lossy hash of it and `record-answer.sh` takes a key — it is not a second identity, since the id
is still derived from the key by `lib/question-id.sh` alone.

**The gate did not move.** `--record-ask` returns before every gate, so which questions are
asked, the per-tick cap, the daily bound, the quiet hours, the working-day hold, `already_asked`,
`answered` and the one bounded re-ask are byte-identical. **A coordinate is never load-bearing**:
a question posted without one is still asked and still gated, and reads a **named absence**
(`coordinate_reason: not_recorded`) — which is what stops a later tick searching the channel for
the thread. A malformed coordinate is **refused** (`bad_coordinate`) rather than stored, because
one recorded wrong reads a tick later as a thread with nothing in it, indistinguishable from
nobody answering.

**One thread read per outstanding question, on a coordinate already in hand.** No search, no
channel history, and `workaholic:notify`'s two-query bound is untouched because no query is made.
The set is bounded at `WORKAHOLIC_ANSWER_READ_MAX` (default 10 — the check-in's own daily bound
rather than a new constant), newest first, and the number beyond the bound is reported rather
than dropped silently. A candidate with **no coordinate** and one with **no key** are counted and
named separately; neither is searched for.

**The judgement's bar**, which lives here rather than in a script: a reply is an answer when a
**person** wrote it in that question's thread. Every post this plugin emits — the tick root, its
questions, its `✅ 解消を確認` confirmations, any finish line — is excluded **by shape**, so
**a machine's post is never an answer**. When unsure, **do not record** and say what made you
unsure: the standing bar, and here it costs one hour rather than the answer. **Nothing parses the
answer** — it is a person's prose, `record-answer.sh` stores it verbatim on one line, and acting
on it stays the next run's judgement.

**Per candidate, one outcome or the other.** Either `record-answer.sh --tick --key --answer`, or
a named not-recorded reason. A candidate handed back with no outcome is non-conformant on its
face — the enforcement the connector retry already carries, and for its reason: no mechanical
check tells a real read from a claimed one, so what this buys is that a report naming no outcome
is visibly wrong.

**The recording reaches the base** on the log's own commit: it happens after `run.sh` returns, so
`persist-log.sh`'s **second** run covers it, exactly as it covers every `<step>-filed` line. A
line that died with the container is the defect that made the tick's feedback records evaporate.

**An answer that asks for something becomes one `[FB]` issue**, through
`propose/scripts/file-inbound-ask.sh` — the writer the `:40` sweep already uses — assigned to the
running identity so the next `[Specificate]` ingests it like any other ask. **No second inbox**,
and the direction it answers rides it through `feedback/scripts/ask-feedback-line.sh`, the one
writer of that line, or no line when the answer names none. Not every answer asks for work: one
that rules on a question, declines it, or says *yes, do that* needs no issue, and the filing bar
is the feedback skill's own. Report `filed: <issue>` or `not_filed: <reason>` per answer.

**The dedup is structural, and there is no cursor.** A question in state `answered` is not a
candidate — the step's own set is the `asked` ones — so one answer is read once, filed once and
stamped once however many ticks run. The marker on the issue is the answer message's own
`slack-ref: <channel>:<ts>`, which `list-swept-slack-refs.sh` already reads back out of the issue
ledger: the **same** marker and the **same** reader, rather than a second marker with a second
reader for a dedup the state machine already provides. That the `:40` sweep then also treats the
message as captured is correct — it was.

**The stamp is a reaction on the answer message and nothing else** — the catalog names the emoji
once (`workaholic:notify`, `/moderate`'s entry) and everything else reads it from there. **No
reply is posted for this event, in any thread.** It rides the coordinate already in hand, only an
answer **this run recorded** is stamped, and it is never load-bearing: the answer is recorded and
any issue filed before the stamp is attempted, and a failure is reported `ack_failed: <reason>`
and changes nothing else. Three facts, three reports: the recording's, the filing's, the stamp's.

**What it never does.** It never posts a reply for this event, never re-asks or confirms anything
(`answered` is already its own refusal at the gate, and `✅ 解消を確認` keys on `settled`, not on
`answered` — both paths untouched), never opens an issue except through `file-inbound-ask.sh`,
never adds an edit path for a correction (a person who answers twice appends a later line and the
newest wins), and never reads a channel. The overlap with `unanswered-asks` is deliberate and must
not be collapsed: that step asks about a **channel message nobody answered**; this files an
**answer to the tick's own question**. One is a question, the other is work.

**Degradations, named one by one**: `no_log_reader`, `log_unreadable` (any refusal but an absent
log — `no_log_area` is a readable answer meaning nothing has been asked), `candidates_underivable`
from the step; `no_slack_transport` and `thread_unreadable` from the agent's read. An unread
thread is never reported as a thread nobody answered.

## 24. `standing-rulings` — the rulings the loop cannot make, drafted instead of asked

```bash
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/step-standing-rulings.sh --tick <id> [--root <repo-root>]
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/list-standing-rulings.sh [--root <.workaholic>] [--judgement <subject>=<answer>]...
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/list-open-rulings.sh
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/draft-standing-rulings.sh [--judgement <subject>=<answer>]...
```

- **Reads**: `list-open-rulings.sh` (the brake, one REST call) and `list-standing-rulings.sh`
  (the candidate set, a pure local read composing `strategy/scripts/unattributed-work.sh` and
  `workaholify/scripts/audit-identity-coverage.sh`). **Never `plan-units.sh`** —
  `undrivable-units`' rule, first recorded by `closable-missions`: the survey reaches the
  mission readers, which carry the living migrations and **stage** what they converge.
- **Writes**: nothing. The act is the agent's, through `draft-standing-rulings.sh`, and every
  artifact write there happens in a publish tree.
- **Its `event` is always empty**, deliberately and for `unanswered-asks`' reason: when
  `run.sh` reads this step's line nothing has been drafted, because the agent acts only after
  `run.sh` returns. A tick that drafted nothing therefore renders no root line — which is what
  the requirement asks for — and the drafted pull request reaches the operator as a pull
  request, the surface it is addressed to.

**Why it exists** (2026-08-28, mission `put-the-loop-s-standing-rulings-on-one-pull-request`).
Two rulings stand that the loop cannot make itself, and both were surfaced as an hourly
**question**: `direction-arrived:<slug>` names an unattributed mission, `undrivable-unit:<path>`
names an address no mapping entry covers. Each question names a repair the operator must
perform **by hand on `main`** — editing a mission's `feedback:` line, completing a line in
`.claude/git-identities` — which is the one act this repository still left to a person editing
the base directly, and exactly what `amend.sh` was admitted to remove for the strategy
artifact. Drafted as a diff instead, **merging is the ruling and closing is the refusal**.

**The judgement is the run's, and no script derives one.** Which direction a mission answers
and which account an address belongs to are readings only a person or a run can make — a script
that guessed either would be **authoring** the operator's ruling, which `carry-attribution.sh`'s
header forbids and on which this whole path rests. `list-standing-rulings.sh` therefore takes
one `--judgement <subject>=<answer>` per candidate in `survey-strategies.sh --aim-kind`'s shape,
stores the answer it was handed, and **derives none**; an unjudged candidate reads `undecided`
and reaches no writer, keeping its own hourly question. A judgement naming a subject the reader
did not surface is refused `subject_not_surfaced` — the reader's own candidate set is the
domain, and an answer outside it means the run and the tree disagree about what is standing.

**One open ruling at a time, with no cursor.** The brake is the open pull request itself, in
`list-open-proposals.sh`'s shape: from the moment a ruling opens until the operator rules on it
the gate holds, and the moment they merge it the subject leaves the candidate set by itself,
because it is no longer unattributed or uncovered. So the bound is enforced continuously with
nothing stored anywhere — a cursor is a second source of truth about what is in flight, and
this repository has refused one at every equivalent seam. **An unreadable brake drafts nothing**:
a brake that cannot be read is not a brake, and handing the operator two competing diffs about
the same subjects is the failure it exists to prevent.

**What the act may write.** `draft-standing-rulings.sh` opens a publish tree, reads the
candidate set **inside** it (so the rulings are derived from the base the pull request will be
opened against), and then:

- runs `carry-attribution.sh <strategy> <mission>` per judged mission — **unmodified**, still
  the one writer of that line, still appending only refs the named strategy already cites,
  still touching no strategy file. Its refusals (`strategy_not_found`, `mission_not_found`,
  `not_active`, `no_revision`, `immutable_field`) are reported by name and write nothing;
  `already` is a success, not a refusal;
- appends the completed `<login>=<address>` line to `.claude/git-identities` as a **live** line
  — `apply-bootstrap.sh` writes a comment because it proposes without deciding, and here the
  ruling has been made — stating in the body the **git history that supports it**. An address a
  login already names live is a no-op; a login the mapping already names gains the address as
  another of its own, because `identity.sh` takes the first row a login matches and a second
  row would resolve the address to *itself* as canonical. Every write is asserted **append-only**
  (every address named before is still named, exactly one is new) and reverted from the
  pre-image otherwise. `login_ambiguous` and `no_mapping_file` refuse by name — the file's
  absence is a **bootstrap** repair, and `apply-bootstrap.sh` owns the header it scaffolds;
- lands it through `publish-tree-pr.sh`, which **refuses to auto-merge it** (`ruling_touching`,
  derived from the tree rather than from the caller) whatever `WORKAHOLIC_AUTO_MERGE` says.

**The pull request names what it rules on, visibly**: one `ruling: <kind> / subject: <subject>`
line per drafted subject in the body, in the shape `/propose` puts `strategy: … / move: …` on an
issue. A hidden marker would be a fact the loop depends on that no human reading the pull
request can see.

**Degradations, named one by one**: `jq_unavailable`, `no_rulings_reader`, `no_brake_reader`,
`brake_unreadable`, `brake_<reason>` from the brake, and the candidate reader's own
`unattributed_unreadable:<reason>` / `identity_unreadable:<reason>`. Each drafts nothing.
