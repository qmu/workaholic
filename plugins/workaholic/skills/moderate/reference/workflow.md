# The thirteen-step contract — reference

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
missions had accumulated and nobody was told**; they were found because the mission lens printed
all of them on every prompt and the list had grown long enough to read as wrong. This step makes
the residue legible before it is large.

- **Reads**: three **pure** readers — `summary.sh` (the active set with its `checked`/`total`),
  `progress.sh` (`unlinked`) and `queue-size.sh` (the queue count, which is the reader
  `plan-units.sh` itself uses for that number). No new parser of the many-valued `mission:`
  relation, which `read-relation.sh` owns.
- **`plan-units.sh` was the obvious composition and is refused**: its `queue_drained` exclusion is
  exactly this candidate set, but the survey runs the living migrations and **stages** what they
  change — measured by this step's own test, which caught the report leaving a modified mission in
  the index. A step whose contract is *writes nothing* may not reach it through something that
  writes.
- **Writes**: nothing — no file, no commit, no status.
- **Reports** each entry with the two facts that make it closable, `checked/total` and the queued
  count, and nothing else.

**It never closes one**, even though the arithmetic is identical to the archive gate's: two writers
of an end state is exactly what `close.sh`'s single-writer rule exists to prevent, and the gate owns
the one case a machine may end.

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

**Only a `live` subject is re-asked.** `settled` needs nobody; `unknown` is a reading that could not
be made, and spending a person's attention on our own degradation is the rule `strategy-pace`
already applies to its own `unknown`.

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
- **Quiet hours: one gate per tick, in the workspace's timezone** (resolved 2026-08-17), default
  `Asia/Tokyo` 22:00–08:00, both overridable (`WORKAHOLIC_QUIET_TZ`, `WORKAHOLIC_QUIET_HOURS`).
  The per-recipient alternative — each addressee's Slack profile timezone — is more precise and
  was not taken: it costs a profile read per person per tick against a surface this project keeps
  to exact-string queries, and it buys little, because a suppressed question is **held, not
  dropped**. The gate is one function reading one zone, so it stays swappable.
- **Held is not dropped**: a suppressed question is recorded as `human-checkin-held-<slug>` and
  handed back by this step on the next eligible tick; it drops out once it has been asked.
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
novelty and no cursor is stored. **The gates are `questions >= 1` or `changes >= 1`.**

**This step is exempt from `--deadline-seconds`.** The deadline cuts steps in order and this one is
last, so a slow tick used to read nine things and say nothing — the one step whose absence nobody
can see was the first to go. By the time it runs the other steps have handed it their findings, and
asking with nine of them beats asking with none.

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

Not an eleventh step: the ten above are the contract and the log's step keys, and this is the
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
