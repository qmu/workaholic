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
`no_output`, `bad_output`, `jq_compile_error`, `no_connector`, `no_credentials`, `no_strategies`,
`unreadable_inbox`, `quiet_hours`, `already_filed`.

**`needs_agent` is the seam between the script and the model.** A step script is non-interactive
and composes no prose: it probes, it decides, and where the action is mechanical it files through
an existing seam itself. Anything that needs *composition* (an issue body, a question, a proposal)
or a *human surface* (Slack) is returned here, and the agent acts on it afterwards through the
seam this file names for that step — recording what it actually did under the step id `<step>-filed`.

---

## What a `summary` may carry — the rule, and the audit behind it

**A summary is compared, so it carries what moved in the repository; a transport's answer belongs
on the `headline` or in `needs_agent`.** That is the whole rule, and it is here rather than in one
step's header because it binds every step written after it.

`render-tick-post.sh` compares `(step, status, stabilized summary)` against the previous tick's —
twice: once for the change diff that decides whether an hour has anything to say, and again over
the `degraded` and `blocked` rows for the impairment diff. `stabilize()` strips an ISO timestamp,
a bare hex object name of seven characters or more, and a clock time, and **nothing else** — its
own header explains why that list is short and named rather than a general scrub. So any other
value a summary interpolates is compared verbatim, and a value an API recomputes between two
identical reads makes the gate built to stop hourly noise the thing producing it.

The distinction is **where the number comes from**, not what type it is:

- a **repository** fact is one the tree, the log, the claim scan or a local `git` derivation owns
  — a count of queued tickets, a mission slug, a pull request's open/closed state, a conflict
  class computed by `merge-tree`. It moves when the repository moves, and it *should* speak.
- a **transport** fact is one a remote service recomputes on its own schedule — GitHub's lazily
  computed `mergeable` above all, and whether a bounded fetch happened to succeed. It moves with
  the repository standing still.

### The audit (2026-09-01, ticket `20260901122448-name-every-step-summary-carrying-transport-derived-volatility`)

Every one of the thirty-four `step-*.sh` summary compositions was read. Each is a literal format
string over named shell variables, so **none is unauditable** — there is no step whose summary is
built by interpolation this audit could not follow, and none is recorded as unaudited.

Three carried a transport-derived term. All three are repaired; every other step is cleared.

| Step | Verdict |
| ---- | ------- |
| `stuck-prs` | **repaired** — carried the `<number>:<blocked_by>` pair list. Now the count and class set only (ticket `20260901122448-keep-a-transport-derived-state-list-out-of-the-post-gate`). |
| `merge-conflicts` | **repaired** — carried `N not yet computed by GitHub`, which is `mergeable == null` and nothing else. The count stays on the `uncomputed` field and the note moved to the `event`. |
| `release-status` | **repaired** — its `blocked` row carried `(refs: fresh\|stale)`, a word set by whether one bounded fetch succeeded. A doubtful read already has its own `degraded` row, which is where a reader learns it. |
| `base-health`, `drill-health` | cleared — a check-run *conclusion*, not a lazily computed field: it does not flip between two identical reads, and when it does flip a check really was re-run. |
| `stranded-publications`, `stalled-units`, `undelivered-units`, `handoff-units`, `raced-units`, `retire-claims` | cleared — every count comes from the claim scan and `claim-mergeability.sh`, which is a local `merge-tree` with no network. |
| `closable-missions`, `undrivable-units`, `direction-health`, `date-will-not-hold`, `strategy-pace`, `doc-drift`, `thread-reconcile`, `standing-rulings`, `file-findings`, `question-answers`, `unanswered-asks`, `blocked-tick`, `cadence-lapse`, `human-checkin` | cleared — tree, tick log, or this loop's own gate words. |
| `unrecorded-missions` | cleared — the tree terms are the tree's, and a pull request's closed/unmerged state is a repository fact GitHub stores rather than recomputes (`issue-triage`'s row, for its reason). |
| `issue-triage`, `operator-pulls` | cleared — an issue's or pull request's open/closed state is a repository fact GitHub stores rather than recomputes. |
| `inbound-sweep`, `strategy-digest` | cleared, with a caveat named rather than repaired: both are **window-relative**, so their counts move as the window slides. That is clock-derived, not transport-derived, and in both cases the movement tracks activity that really happened. |
| `note-cadence`, `workload-logs` | cleared, with the term to watch named: `note-cadence`'s *due* is a JST-day boundary over a draft release CI alone writes, and `workload-logs`'s `readable` is an environment capability. Neither recomputes remotely today; a target whose log endpoint flaked would make `readable` the fourth finding. |
| `open-log` | not compared at all — `render-tick-post.sh` skips it by name, so its day-file path cannot open a root. |

**What the audit did not do**: it invented no repair to justify itself, and it left `merge-conflicts`'
`(#12, #13)` list and `stuck-prs`' `headline` exactly where they are — those name which pull request,
which is a repository fact. Whether a change *line* may name an identifier is a separate rule
(`CLAUDE.md`, an event names no identifier) and a separate ask.

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
- **And the conversion validates** (2026-08-26, `lib/tick-iso.sh`, shared with step 7). The log is
  append-only and carries whatever any tick ever wrote, so the tick id it hands back is an input,
  not a guarantee. Measured: a sentinel section `## 20260819-999999` sat on the base; `999999`
  sorts last, so it won every window from that day, the unvalidated substitution produced
  `2026-08-19T99:99:99Z`, and GitHub answered `422 The since parameter needs to be in ISO 8601
  format` for **seven days** while this step reported itself `ok`. An id that does not validate now
  widens the window to the tick's own day start and **names the widening in the summary** — one wide
  window instead of seven silent days. Nothing prunes the log to fix it: it is append-only, and a
  machine deleting a line it disliked is a worse failure than the one it would cure.
- **A failed read is not an empty one, and never a finding** (same change). The transport's exit
  status was swallowed by `|| true`, and the error body reaching stdout was parsed as a row — so the
  422 document was handed to the agent as an inbound ask "to judge", with itself as the reference.
  The status now decides whether the read happened, and a row whose issue number is not a number
  means the response was not the issues list: both are `degraded`/`gh_read_failed`, by name.
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
  still handed over — three of four working is not "nothing found"), `gh_read_failed` (the endpoint
  did not answer, or did not answer with issues), `bad_window` (neither the previous tick nor this
  one is a timestamp — the one case where no window can be derived at all).
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
- **And a `null` gets ONE second look before either step sees it** (2026-09-01, ticket
  `20260901082631`). Requesting the pull request is what *schedules* the background merge job,
  so the tick's own first per-pull read is systematically the one most likely to answer `null`:
  measured (issue #838), four pull requests reported `unknown` hour after hour and a hand read
  settled all four on the first try, because the hand read was the **second** read. The reader
  waits once (`WORKAHOLIC_PULLS_STATE_REREAD_WAIT`, default 2s) and re-reads the `null` rows
  **once** — never a retry loop — bounded by `WORKAHOLIC_PULLS_STATE_REREAD_MAX` (default 5
  rows) and `WORKAHOLIC_PULLS_STATE_REREAD_BUDGET_SECONDS` (default 10s in total), and reports
  the spend as `reread_attempted` / `reread_settled` / `reread_capped` so a tick that spent the
  budget and learned nothing says so. It lives in **`pulls-state.sh` alone**, so both steps
  inherit the settled answer and **neither gains a network call of its own** — a step-level
  re-read would re-open exactly the drift the per-tick cache below exists to close. A row still
  `null` after the second look is still `unknown`, and `uncomputed` still counts it.
- **Resolved once per tick, used twice — and since 2026-08-29 actually so** (ticket
  `20260829092043`). That sentence stood under step 6 while both steps called the reader
  themselves, so a tick made two rounds of per-pull reads. Because `mergeable` is computed
  lazily and *requesting* the pull request is what schedules the job, the two rounds can
  disagree: measured on tick `20260829-085055` (issue #710), this step reported `none
  conflicted` while step 6 named four — #622, #625, #633, #688 — over the same open set, with
  neither wrong about what it read. `run.sh` now resolves once before the step loop and names
  the file in `WORKAHOLIC_TICK_PULLS_STATE`, and **`pulls-state.sh` is what consults it**, so
  both steps stay byte-identical and the property belongs to the one reader rather than to each
  caller's memory. A step run standalone sees no variable and resolves for itself; the cache is
  keyed on the `--limit` it was resolved at, so a wider read is never served a truncated answer;
  and a failed resolution is never cached, because one transport hiccup must not become the
  tick's answer for every consumer.
- **A FOURTH outcome, named rather than folded into the zero** (2026-08-29, ticket
  `20260829092046`): `uncomputed`. This step counted only `conflict` rows, so a tick that could
  not look and a tick that looked and found nothing both reported `none conflicted`, in the
  voice of a completed reading — the *found nothing* versus *could not look* collapse repaired
  by name in `attributed-work.sh`, in the three-valued merged lookup and in
  `ci-retirement-turn.sh`. A tick with uncomputed rows now names how many, and never says
  `none conflicted` about them; a tick with neither conflicts nor uncomputed rows keeps the
  earlier wording byte-identically. It is **`ok`/`mergeability_uncomputed`**, deliberately
  neither `degraded` (which names a transport this step could not read, and the transport
  answered) nor `blocked` (which asserts a conflict nobody proved, and would send a claim holder
  after one). It adds **no `event`**, so the posting behaviour below is unchanged.
- **Writes**: **nothing to any branch, and no post of its own.** The finding rides step 6's
  reminder; two Slack lines about one pull request in one tick is the noise a gated post exists
  to prevent.
- **It does not rebase** (resolved 2026-08-17, the ticket's Open Decision). A `work-*` branch
  **is** a claim — the heartbeat is its tip and `archive.sh` pushes it after each archive commit —
  so a third party rebasing it races the claim holder's own pushes and can strand or duplicate a
  unit; it is one of the three unit-less writer designs `workaholic:ship` §7 measured and refused.
  Rebasing only *unclaimed* branches would need a staleness rule the claim protocol deliberately
  refuses to have (it reports staleness and never acts on it), and rebasing anything accepts the
  race knowingly. **This step still rebases nothing, and that bound is unchanged** — what changed
  on 2026-09-02 (mission `resolve-a-conflicted-pull-request-in-the-tick-not-report-it`) is where
  the repair goes. It used to be assigned to the **claim holder**, and the operator's correction
  was that this is wrong because a claim holder never comes: parked pull requests read as
  progress to the loop and as stagnation to them. The repair belongs to the next **`[Implement]`**
  tick, which attaches the branch's own worktree and **merges** — never rebases, so the race this
  bullet is about does not arise — through `catch-up-claim.sh` and
  `settle-stranded-publication.sh`, on this identity's own claim and never a colleague's. Only a
  hunk the merge itself cannot settle reaches a person, and it reaches them by name.
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

- **Reads**: `pulls-state.sh`, as step 4 does — resolved once per tick, used twice, and since
  2026-08-29 held by the reader rather than by each caller (step 4's entry carries the
  measurement and the seam).
- **Every row names the decision, not the colour**: `conflict` → the next `[Implement]` tick's
  catch-up clears a generated-index conflict, a real content collision is the claim holder's and
  nobody else may push to that branch; `review` → a required review or gate is unsatisfied;
  `checks` → the author must fix a failing check or say it is expected; `draft` → mark it ready or
  close it; `behind` → the claim holder must update it.
- **An `unknown` row leaves the pass and is counted instead** (2026-09-02, mission
  `resolve-a-conflicted-pull-request-in-the-tick-not-report-it`). `pulls-state.sh` answers
  `unknown` for `mergeable == null` — GitHub has not finished computing it — which says nothing
  about the pull request and everything about when we asked, and the only "act" it ever named
  was *re-read before acting*, which is nobody's. The operator ruled it not worth a
  notification. It is filtered at **candidate selection**, not at the post: `ask-question.sh`
  records a key as asked when the question is composed, so a post-time filter would leave the
  key spent while reaching nobody. It leaves the `ask_key` digest with it, so an uncomputed row
  can never change the key of a question about a different pull request. A pass holding **only**
  uncomputed rows reports `ok`, never `blocked` — a `blocked` row with no candidate renders an
  impairment line in the root about something nobody may act on. The count survives on the
  step's own **`uncomputed`** field, and deliberately not in the compared summary, on
  `step-merge-conflicts.sh`'s 2026-09-01 measurement: that string is compared for the impairment
  diff, so a count GitHub moves on its own schedule would open a root every time it settled one
  pull request.
- **The heading names the kind, the key does not move** (2026-08-18, issue #513). `headline` is
  derived from the same `blocked_by` set — `conflicting with main`, `waiting on review`, `with a
  failing check`, `still in draft`, `behind main`, and
  `stuck: <kind>, <kind>` when one post covers several (the `with mergeability not yet computed`
  heading is retired with the row it named) — and the `🔧` post's first line carries it,
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
- **The `conflict` row names which actor clears it** (2026-09-01, ticket `20260901082633`). It
  read *the claim holder must resolve the conflict* for **every** conflict, so the one class the
  loop repairs itself — a collision confined to the generated OKF indexes, settled by
  `catch-up-claim.sh` from `/implement` and by `settle-stranded-publication.sh` for a
  publication — was announced to a person as theirs, and queued behind a budget of ten questions
  a day. Measured: four conflicting pull requests, all four colliding on
  `.workaholic/stories/index.md`, two of them on nothing else. The correction is **generic
  rather than per-row, by constraint**: the class lives in `claim-mergeability.sh`, which needs
  the branch ref, and this step reads GitHub over REST through `pulls-state.sh`, which carries
  no class — a per-branch judgement here would need the fetch step 4's header refuses. The
  per-branch judgement therefore belongs to `/implement`'s catch-up, which reads the class off a
  claim row that already has it and **attempts** it (`catchup-blocked` was retired 2026-09-02:
  the tick resolves and merges rather than handing a conflict to a claim holder who never comes). **Wording only**: `stuck:<digest>`, the `blocked_by` set,
  `headline` and the `needs_agent` shape are byte-identical.

**The question, under the composition contract** (2026-08-31, mission
`make-the-tick-s-questions-readable-and-close-them-in-the-thread`). This step is the one that
already met it, and the reason is worth naming: `headline` is derived from the *reason* rather
than from the identifier, so the post opens `conflicting with main` and not `#642`. Heading —
the `headline` above, then the pull requests it covers. Body — the act that row's `blocked_by`
already names (the catch-up clears a generated-index conflict and a content collision is the
holder's / review it / fix the check / mark it ready / update it / re-read). `stuck:<digest>`
is a **dedup key and never a heading**: the contract's clause 3 in its oldest form.

## 7. `doc-drift` — the documentation against the current concept

- **Reads**: `story/scripts/doc-drift.sh` (structural presence changes versus the documents that
  enumerate them) and `story/scripts/area-freshness.sh` (a hand-maintained record naming something
  this repository retired). Reused, not re-implemented.
- **The window is a git question**: the base is `git rev-list -1 --before=<the previous doc-drift
  tick, as ISO> HEAD`, so no `date -d`/`date -v` arithmetic is involved. `no_baseline` when nothing
  precedes that boundary — comparing against nothing would report every document as drifted.
- **The conversion is `lib/tick-iso.sh`'s, shared with step 2** (2026-08-26). The same sentinel tick
  id blinded this step too, and more quietly: the sweep at least got a 422, while `git rev-list
  --before=2026-08-19T99:99:99Z` simply matched nothing, so this step answered `no_baseline` — a
  legitimate answer on a young repository — for seven days without one document being checked.
  Sharing the derivation is the point: two copies of an unvalidated substitution is how one poisoned
  log entry took out both steps. An unusable previous tick widens to the day start and says so;
  `bad_window` is the abort when even that is not a date.
- **Writes**: nothing. Drift becomes a **ticket**, because fixing documentation is work and work
  has a queue; an hourly agent rewriting `main`'s documents is the unattended-write class this
  project has refused twice.
- **Dedup is not optional here.** `terms/retired-terms.md` is a glossary *of* retired terms, so it
  names retired terms by construction and `area-freshness.sh` reports it truthfully and forever.
  A finding an earlier tick logged under `doc-drift-filed` is counted and dropped.
- **Aborts**: `no_repo`, `no_baseline`, `bad_window`, `drift_unreadable`.

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

**The question, under the composition contract** (2026-08-31, mission
`make-the-tick-s-questions-readable-and-close-them-in-the-thread`; the contract is
`workaholic:notify`'s, beside the `🙋 <@U…>` shape). Keyed `strategy-pace:<slug>`.

- **Heading** — *nothing has landed on `<title>` for as long as it has left*, then the slug, the
  declared stage and `days_to_target`. Never `strategy-pace:<slug>` or the bare word `late`:
  `late` is this repository's derivation, and its plain fact is the sentence above.
- **Body** — the one act: *re-plan it, re-date it, or say it is fine as it is.*

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


**And each candidate carries how long it has been ASKED ABOUT** (2026-08-30, mission
`say-how-long-the-loop-has-been-stuck`). `moderate/scripts/condition-age.sh --key <the key this
step already composes>` answers `first_seen` / `ticks` / `truncated` / `first_seen_is_floor`, or
a named `readable: false`, from the question ledger those keys already write. The reading rides
`needs_agent` **only** and its words are carried **verbatim** — a normalised word sends a reader
to a string no script printed. An unreadable age is named as unreadable and **never rendered as
*this just started***, which is the collapse the reading exists to close. **No key moves**, so
`already_asked` is byte-identical and the changed wording re-asks nothing, and **the summary does
not move either**, for the correctness reason recorded above.

**Two ages ride this question and they are TWO FACTS.** `stalled_hours` is how long the claim
**tip** has not moved (`WORKAHOLIC_CLAIM_STALE_HOURS`, the protocol's own threshold); `age` is how
long we have been **asking**. They are named as two with their sources and never blended into one
number, and `step-operator-pulls.sh` deliberately keeps reading `created_at` alone —
`drive/reference/claims.md`'s source table records every row and the pin checks it both ways.

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

**And a `stranded` claim is a fact with another step's question on it** (2026-09-02, ticket
`20260831203454-tell-a-person-about-a-stranded-claim-branch`). Its tickets are archived on the
base while its branch still holds content found on no other ref: it has not *stalled*, it has
been **orphaned**, and *a claimed unit has not moved for a day or more* sends a person looking
for a run that died when what they must rule on is work nobody can reach. `retire-claims` asks
it, naming the files; this step filters and **counts** it (`N stranded (tickets archived, branch
still holds work)`), the same half of the same rule `superseded` and `awaiting_verification`
already follow — **one step asks and the other filters, and either half alone is a defect.**

**And a claim the RETIREMENT PATH already owns is a fact with no question on it at all**
(2026-09-02, mission `retire-a-claim-whose-work-is-finished-or-abandoned`). The same argument as
`superseded`, extended to the classes that joined it: measured, the operator closed a pull
request and closed its mission `abandoned`, and this step asked them about that branch every hour
until they deleted it by hand — a question asking a person to do the tick's own job. The set is
**composed** from `drive/scripts/list-retirable-claims.sh`, never re-derived: its four classes
(`superseded_only`, `pull_request_merged`, `pull_request_closed_unmerged`, `mission_not_active`)
are defined once, and restating them here would be two definitions of one set. What was
subtracted is **counted** in the summary (`N already owned by the retirement path`), because
filtering is not silence. **An unreadable retirement read filters nothing** and says so in the
summary: a gate that cannot be read is not a gate, and an over-eager question beats a silently
dropped one. **It is read only when there is something to subtract from** — the retirement
reader makes its own claim scan and a bounded pull-request read per `work-*` ref, and a
subtraction over an empty candidate set changes nothing — so the common tick, with nothing past
the staleness threshold, pays none of it.

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

**The question, under the composition contract** (2026-08-31, mission
`make-the-tick-s-questions-readable-and-close-them-in-the-thread`). Keyed
`stalled-unit:<unit>`, unchanged.

- **Heading** — *nothing has moved on the work claimed for `<unit>` in `<n>` hours*, then the
  unit, its branch, and the two ages as **two facts with their sources** (the claim tip's
  staleness; asked about since `<first_seen>`, `<n>` ticks). The measured pre-contract wording —
  `a claimed unit has not moved for a day or more`, with the unit id leading — named the
  mechanism and not the thing: a reader had to know what a claim is before the sentence meant
  anything.
- **Body** — the one act: *pick it up again, or release the claim so somebody else can.*
- **Never alone**: `queue_drained`, `parked_with_pr`, `report_incomplete`. Each may ride the
  heading beside the plain fact it stands for, and none may stand in for it.

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

**The near miss, since 2026-09-01** (ticket
`20260901123357-name-a-mission-at-full-acceptance-with-tickets-left`). The close needs **both**
terms — acceptance fully checked **and** the queue empty. A mission at **full acceptance with
tickets still queued** fails the second, so it is closed by nobody and stays active indefinitely;
measured on the day this was filed. Whether those leftovers are work that still matters or work
the mission's own landed changes have mooted is a **judgement**, so the loop may not close the
mission and may not retire the tickets — what it can do, and did not, is say so.

- **It is a question, not a second act.** `close.sh` stays the only writer of an end state,
  `archive.sh` still closes only `achieved`, and the leftovers are named and left exactly where
  they are. Nothing is closed, retired, abandoned, iceboxed or moved by this half.
- **It is the same scan, not a second one.** Both readings fall out of the one pass over
  `summary.sh`'s active set the step already makes: a near miss differs from a closable mission in
  exactly one term, the queue. No reader is added and nothing is walked twice.
- **An unreadable reading yields neither a close nor a question** — the existing rule that an
  unreadable reader is not a proof, applied in both directions.
- The candidate carries the age through `lib/read-age.sh`, keyed on the key the row composes, as
  its sibling steps do: the reader's words verbatim, an unreadable age named as unreadable.

| Key | Heading leads with | Body asks for |
| --- | ------------------ | ------------- |
| `mission-leftovers:<slug>` | *every acceptance item `<title>` promised is checked and it still has `<n>` tickets queued* — then the slug, the counts | *rule whether those tickets still matter, or whether the landed work has made them unnecessary.* |

**What the ask wanted and this does not give, deliberately.** The ask was that the planner "close a
mission, merge two, retire a ticket that landed work has mooted". Closing on arithmetic already
happens, above. *Merging two missions* has no writer and asserts intent; *retiring a mooted ticket*
requires judging that landed work covered it, which is a reading about behaviour rather than a file
test — a shape this repository has refused before. Both would need their own measured ask. Naming
the case is the honest first step and is what unblocks a person today.

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
`notify/reference/notifications.md` and the copy in `/moderate` stay byte-identical (the shapes
left the routine template on 2026-09-01 — `workaholic:notify`, *The command is the ceiling*).

## 12a. `unrecorded-missions` — the pull request was closed, so nothing recorded the work

```bash
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/step-unrecorded-missions.sh --tick <id> [--root <repo-root>]
```

**§12's photographic negative** (2026-09-02, ticket `20260902065500`). That step's proof is
arithmetic — `checked == total`, `unlinked == 0`, an empty queue — and these missions satisfy
none of it: acceptance `0/N`, nothing ticked, the queue still full. **Measured 2026-09-01/02**:
three missions read `status: active` with `0/3` acceptance and **17 queued tickets** between
them, the `/implement` survey offered all three, and the behaviour each asked for was already on
`main` — put there by a person's own single commit while the loop's own pull request was closed
unmerged (#790/#789, #801/#800, #802/#800). Only the **bookkeeping** is missing: no branch
archived the tickets, so no seam ticked the acceptance and `close.sh` was never reached.
Drivability is *active area + plan + queued tickets*, and all three terms still hold — so the
loop is queued to re-implement `main`.

- **Reads**: `summary.sh`, `progress.sh`, `queue-size.sh` and the mission's own `## Changelog`
  from the tree; then **one** bounded `branch-pull-request-state.sh` read per mission that
  passes all four tree terms. `list-claims.sh` is read once for the whole step, as the second
  branch source below.
- **Four tree terms, then one read**: `active`; acceptance entirely unticked (`checked == 0`,
  `total > 0`); the changelog records **no archived ticket**; and the queue is **non-empty** — a
  drained one is §12's candidate or nobody's. Only `closed_unmerged` is a candidate: `merged` is
  work that landed and `open` is a unit still being driven, and each is **counted** and named by
  nobody.
- **The branch is resolved from two sources, and the second is why the step works at all.** The
  ticket says *the mission's recorded `claim:` branch*, and `claim.sh` does write that field —
  **on the claim branch**. A branch closed unmerged never reaches the base, so for precisely
  these missions `main`'s copy carries no `claim:` line: all three measured missions read
  `status: active` with no `claim:` field. The field is read first, the claim oracle's own row
  for the unit second. When **neither** resolves — closed unmerged *and* since deleted, which is
  what CI's retirement now does — the mission is counted **`claim_branch_unresolved`** and asked
  about by nobody. A named absence, never a candidate: this step may not name a mission whose
  pull request it never read.
- **Question key**: `unrecorded-mission:<slug>`, addressed to the mission's **assignee**, asked
  once. Lead with what happened, the slug after it, one act named: close it, or drive it again.
- **Writes nothing, closes nothing, excludes nothing, touches no claim.** `close.sh` writes
  `abandoned` and `carried` on a person's intent alone, and an automatic exclusion would hide a
  mission whose work genuinely still needs driving. The available reading is *the acceptance is
  unticked and the queued tickets describe behaviour the base already has*, whose second half is
  a **judgement about behaviour** — and `list-stranded-publications.sh`'s history records a
  survey-side *already implemented* test refused by name for exactly that reason.
- **A degraded read is named**: an unreadable pull request makes the step `degraded` with reason
  `pull_request_unreadable`, and it is never rendered as *nothing to close*. Candidates the step
  **did** prove are still handed over — losing a question because a different mission was
  unreadable trades one silence for another (`cadence-lapse`'s rule, applied here).

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
  | `all_held` | every candidate is refused by `quiet_hours`, `off_day` or `tick_cap`. **Each held entry carries the gate's own refusal word, verbatim** (2026-08-31) — the four call for four different acts, so the aggregate is the summary and the detail sits beneath it |
  | `all_asked_before` | every key that was ever held has since been asked |
  | `no_candidates` | the genuinely quiet hour |

  **Whether the tick could deliver is asked of the gate, not re-derived here**: an
  `ask-question.sh` probe **per held candidate** (2026-08-31, superseding the single probe on a
  key unique to the tick), recorded nowhere, so the day's arithmetic keeps one home and this
  step cannot disagree with the gate the agent is about to run. **`ask-question.sh` is not
  modified by the reading** — no key, cap, hold or ledger line moves, and the probe is its
  read-only mode. Two of the four words (`quiet_hours`, `off_day`) are tick-wide and repeat on
  every entry; that is the true answer and is reported rather than collapsed, because the cap
  words are not tick-wide and one shape has to cover both.

  **And the arrears say how deep and how old they are** (2026-08-31, mission
  `say-when-the-check-in-queue-is-stuck-and-bound-the-hold`). `held_oldest_day` is the
  **minimum** of the first-held day the drain ordering already derives, over the keys **still**
  held, and `held_days` is the whole-day distance from it to the tick's own day (from the tick
  id, on `ask-question.sh`'s own axis; the distance is civil-day arithmetic in `awk`, because
  `date -d` is GNU-only and `date -v` is BSD-only). No second walk of the log, no cursor, no
  store, and `log-read.sh` is untouched. A degraded read reports **null** for both, never `0` —
  a zero reads as *this just started* for a reading nobody made.

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

  It is supplied for `cap_spent` and `cap_unbounded` — the two states where the tick was
  eligible to ask and structurally could not — and, since 2026-08-31 (mission
  `say-when-the-check-in-queue-is-stuck-and-bound-the-hold`), for an **`all_held` tick whose
  arrears outlived the designed hold**. That case was excluded on the reasoning that the quiet
  window and the off day are the *designed* hold and are already named in the log, which is
  right for one tick and wrong across days: measured, **24 consecutive ticks** reported
  `all_held` with 13 questions behind them while the roots read `1 question(s)`.

  **The bound.** An `all_held` tick supplies an event once `held_oldest_day` predates the
  **working-day boundary** — the first hour inside `WORKAHOLIC_WORK_DAYS` at the end of
  `WORKAHOLIC_QUIET_HOURS`, in `WORKAHOLIC_QUIET_TZ`, exactly as the red-alert cool-down's
  expiry composes it, and from **no constant of its own**. The event names the **depth** and
  the **age**; a hold *inside* the boundary supplies none, and a **null** reading (a degraded
  log) supplies none, because a reading we could not make is never dressed as one we did. It is
  supplied on the `off_day` and `quiet_hours` branches as well as the `ok` one, because that is
  where a weekend's and a night's arrears actually sit. **The refused alternative** was an
  escalation after N ticks: N is a tunable constant this repository refuses by name, while the
  working-day boundary is a derivation whose three terms were already justified.

  **What did not move**: the question keys, the caps, the holds, `ask-question.sh`, the
  renderer's diff rule, and which questions are asked and when. Only what the root *says*
  changed. Every other case still supplies none and therefore renders no line: a genuinely
  quiet hour, `all_asked_before`, the degraded read, and a tick that delivered questions, which
  needs no event because the questions are the delivery. `cap_spent` is worth a line even
  though the budget worked, because a reader has to be able to tell it from `cap_unbounded`.
  The line names **no dedup key and no mention token**, and it is a function of the reading
  alone, so two consecutive ticks with the same reading render one line.

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

1. Render the post: `run.sh`'s JSON | `render-tick-post.sh --tick <id> --root <repo-root> --questions <n>`.
   It returns `post`, a `reason`, the `changes[]` it found, the `impaired[]` steps it could not
   read, the `token` the lookup searches, and **two forms off one body** — `root_text` (head plus
   body) and `reply_text` (the body alone, no head).
2. `post: false` ⇒ **post nothing**, whatever the reason (`idle`, `no_previous_tick`, `no_log`,
   `no_rows`). Report the reason in the run. `reply_text` is empty on every silent path exactly
   as `root_text` is.
3. `post: true` ⇒ **resolve the day's standing root first**, by the stateless exact-string lookup
   in `workaholic:notify`, searching the rendered `token` (`` `tick-day:<YYYYMMDD>` ``) and nothing
   else. It names the **day**, not the tick, so every speaking tick of one day resolves one thread.
   - **found** ⇒ post `reply_text` as a reply into it, and no root. The head restates the day and a
     reader following one thread has already read it.
   - **not found** ⇒ the day's first speaking tick, or a channel whose history the search cannot
     reach: post `root_text` as a top-level message carrying the token and the session URL.
   - **`token` empty** (an unreadable tick id, named in `token_reason`) ⇒ post the root, unthreaded.
     A key derived from a date the tick could not read would thread an hour into the wrong day.

   Either way, post each cleared question as a **reply into that thread**, carrying the person's
   `<@U…>` and `` `ask:<key>` `` — and no session URL, which the root already carries. Report per
   tick which it did (`root` / `reply`) and the surface that carried it, so a tick that fell back
   to a root is visible in the run report rather than inferred from the channel.

   **The delta reply carries no mention token**, exactly as the root does not: a change line names
   a repository event and asks nobody for anything, and the mention belongs on the question, which
   now sits in the same thread.

**The root rides the connector; a question whose mention resolves to the poster rides the bot**
(2026-08-31, mission `notify-the-person-a-directed-question-addresses`). This question is the
one shape whose entire purpose is to reach a named person, and it is why the `🙋` line keeps
its `<@U…>` unconditionally where every other shape dropped one. In the single-developer
configuration — the normal one — that token resolves to the account the post is made as, and
**Slack notifies nobody of their own message**: the loop's blockers reached the operator only
when they happened to reread the channel. The carrier rule is `workaholic:notify`'s
(*Which transport carries which shape, and why*) and is not restated here; what this step owes
it is the mechanics:

- **The root is always the connector's.** It is a top-level post, it needs no mention, and the
  connector is the transport this tick already holds. Nothing about step 1 or 2 moves.
- **The coordinate is already in hand and no query is added.** The connector returns the root's
  `(channel, ts)` when it posts it — the same fact `--record-ask` has recorded per question
  since 2026-08-28, which is what proves the timestamp is an *input* here and never a lookup.
  Hand that `ts` to `notify-slack.sh --thread-ts <ts>` and the bot's reply lands **inside the
  tick root's thread**, so the two speech acts stay told apart by position exactly as they are
  now. The two-query lookup bound is untouched: no search happens on this path at all.
- **With no bot token, post through the connector exactly as today.** `notify-slack.sh` answers
  `no_token` and exits 0; the question is still asked, still gated, still recorded. This is a
  fallback, never a drop.
- **Report the carrying surface per question** in the step's own log line — `bot`, `connector`,
  or the transport's own refusal word (`no_token`, `no_channel`, `slack_<error>`, …) — so a
  question that reached nobody is never recorded as one that did. A refusal is reported, never
  retried: the bot must be a member of the channel and `WORKAHOLIC_SLACK_CHANNEL` must name the
  channel the root was posted in, and both are **provisioning** rather than code.
- **The gate does not move, and that is checkable**: `ask-question.sh` is byte-identical, so the
  key, `already_asked`, `answered`, the per-tick cap, the day cap, the quiet hours, the
  working-day hold and the one bounded re-ask are exactly what they were. The question's wording
  does not move either — only the account that speaks it.

The cost is stated rather than absorbed: a person's own thread now carries one bot reply per
question, changing the thread's author mix. That is the intended trade — a reply nobody is
notified of is worth less than one that reaches them.

**Every root names the steps that could not read** (2026-08-31, mission
`name-the-steps-a-tick-could-not-read`). `run.sh` classifies every step
`ok|filed|skipped|degraded|blocked` with a reason and the renderer read neither, so a tick where
six steps saw nothing rendered exactly like a tick where everything was read — measured, 24 of 25
ticks in that state, found four days later by asking. `render-tick-post.sh` derives `impaired[]`
(the `degraded` and `blocked` rows in `STEPS` order, each with its own status and reason) and
`impaired_count` **on every exit path, including the silent ones**, and the root carries the count
in its head and the names in its body:

```
🔎 Moderation - <N> change(s), <M> question(s)
<the event lines>
⚠️ <step> — <status>: <reason>
```

**`skipped` is not impairment** — a step declining to run for a stated, healthy reason (`budget`,
an absent precondition) did not fail to see. **`blocked` renders beside `degraded`** under one
clause: they differ in cause and are identical in consequence to the reader.

**The clause rides OUTSIDE the diff, and that is the load-bearing decision.** A step degraded the
same way for twenty-four ticks has an unchanged summary, so the diff would call it unchanged and
the impairment would be said once and then vanish — the defect, not the fix. **It earns no post
either**: it adds a clause to a root already being posted for a question, a digest or a delivery
failure, so a tick that would have been silent stays silent and the twice-retired status root is
not reinstated. The third head term is omitted entirely at `K == 0`, so a healthy tick's root is
byte-identical to what it always was. The list names at most `WORKAHOLIC_IMPAIRED_MAX` (default 5)
steps and counts the rest as `and <K> more` — never a silent truncation, and the head always
carries the full count. No dedup key, no mention token, no session URL on the clause.

**A change is a diff against the previous tick**, read from the log; no step declares its own
novelty and no cursor is stored. **The gate is `questions >= 1`** — the changed-step half was
retired on 2026-08-22 (issue #569), because with `0 question(s)` the root is a status line
addressed to nobody. Three narrow conditions sit beside it, each OR'd next to that untouched
expression: the **morning digest** (2026-08-24), a **check-in that reached nobody**
(2026-08-28, above), and a **changed impairment** (2026-08-31).

**A changed impairment is the fourth gate**, on the third's precedent. The worst case measured is
the one where nothing posts at all: with no question, no digest and no delivery failure, a tick
with six blind steps emitted `post: false` and was byte-identical, to the operator, to a quiet
hour. **The line is outside the diff and the gate is inside it** — the impairment is *stated* on
every root and *earns* one only when it moved, so a standing impairment never opens a root of its
own after the first, which is the property `📦 Release Preparation` lacked. Appearing and clearing
both break silence; persisting does not. A root earned this way reports `reason: ready_impairment`
so a machine reading the JSON can tell it from one a question earned, and `root_text` is unchanged
either way — a clearing renders the same clause in its other state (`✅ every step read this
tick`), because a root that posts and says nothing about why is the content-free status line this
repository has retired twice.

**The comparison is a set of `(step, status, stabilized summary)`, and the third term is
mechanical**: `reason` never reaches the tick log — `log-append.sh` writes
`- <step>: <status> — <summary>` and nothing more — so the previous tick's reason is not
recoverable from the only cross-tick memory there is, and a store for it is what this must not
add. The set is strictly finer than `(step, status)` alone, so it errs toward opening a root; both
sides are sorted, so row order cannot decide it; and `stabilize` is applied to both, because two
steps embed a timestamp or a sha in their summary and would otherwise differ every tick by
construction and fire this gate hourly. It reads no age: no gate in this repository may.

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
the developer's specified form: numbered strategies, bold title on its own line, **each
strategy's missions nested under it with acceptance done/total and queued count**, headline is
`commit_count`, honesty line naming tickets, **the total queued** and the window. The render is logged
(`strategy-digest-rendered:<jst-day>`) so a second morning render is impossible; before 09:00 the
step reports `before_morning`; a no-op digest (`no_strategies` / `no_activity`) rides nothing; an
unreadable digest is `digest_unreadable`, named rather than rendered as a quiet morning.

**The digest is the root's second gate**: a morning tick with a digest posts its root even with
zero questions — the day's opening statement, the exception the developer asked for — while every
other hour the question gate stands alone.

**And the morning render carries the corpus's own mission-size distribution** (2026-09-03, ticket
`20260903053713-report-the-mission-size-distribution.md`): one line off
`mission/scripts/size-distribution.sh` — the buckets and their counts, nothing else. Rule 2 of
`rules/workaholic.md`, *What a Mission Must Be Able to Hold*, is a position about the **corpus**,
and nothing in the loop could see the corpus: the distribution that produced the rule was counted
by hand, so without a reading the next report of the defect would be another hand count.

**It rides THIS step and no hourly one.** The number moves slowly by construction, and an
unchanged answer restated every hour is what `📦 Release Preparation` was retired for — the same
reasoning the mission grain above already carries. **It gates nothing**: nothing is refused,
ordered, closed, held or sorted on it, and it is reported as evidence in the voice `pace` and the
base's own health already use. **It names no slug** — *how many* is news and *which* is a task,
and this line is addressed to nobody; the one place a slug appears is the reader's `below_floor`,
which is `layout-doctor.sh`'s advisory rather than this step's. A reading that answers
`ok: false` is named **as unreadable, by its reason**, with null counts, never as an empty
distribution, which means the opposite. The reader is **one pass** over the ticket tree
(measured 7s here against 126 missions and 1335 tickets) and composes `read-relation.sh` and
`queue-size.sh`'s own floor rather than re-deriving either.

**The plan's shape is daily, not hourly, and that is an answer rather than an omission**
(2026-09-01, mission `report-where-the-work-stands-not-only-what-is-wrong`). The ask that put
the mission grain here asked for it on **every** tick — "post where the work stands on the
ordinary tick rather than only when something is wrong". Its first half is granted: the grain,
the mission counts and `queued_total` now ride this step. Its second half is declined with its
sources, which are two roots this repository has already retired for exactly the shape being
asked for. `CLAUDE.md` (`/moderate`): *the two retired status roots stay retired — a status line
addressed to nobody is noise whatever its dedup key*; `workaholic:notify` records what `📦
Release Preparation` measured — ten lines in ten consecutive hours for one unchanged request,
none of them answered. **A plan's shape is an unchanged answer on most hours**, so an hourly copy
of it is that post returning under a new name; a *daily* one speaks for today even when today
resembles yesterday, which is the distinction the `standup:<date>` key was chosen for.

**If the operator, having read that, wants an hourly plan post, it is their call and a new ask.**
This step does not decide it for them and does not pretend the request was met: the gate, the
key, the cadence and the once-per-JST-day dedup are untouched, and nothing here posts a second
root.

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
| `arrived` **declared 進行中** (2026-08-29) | `direction-cutover:<slug>` | the strategy's `assignees` |
| `overdue` | `direction-overdue:<slug>` | the strategy's `assignees` |
| `expiring` (2026-08-29) | `direction-expiring:<slug>` | the strategy's `assignees` |
| `dormant` | `direction-dormant:<slug>` | the strategy's `assignees` |
| `dormant` **declared 改良中** (2026-08-29) | `direction-settled:<slug>` | the strategy's `assignees` |
| `none` (repository-level) | `direction-none` | nobody — there is no direction to own |
| **the last live direction** (repository-level, 2026-08-28) | `direction-last:<slug>` | the strategy's `assignees` |
| `unreadable` | — | **never asked about** |

**The two transition questions REFINE an existing one rather than adding one** (2026-08-29,
mission `make-a-direction-s-lifecycle-a-declared-stage`). The ask is that stage transitions —
*this direction can now cut over*, *this direction has settled into observation* — are worth
telling a person about rather than only the backwards alarms. They cannot be added **beside**
the existing readings: `direction-state.sh` projects `quiescent` to `arrived` and `dormant` to
`dormant` in a fixed precedence, so a 進行中 direction whose work is all in **always** reads
`arrived` and a quiet 改良中 one **always** reads `dormant` — a question added beside those
would double-ask one direction (the doubling `handoff-units` and `stalled-units` were split to
avoid) or never fire at all. So the **stage decides which question the same evidence draws**,
every other combination is byte-identical, and `direction-state.sh`'s precedence is untouched:
this is the step choosing its wording, not a sixth lifecycle value.

**The cost is stated**: the key changes for those two combinations, so a direction already
asked `direction-arrived` may be asked `direction-cutover` once. One extra question, ever, and
it is the better-aimed one.

**Neither is ever inferred from stuckness.** Both candidate sets are built only from readings
that describe **work landing** (`quiescent`, `dormant` — attribution terms), never from a
handoff, a block, a stale claim, an undelivered unit or a queue that will not drain: those
occur in **any** phase, so none of them is evidence about a stage. And both are **candidates,
never verdicts** — whether a toggle can be flipped is a fact no script can see, so the question
describes the evidence and asks; the tick moves no stage, and the artifact keeps its three
writers.

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

**A fifth reading since 2026-08-29** (mission `warn-a-direction-before-its-date-silences-the-loop`):
a direction whose date is **approaching**. Every reading above answers backwards — has the date
gone, is anything answering it, has its work come in — so a live, in-date, `on_course` direction
one day from its `target_date` produced no question at all, and the day after `past_target_date`
silenced origination with the only signal being `direction-overdue`, asked in **arrears**. The
precedent is `direction-last:<slug>`, which names the last live direction to its owner *while
they can still act* rather than announcing silence afterwards to nobody; expiry is that same
event by a different cause.

**Its heading names the days left and the date**, because a warning that does not say how long
somebody has is not a warning, and the leaving rides it exactly as it rides `arrived` and
`overdue`. Its body names the same act `overdue` names — re-date it, announce a successor when
you end it, or say it still stands — offered while it can still be taken, inside
`workaholic:notify`'s one-sentence bound. Every gate applies unchanged: the asked-once ledger,
the per-tick cap, the quiet hours, the working-day hold. **It is never held by an open ruling**,
for `overdue`'s own reason — a ruling answers which direction a mission belongs to and answers
nothing about a date. And the step **asks and nothing else**: nothing is re-dated, closed,
amended or gated, and the artifact keeps its three writers.

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

**And since 2026-08-28 an `arrived` question can be HELD** (mission
`put-the-loop-s-standing-rulings-on-one-pull-request`). The `arrived` question exists to name
the residue the reading could not see; once an open ruling pull request names **every** mission
in that residue, the diff already carries the whole ask, and the question would send the
operator to do by hand what they are being asked to merge. **All of it or none of it** — a
ruling naming one mission must not silence a question about a different one, so a partially
covered residue still asks, with its full residue named and the partial cover said in words
(*a ruling pull request is open for some of these; the rest the loop could not judge*).
`overdue` and `dormant` are **never** held: those are about the date and the silence, which no
ruling answers. The read is `moderate/scripts/ruling-suppression.sh` — one reader, shared with
`undrivable-units`, so the two steps cannot disagree — and an **unreadable** read holds nothing
(`ci-retirement-turn.sh`'s discipline). The suppression is **derived, stored nowhere**: merging
or closing the ruling makes the question reachable again with no state.

**The plan's delta rides the same root** (2026-09-01, ticket
`20260901123358-carry-the-plan-s-delta-in-the-hourly-post`). `strategy-pace` carries a `plan`
block — `advancing`, `held`, `held_reasons`, `wip` — lifted off the one survey it already makes,
and puts the same numbers in its own `summary`, because that string is what the root's change
diff compares. `render-tick-post.sh` renders one `📋` line from the block, **beside** the change
lines rather than instead of them.

- **Gated on the diff**: an hour in which the plan did not move adds no line. That is the whole
  difference between this clause and the retired `📦 Release Preparation`.
- **It earns no post**, exactly as the impairment clause does not: it adds a line to a root that
  was already being posted for a question, a digest or a delivery failure.
- **No identifier and no mention token** — *how many* is news, *which* is a task.
- **A tick the repository's `wip_limit` is holding says so**, with the count and the limit: a
  quieter loop must not be indistinguishable from a stopped one.
- **A degraded reading is named** (*the plan could not be read this tick*), never rendered as an
  empty delta — a plan we could not read and a plan that did not move are the two states the
  clause exists to keep apart.
- **What it deliberately does not say**: *which unit is next*. The executor's order is
  `plan-units.sh`'s, which no step here may reach (the survey runs the living migrations and
  **stages** what they converge), and naming a unit would put an identifier on a line addressed
  to nobody. Both rules are older than this clause and neither is worth bending for it.

**The seven questions, under the composition contract** (2026-08-31, mission
`make-the-tick-s-questions-readable-and-close-them-in-the-thread`). Every key, the asked-once
gate, the addressee, the per-tick cap and the precedence are **byte-identical**; only what the
sentences lead with moves. The stage, the residue, the leaving, the days left and the date keep
riding the **heading**, exactly as they did — the body's one sentence is reserved for the act.

| Key | Heading leads with | Body asks for |
| --- | ------------------ | ------------- |
| `direction-arrived:<slug>` | *everything the loop can attribute to `<title>` has landed* — then the slug, the declared stage, what landed and when, and the residue by mission slug | *N item(s) landed and nothing is waiting; it reads finished* (or *finished except for work no direction claims*) — then *announce that it ended, or say it still stands.* |
| `direction-cutover:<slug>` | *`<title>`'s work is all in and it is still declared 進行中* — then the slug, what landed, the residue | *can it cut over now, or is something still holding it?* |
| `direction-settled:<slug>` | *improving `<title>` has gone quiet* — then the slug, 改良中, the window nothing landed in | *is this observation now, or is there still work to do?* |
| `direction-overdue:<slug>` | *`<title>` went past its date on `<target_date>`* — then the slug, the stage, the leaving | *re-date it, close it, or say it is still running.* |
| `direction-expiring:<slug>` | *`<title>` reaches its date in `<n>` days, on `<target_date>`* — then the slug, the stage, the leaving | *is the remaining work going to land by then?* |
| `direction-dormant:<slug>` | *nothing has answered `<title>` since it was set* — then the slug, the stage, the date | *is it still the direction, or should it be re-dated or closed?* |
| `direction-last:<slug>` | *`<title>` is the last live direction, and the loop originates nothing after it* — then the slug, the stage, the leaving | *close it with a successor, or keep it open?* |
| `direction-none` | *no live direction remains, so nothing is proposing work* — addressed to nobody, because no owner is left to name | *set one, or leave the loop reactive.* |

**Three rules the bodies gained on 2026-09-03** (mission
`make-the-maintenance-tick-s-channel-presence-help-the-work-along`), each measured on one
morning's thread:

1. **One question per KIND, not per subject.** `lib/question-id.sh` keys on the key and the step
   composed one per subject, so five `🙋` went out in twenty-four seconds, three of them the same
   sentence with a slug swapped. The step now hands back **`groups`** beside `directions`: one
   entry per reading, carrying the union of the assignees and every subject. **The key carries the
   sorted subject set, not the kind alone** — a bare `direction-arrived` would be asked once ever
   and a direction arriving next week would never be asked at all, turning the asked-once gate into
   a silence. The stated cost is that a fourth direction joining an already-asked group re-asks the
   whole group once. A group of one renders exactly as it did before.
2. **The tick's own counters left every body.** `It would leave N unreached and M unclaimed.` stood
   at the head of each one: the tick saying what its counters would hold afterwards, in a sentence
   addressed to a person. The sizes still ride the **heading**, where the named detail belongs.
3. **A repository-wide fact left the four questions it is not about.** The unattributed residue —
   *not attributed to any direction: `<mission>` (N queued)* — was pasted into every heading because
   the composer had it in hand. It stays on **`arrived`** and its `cutover` refinement, where
   whether the loop could see everything is exactly the question (the 2026-08-28 mission that added
   it), and leaves `overdue`, `expiring`, `dormant` and `settled`, where it is a fact about the
   repository rather than about the subject.

**And the `arrived` body states a reading rather than offering a bare choice.** It said a count and
asked; every other part of this loop states a judgement and lets a person veto it. It now names what
landed and says whether the evidence **reads finished** — a reading, never a verdict: nothing closes
a direction but the operator announcement, and that rule does not move.

**What is refused here**: leading with `arrived`, `dormant`, `quiescent`, `expiring` or
`overdue`. Those are the loop's readings, not the operator's facts — `quiescent` in particular
means *cited, landed, nothing waiting, no date term*, which is four conditions no reader can be
expected to reconstruct from one word. Each may ride the heading **beside** the plain fact; none
may replace it. A heading is also never *still declared 進行中* for a direction carrying no
`stage:` line: absent means 進行中 for every reader in the layer and is the wrong thing to quote
back, which is why only a **declared** stage refines a question.

## 15a. `date-will-not-hold` — a direction whose board will not clear, said before the date

```bash
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/step-date-will-not-hold.sh --tick <id> [--root <repo-root>] [--open-proposals <file>]
```

**It runs immediately after `direction-health`** in `run.sh`'s `STEPS`, which is the contract.

**Why the step exists** (2026-09-01, ticket
`20260901123357-escalate-a-date-that-will-not-hold-never-re-date-it`): two date questions already
exist and **both fire at or after the date** — `direction-overdue` once the date has gone,
`direction-expiring` once it is inside the survey window. Nothing asked *before*, on the
arithmetic. Measured 2026-09-01: three directions dated the same day, six days out, 30 queued
tickets between them, every existing reading healthy, and nobody told.

**The re-dating half of the ask is refused, by name, and the refusal is the point.** The ask was
that the loop "re-date or escalate what the arithmetic says cannot land". A strategy is the
operator's **resolved** direction; `amend.sh` carries only a revision the operator announced by
explicit slug, and a run never amends on its own reading (`workaholic:strategy`). A loop that
moves its own deadlines when it misses them is a loop whose dates mean nothing — a worse failure
than the one being fixed. So this step **writes nothing**: no `amend.sh` call, no `target_date`
touched, no stage moved, no mission closed, no work held. The question is the only act. If the
operator wants the loop to re-date, that is a deliberate ruling with its own measurement, and
this section is where a future reader should find the argument.

**It reads `strategy/scripts/landing-arithmetic.sh`** — the one derivation of *what remains
against how long is left* — and takes its `does_not_clear` rows. A `no_target_date` direction is
never a candidate (there is nothing to escalate) and an `unreadable` one is **counted, never
asked about**: spending a person's attention on our own degradation is the rule `strategy-pace`
already applies to its own `unknown`.

**It does not ask twice about the same thing, and the boundary is READ rather than re-derived.**
A candidate must read `live` in `direction-state.sh` — the one lifecycle reader, whose precedence
is `unreadable > arrived > overdue > expiring > dormant > live`. Every direction
`direction-health` asks about this tick is therefore excluded **by that step's own reading**
rather than by a second copy of the `expiring` boundary here: `overdue` and `expiring` keep their
cases, `arrived` and `dormant` keep theirs, and this step gets what is left — a live, in-date
direction whose board will not clear. A fresh threshold here would be a number nobody could
defend, and a second derivation of `expiring` is how two boundaries drift. A lifecycle read that
**refused** is `degraded` by name — never an empty live set quietly asking nobody: without the
filter the step has not found *nothing to escalate*, it has found nothing at all, and
`direction-health` reports its own refusal exactly this way. It takes the same optional
`--open-proposals` file that step does, so both read one lifecycle answer.

**`strategy-pace` is a different question and is not filtered against.** `pace: late` asks whether
anything has *landed* over a period as long as the one that remains; this asks whether what
*remains* fits in the days left. A direction can be `on_course` and still not clear — that is
precisely the measured case — so filtering one against the other would drop the finding.

**The age rides the candidate**, through `lib/read-age.sh` keyed on the key the row already
composes, exactly as `stalled-unit`, `undelivered-unit`, `undrivable-unit` and `retire-blocked`
carry it: the reader's words verbatim, an unreadable age named as unreadable, an absent one not
mentioned. Two kinds of number and never blended — the arithmetic answers *what remains against
how long is left*, the ledger answers *how long have we been asking*.

**The check-in's machinery applies unchanged**: the working-day and quiet-hour holds, the caps,
the asked-once ledger and the bounded re-ask. This step supplies subjects and their content keys.

| Key | Heading leads with | Body asks for |
| --- | ------------------ | ------------- |
| `date-will-not-hold:<slug>` | *`<title>` has more queued than it has been finishing, and will not clear by `<target_date>`* — then the slug, what remains at each grain, the days left, the observed rate | *re-date it by announcing the change with its slug, or cut what is queued.* |

**What is refused here**: leading with `does_not_clear`, `needed_days` or the slug; adding the two
remaining grains into one number (unchecked acceptance items and queued tickets are not the same
unit, and the body says what was counted); and any sentence implying the loop will move the date.

**What it puts on the root.** `event` names the repository event — *N directions will not finish
what they have queued before their dates* — and a tick with no candidate supplies the empty
string, so no line is rendered even when the change diff calls the step changed. The summary
keeps every count, including the candidates another date question already owns.

**What it costs, stated rather than discovered**: both readings walk attribution, measured here
at 110s and 36s. The first is a cost the tick already pays in `strategy-digest`, the second one
`direction-health` already pays. Re-composing either reading to make this step cheaper would put
a second composition of the same board in the tree, which is how two answers to one question
drift, so the duplicate read is deliberate. A tick out of clock reports this step `skipped` with
reason `budget`, by name.

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
| which channel, which window | the script | `WORKAHOLIC_INBOUND_SLACK_CHANNEL` (default `<repo_name>`; set to `dev-workaholic` here), `WORKAHOLIC_INBOUND_SLACK_WINDOW_HOURS` (default 26) |
| which refs an earlier tick asked about | the script | its own `unanswered-asks-filed` lines, read through `log-read.sh` |
| is this a question, a request, an opinion — and has anything answered it | the agent | the probe returned in `needs_agent` |

**The channel and the window are the inbound sweep's own, unchanged.** One channel and one window
mean the two readings cannot disagree about which messages the loop had a chance to see; a second
pair of variables is exactly how they would. The cost is stated rather than hidden: a message
already older than the window when this step first runs is never asked about, and nothing
backfills it. Every message arriving afterwards is asked about exactly once.

**A channel it could not read is its own outcome, and it reaches a person** (2026-08-29, mission
`point-the-inbound-readers-at-the-channel-that-exists`). The agent's read has **three** outcomes
and they are named apart:

| Outcome | What it means | What follows |
| ------- | ------------- | ------------ |
| `asks_found` | candidates nobody has answered | one question each, keyed `unanswered-ask:<channel>:<ts>` |
| `window_empty` | the channel **was read** and held nothing in the window | an honest quiet hour; no question |
| `channel_unreadable` | the read **did not happen** | one question, keyed `inbound-channel-unreadable:<channel>` |

**It never claims a channel is absent.** Slack answers *not found* for a channel the calling
token cannot **see**, so absent and invisible are one response — the distinction
`check-slack-channel.sh` was written to preserve, and reintroducing it at this seam would send a
person to create a channel that already exists. The question says *the channel could not be
read*, names the channel this run resolved and the reason the transport gave, and stops there.

**Quiet while the reading is unchanged, by the route rather than by a suppression list.** The
escalation goes through `ask-question.sh` on a key naming the **channel**, so the asked-once gate
answers it: one question per channel, ever, with the per-tick cap, the quiet hours and the
working-day hold applying unchanged. An hourly restatement of an unchanged reading is what this
repository retired two roots for, and this cannot produce one by construction. The cost is stated:
a channel that breaks, is fixed and breaks again is not re-asked — the same property
`base-red:<commit>` and `stalled-unit:<unit>` already carry; a **different** channel is a
different key, which is the change that actually matters. `no_slack_transport` asks nothing: it is
this session holding no connector, not a fact about the channel.

**The resolved channel name rides the summary**, so a divergence between the channel the loop
posts to and the one it reads is legible from the tick log without anyone re-deriving the default.
That divergence ran for a day precisely because it was not.

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
`no_slack_transport`, `channel_unreadable` — never rendered as a channel with nothing waiting,
and since 2026-08-29 `channel_unreadable` has the keyed question above rather than only a line in
the log.

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

**The two questions, under the composition contract** (2026-08-31, mission
`make-the-tick-s-questions-readable-and-close-them-in-the-thread`). Keys unchanged.

- **`unanswered-ask:<channel>:<ts>`** — heading: *nobody has answered `<who>`'s message in
  `#<channel>`*, then when it was written and its first words; the permalink carries the rest.
  Body: *answer it in the thread, or say it needs nothing.* The channel-and-timestamp pair is a
  coordinate, never a heading.
- **`inbound-channel-unreadable:<channel>`** — heading: *the loop could not read `#<channel>`,
  so nothing written there is reaching it*, then the reason the read gave. Body: *check the
  connector, the token or the channel name.* It says plainly that the read **did not happen**,
  never that the channel does not exist: sending somebody to create a channel that already
  exists is the failure this wording exists to avoid.

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

**And each candidate carries how long it has been ASKED ABOUT** (2026-08-30, mission
`say-how-long-the-loop-has-been-stuck`). `moderate/scripts/condition-age.sh --key <the key this
step already composes>` answers `first_seen` / `ticks` / `truncated` / `first_seen_is_floor`, or
a named `readable: false`, from the question ledger those keys already write. The reading rides
`needs_agent` **only** and its words are carried **verbatim** — a normalised word sends a reader
to a string no script printed. An unreadable age is named as unreadable and **never rendered as
*this just started***, which is the collapse the reading exists to close. **No key moves**, so
`already_asked` is byte-identical and the changed wording re-asks nothing, and **the summary does
not move either**, for the correctness reason recorded above.

The age is the age of the **question**, not of the condition, so the composed wording says how
long the artifact has been *asked about* rather than asserting how long it has been undrivable.
On this candidate the two nearly coincide, and saying the weaker true thing costs nothing.

**And since 2026-08-28 a candidate can be HELD** (mission
`put-the-loop-s-standing-rulings-on-one-pull-request`). While an open ruling pull request names
an address, asking a person to complete that same mapping line by hand on `main` is asking them
to do what they are being asked to merge, so that candidate is **held and counted** rather than
asked about. Keyed on the **subject**: a ruling naming one address does not silence the question
about another. A candidate that survives while a ruling is open carries `unjudged: true` and its
question says so — *the loop could not judge which account this belongs to* — because an unjudged
subject is exactly the one that most needs a person. The read is
`moderate/scripts/ruling-suppression.sh`, shared with `direction-health`; an **unreadable** read
holds nothing; and `ask-question.sh`, the key, the asked-once gate, the caps and the holds are
byte-identical.

**The question, under the composition contract** (2026-08-31, mission
`make-the-tick-s-questions-readable-and-close-them-in-the-thread`). Keyed
`undrivable-unit:<artifact path>`, unchanged — and the key is exactly the identifier the
contract forbids leading with, which is what made this step the clearest case for the rule.

- **Heading** — *`<the artifact's title>` is assigned to an address the identity mapping does
  not name, so no runner can pick it up*, then the address, the path, and *asked about since
  `<first_seen>`, `<n>` ticks* where the age is readable.
- **Body** — the one act: *add `<login>=<address>` to `.claude/git-identities`, or reassign the
  work.* The repair is one line and the question says which line.
- **An unjudged candidate says so** — *the loop could not judge which account this belongs to* —
  because that is the fact that makes it a person's, and it is the plain-fact form of
  `unjudged: true`.
- **Never alone**: `owner_unresolved`, `identity_unresolved`, `undrivable`.

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


**And each candidate carries how long it has been ASKED ABOUT** (2026-08-30, mission
`say-how-long-the-loop-has-been-stuck`). `moderate/scripts/condition-age.sh --key <the key this
step already composes>` answers `first_seen` / `ticks` / `truncated` / `first_seen_is_floor`, or
a named `readable: false`, from the question ledger those keys already write. The reading rides
`needs_agent` **only** and its words are carried **verbatim** — a normalised word sends a reader
to a string no script printed. An unreadable age is named as unreadable and **never rendered as
*this just started***, which is the collapse the reading exists to close. **No key moves**, so
`already_asked` is byte-identical and the changed wording re-asks nothing, and **the summary does
not move either**, for the correctness reason recorded above.

**Two ages ride this question and they are TWO FACTS.** `open_hours` is how long the pull request
has been open, from its own coordinates; `age` is how long the unit has been asked about. This is
the one step where both are present, and neither may silently replace the other — a pull request
opened an hour ago that nobody has been told about, and one open a week that a person was asked
about on day one, call for different acts. `drive/reference/claims.md`'s source table records
which question reads which, and the rule it exists for: **nothing derives an age twice**.

**It asks and nothing else.** It never merges, never retries, never drives and never resolves the
blocker itself. Each question is keyed `undelivered-unit:<unit>` through `ask-question.sh`, so
the asked-once gate, the per-tick cap, the quiet hours and the working-day hold all apply
unchanged and no second ledger exists. A degraded read (`no_claim_reader`, `claims_unreadable`,
`claims_unparseable`, `origin_unreachable`, `shallow_history`) is named and asks nothing — a scan
that could not reach the remote has not found *nothing undelivered*, it has found nothing at all.

**The question, under the composition contract** (2026-08-31, mission
`make-the-tick-s-questions-readable-and-close-them-in-the-thread`). Keyed
`undelivered-unit:<unit>`, unchanged.

- **Heading** — *the loop finished `<unit>` and could not merge it*, then the pull request, its
  age, and the two ages as **two facts with their sources** (the pull request's own
  `created_at`; asked about since `<first_seen>`, `<n>` ticks).
- **Body** — the one act: *merge it, or say what should happen to it.*
- **Never alone**: `report_undelivered` and the recorded `merge_outcome` word
  (`session_type_cannot_merge`, `merge_not_allowed`, `head_moved`, …). The refusal word is worth
  carrying because it says *where to look* — but beside *the merge was refused*, never instead
  of it, since none of those words means anything to a reader outside this repository.

## 19. `retire-claims` — a claim proved empty, taken off the table

```sh
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/step-retire-claims.sh --tick <id> [--root <repo-root>]
```

Every claim the oracle reads **`superseded`**: the unit's content already reached the base, so
the branch can never land and holds no work. The step hands each to
`drive/scripts/retire-claim.sh` — its **only** caller, deliberately, because one caller is what
keeps the retirement's bounds checkable — which closes the pull request, deletes the remote
branch and reaps the worktree.

**And every claim the oracle reads `stranded` — asked about, never acted on** (2026-09-01, issue
#788; the question given its content 2026-09-02). A `stranded` row is the photographic negative
of the one above: the unit's tickets *are* archived on the base, and its branch **still carries
files that exist on no other ref**. It is not a retirement candidate by construction —
`retire-claim.sh` refuses anything but the word `superseded` — and it is the same shape of
finding this step already owns, *a claim that looks finished and is not*, so it is asked here
rather than growing a step of its own.

**The question, under the composition contract.** Keyed `stranded-unit:<unit>`, so one branch
costs one question however many ticks see it, addressed to the **claim holder**. It leads with
what happened in words a reader outside the repository understands — this unit's tickets are
archived on the base while its branch still carries files that exist nowhere else — and names
the unit and the exact branch *after* that. **It names the files**, from the row's own
`stranded_files` (bounded, with `stranded_file_count` the true total, so a branch differing in
a thousand files says `and N more` rather than listing them): a person cannot rule on work they
cannot see, and *your branch holds work nothing else has* without the names is a verdict word
standing alone, which the catalog forbids. It says plainly that deleting the branch would lose
that work, asks what should happen to it — landed on the base, or discarded deliberately — and
**never suggests deleting the branch**. The two payloads ride separately for that reason: a
blocked retirement asks *please delete this branch* and a stranded claim asks the opposite, and
one instruction carrying both would carry two contradictory actions.

**The age rides it** through `lib/read-age.sh`, keyed on the key the step already composed, the
reader's words verbatim — an unreadable age named as unreadable, an absent one not mentioned.
**A branch stranded for weeks with nobody answering is a real possibility, and this is what
happens then**: the question is asked exactly once and the age is the only thing that says how
long it has been standing, so the arrears are visible on the one question rather than becoming a
silent backlog or an hourly re-ask.

**The tick acts on none of it.** It never deletes the branch, never merges it, never closes a
pull request, never releases the claim and never re-drives a ticket. `stranded` is a
**judgement** (`drive/reference/claims.md`, *Proofs and judgements*), and the right act — port
the work onto a live branch, open it as its own pull request, or discard it deliberately — is
genuinely unclear and is the holder's to choose.

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

One question per blocked unit, keyed **`retire-blocked:<unit>:<refusal word>`** so
`ask-question.sh`'s asked-once ledger holds it to exactly one ask **per (unit, refusal word)**,
naming the unit, the **exact branch** left on origin, the refusal that is blocking the delete
now, and the acts that already stand — a question that does not name the branch does not say what
to delete. Which half moved and which did not: a retirement that **worked** still asks nothing at
all.

**Asked once per (unit, refusal word), never per unit** (2026-08-29, mission
`read-back-whether-the-loop-s-own-act-took-effect`). Asked-once-per-unit is right for an
unchanging block — an hourly restatement of the same refusal is the noise two keyed roots were
retired for — and wrong the moment the **word** changes: a unit first blocked on
`branch_delete_failed` and later on `pull_request_open` is a different fact needing a different
act, and the second reached nobody. **An unchanged word is held forever**, which is the
discipline this preserves rather than drops.

**The gate itself did not change, and that is the property the shape was chosen for.** The
narrowing lives in what the **key is made of**, so `ask-question.sh` stays one mechanism that
cannot drift from itself, and every existing hold — quiet hours, working days, the per-tick cap
and the day cap — applies to a re-ask unchanged, because a re-ask is simply one more question.
Re-asking on a **timer** was refused by name: it reintroduces exactly the hourly restatement the
asked-once gate exists to prevent, and a word that has not changed carries no new information for
the person.

**The word is the one a person must act on**: CI's refusal where the effect reading
(`drive/scripts/ci-retirement-turn.sh`) names one, because that is the executor that was going to
take the delete, and the container's own refusal otherwise. One word, and it is the same word the
question names. A word that **oscillates** between two values would re-ask on each flip; whether
that needs its own bound is worth measuring before one is added, and none is added on speculation.

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

**And each blocked candidate carries how long it has been ASKED ABOUT** (2026-08-30, mission
`say-how-long-the-loop-has-been-stuck`). `moderate/scripts/condition-age.sh` is read with the key
this step composes — `retire-blocked:<unit>:<refusal word>` — **after** the key is settled and
after both suppressions, since an age read under any earlier key would answer about a different
question. The reading rides `needs_agent` only, its words are carried verbatim, and the summary
does not move, for the stability reason above.

**A changed refusal word resets the age, and that is correct.** The key carries the word, so a
unit whose block changes cause starts a new question and reads `first_seen: null` on its first
tick. The composer must not read that reset as the block having cleared: the branch has been
standing all along, and only what is blocking its delete has moved.

**The age is attached after the act, never before it.** This step is the one age consumer that
also *acts* — `retire-claim.sh`, on a proof — and the age is a **judgement**, so it must never
sit in front of the proof the act reads. The suite pins the ordering.

**It asks and nothing else**: no claim released, no pull request reopened, no delete re-run on the
strength of an answer, and the `superseded` proof gate and the retirement's other two acts are
exactly what they were.

**And the question narrows once more, to what CI could not take either** (2026-08-28, mission
`finish-a-proved-retirement-where-the-write-is-permitted`). Act 2 now runs in
`.github/workflows/claim-retirement.yml`, where the write is permitted, so a blocked unit whose
branch a workflow is about to delete must draw **no** question: asking a person, once per unit and
forever, for an act CI was about to perform is not merely noisy — the ask is wrong.

The reading is `drive/scripts/ci-retirement-turn.sh`. **It answered from a completed run's
EXISTENCE until 2026-08-29, and that premise was the design rather than the behaviour** (mission
`read-back-whether-the-loop-s-own-act-took-effect`). It read: *CI deletes the branch when it
succeeds, so a successful turn removes the claim row and the candidate with it; a completed run
at the base tip therefore means CI saw exactly this tree and the branch survived it.* The
inference holds only if every completed turn actually reached its act — and measured the same
day, `claim-retirement.yml` was green on every run while three proved candidates stood, because
the CI-side act refuses `gh_unavailable` before its proof gate. The sentence is corrected in
place in `drive/reference/claims.md`, *When an act of the retirement is refused*, with the
measurement that retired it.

**What replaced it**: the turn **records** what it attempted and what each act answered, and the
reading answers **per unit** from that record — `taken` only on the act's own success word. It
remains **store-free** (no cursor, no queue, no ledger, no field on any artifact); only which
part of the run is consulted moved. Matching is still on `head_sha`, which needs no clock, no
timezone and no date parsing. Five values, each with its own consequence:

| Reading | What it means | What the tick does |
| ------- | ------------- | ------------------ |
| `taken` | the act **succeeded** for this unit (`deleted`, or `already_gone`) | ask nobody — nothing is owed |
| `refused:<word>` | the act was refused, carrying its own word — or the turn's candidate reading was degraded and named its reason | ask — this is precisely what a person must hear about |
| `pending` | no completed run at this tip yet | ask nobody **this tick**; the asked-once ledger keys on the unit and its word, so a branch that outlives CI's turn is still asked about later |
| `unavailable` | the workflow is not present in this repository | ask — CI will never take the act here |
| `unreadable` | a run completed and we cannot say what it did | ask — a reading we could not make must never suppress a question |

A read the step could not make leaves the question exactly where it was, on the same rule: an
over-eager question is better than a silently dropped one, and this repository has measured the
cost of a blocked act nobody was told about.

**Everything else about the question is byte-identical** — the asked-once gate, the addressee,
the per-tick cap, the quiet hours and the working-day hold (the key gained the refusal word in
2026-08-29's narrowing above, and nothing else about it moved). Only the candidate set narrows,
and the **summary carries no CI term**, deliberately: every term of it stays a function of the
claim set and the act states, so a held block keeps rendering identically tick after tick and a
newly blocked unit still moves it. The narrowing is not a suppression list.

**The effect reading is deliberately kept out of the summary**, and the reason is measured rather
than stylistic: CI runs on every merge to `main`, so between a merge and its run completing the
reading genuinely oscillates `pending` → `refused:<word>` hour to hour. In the summary that would
move the diff most hours and render a root line for a block that had not changed — exactly what
the stability rule exists to prevent. The **key** is safe from the same oscillation by
construction, because a `pending` unit is suppressed before any key is composed.

**The suppression is per unit, not per turn** (2026-08-29). It was one run-level word applied to
every blocked unit at once; a unit is now held only on **its own** answer, and only on `taken`
(the act succeeded, so nothing is owed) or `pending` (CI may still take it, this tick only).
`refused:<word>`, `unavailable` and `unreadable` all hold nothing — and a unit the reading never
answered keeps its question **by construction**, because only named units are removed.

**A blocked retirement supplies an `event`, and which guard holds which case moved with it**
(2026-08-29, mission `read-back-whether-the-loop-s-own-act-took-effect`). An act the loop
believed it took and did not is a repository fact a person should see the hour it appears, so the
step's `event` now names those units — where before only a *successful* retirement supplied one.
There were two independent guards against an hourly restatement, an unchanged summary **and** an
empty event; a standing block now has one:

| Case | What holds the root line |
| ---- | ------------------------ |
| a tick whose acts all took | **no event** — the *a step with no event renders no line* guard |
| a **standing** blocked unit | **the summary diff** — identical string, so the step is not "changed" |
| a **newly** blocked unit | neither: the unit set moves, so the summary moves and the line renders |

That is the whole reason the summary must carry no CI term: on the standing-block path it is the
only guard left. Re-implementing the renderer's diff inside the step to suppress a repeated event
was refused — the renderer already owns that comparison, and a second copy is how the two would
disagree.

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

**The question, under the composition contract** (2026-08-31, mission
`make-the-tick-s-questions-readable-and-close-them-in-the-thread`). Keyed
`retire-blocked:<unit>:<refusal word>`, unchanged — the word stays **in the key**, which is
where it belongs, and never leads the heading.

- **Heading** — *`<unit>`'s work is all on `main` and its branch could not be deleted*, then the
  **exact branch** left on origin, the refusal, the acts that already stand, and *asked about
  since `<first_seen>`, `<n>` ticks*. A question that does not name the branch does not say what
  to delete, so that detail rides the heading and is not compressed away.
- **Body** — the one act: *delete `<branch>` on origin.*
- **Never alone**: `superseded`, `branch_delete_failed`, `gh_unavailable`. `superseded` in
  particular reads as a problem and means the opposite — the content already landed — so its
  plain fact leads and the word rides behind it.

## 20. `base-health` — did the base survive what the loop merged?

```sh
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/step-base-health.sh --tick <id> [--root <repo-root>]
```

The base's own checks, read once per tick through `drive/scripts/attribute-base-red.sh` — which
composes `drive/scripts/read-base-checks.sh`, the one derivation of a commit's check state. A red
base is handed to the check-in as **one `🔴 Blocked` report addressed to nobody** (2026-09-03,
mission `make-a-red-base-impossible-for-the-loop-to-miss`).

**It is a report rather than a question, and the `base-red:<commit>` question is retired.**
`ask-question.sh` holds a question under `quiet_hours` because a question addresses a named person
and nobody should be paged at 23:00 to choose between two dates. A red base asks the operator to
decide **nothing** — it reports that the ground everything is landing on is broken — so the reason
the window exists does not apply to it, and the loop used to build on a broken base all night while
its own announcement waited for morning. `🔴 Blocked` already exists for that class and carries its
own failure-signature cool-down, which this **composes and never re-derives**: no second clock gate,
no new constant. The signature carries **no SHA** (that rule is the cool-down's own — a key that
changes every commit suppresses nothing), so it is the failing check names: the same suite still
failing is one alert however many red commits carry it. The attribution walk is untouched — who
broke it is still `attribute-base-red.sh`'s answer and rides the report's own sentence.

**And every reading of the colour names the suites that never ran.** The step reads the tip once
through `read-base-checks.sh --declared` and carries `unverified` **beside** the colour in its
`summary`, on the green, red and `unanswerable` paths alike — a tip can carry a green verdict and an
unverified suite at once. A degraded declared-read is named as degraded (`unverified_readable:
false` with its reason) and never rendered as *every declared suite ran*. It is **evidence and
gates nothing**: it opens no question, earns no post of its own, and moves no token.

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

**The question, under the composition contract** (2026-08-31, mission
`make-the-tick-s-questions-readable-and-close-them-in-the-thread`). Keyed `base-red:<commit>`,
unchanged — a commit sha is the least readable identifier the tick holds, and it leads nothing.

- **Heading** — *`main` is failing its own checks*, then the failing check names, the merge the
  walk attributed (its pull request and title) and the commit.
- **Body** — the one act: *fix it or say it is expected.* Never *re-run it*: a re-run is an act,
  and this step takes none.
- **`unattributable` still asks, and says so in plain words** — *`main` is failing and the walk
  could not name the merge that broke it*, keyed on the tip, so nobody is sent after a merge the
  step did not identify.

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
3. **Post the catalog's shape** for the **pair** of (latest status, pull request state), and there
   are exactly three: `🟡 Handoff` + merged reuses `🟢 Implemented` with the sentence naming that it
   merged outside the loop, **by whom and when**; `🔵 Proposed` + closed-unmerged uses `⚫ Closed`;
   and `🔵 Proposed` + **merged posts nothing**, reported `proposal_merged_is_not_a_finish`.
   **Never invent an author or a time** — an unresolved one is *stated* as unresolved, never
   omitted silently and never guessed.

   **A merged proposal is the item's START, not its finish** (2026-09-01, issue #787). Merging a
   proposal lands a feedback record and a ticket set, which is the moment the work becomes
   **queued**; `🟢 Implemented` there asserts the opposite of what happened. Measured on a
   consuming repository: an operator read the green circle as their ask being done while the
   ticket was still in `todo/` and the thing they complained about was byte-identical. The two
   cases were already distinguishable with no new state — the latest status reply is read anyway,
   and it is what tells them apart. **Saying nothing is strictly better than saying the opposite**:
   the thread keeps its last true status, and the real `🟢 Implemented` still arrives when the work
   is driven. **No fifth finish emoji was introduced** — a shape of its own saying *the tickets are
   queued* is additive, can follow, and is the operator's to ask for; the catalog already reasons
   against growing the finish vocabulary.

   **The stated cost**: a queued item whose ticket is never driven now has a thread that simply
   stops at `🔵 Proposed`. That is a **true** last word rather than a false one, but it is still a
   silence, and it was chosen rather than overlooked. `[Consent]`'s retirement is untouched: this
   **narrows** what the step corrects and announces no human merge it did not already announce.
4. **Record one `thread-reconcile-filed` line per candidate** through `log-append.sh`, naming the
   key and the outcome, then persist again through `persist-log.sh --tick` — the **second** persist,
   without which the line dies with the container.
5. **One outcome per candidate, or the other**: `posted`, or a named not-posted reason —
   `no_thread`, `already_finished`, `proposal_merged_is_not_a_finish`, `unsure`,
   `no_slack_transport`, `thread_unreadable`, `post_failed`. The third is **counted rather than
   dropped silently**, so a merged proposal reaching no reply is visible as a decision rather than
   as a step that found nothing. **A candidate handed back with no outcome is non-conformant on its face**: this is
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
twenty-six pull requests a day, and a single page would have answered "nothing merged" for anything
older than yesterday.

**A candidate whose artifacts resolve to no feedback stem is reported in `unresolved` under
`stems_unresolvable`, and is never keyed on `unit:<id>` here.** This reader answers *which item*, and
an item with no feedback record has no thread to reconcile at all.

**Degradations, named one by one**: `gh_unavailable`, `list_failed`, and the per-candidate
`stems_unresolvable`. An unreadable read is `ok: false` with its reason and **exit 0**, carrying **no
candidate list at all** — never an empty one, which would render our own blindness as "nothing to
reconcile".

## 25. `file-findings` — a repairable finding, filed as work

```bash
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/step-file-findings.sh --tick <id> [--root <repo-root>]
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/list-finding-issues.sh
```

- **Reads**: the classification table below (its one home), the run's own step reports,
  named by `run.sh` in `WORKAHOLIC_TICK_REPORTS`, and `list-finding-issues.sh` (the ledger,
  one REST call). **Never `plan-units.sh`** —
  `undrivable-units`' rule, first recorded by `closable-missions`: the survey runs the living
  migrations and **stages** what they converge, and a step whose contract is *writes nothing*
  may not reach it through something that writes.
- **Writes**: nothing, not even its own tick-log line (`run.sh` writes that). The act is the
  agent's, through `propose/scripts/file-inbound-ask.sh` — still the **one** filer — assigned to
  the running identity so the next `[Specificate]` at `:15` ingests it, carrying the direction
  through `feedback/scripts/ask-feedback-line.sh`, still the one writer of that line.
- **Its `event` is always empty**, `standing-rulings`' rule for `standing-rulings`' reason: at
  the moment `run.sh` reads this step's line nothing has been filed, because the agent acts only
  after `run.sh` returns. An event here would announce an act the step has not taken.

**Why it exists** (2026-08-29, mission `let-the-tick-s-own-findings-become-the-loop-s-work`).
The tick had two destinations for a finding — a **question** to a person, or a **feedback
record** — and neither becomes work, because `[Specificate]`'s unattended entrance reads GitHub
**issues**. So the loop's own debt accumulated where nothing could drive it, while the only
in-tick caller of the filer acted on a *person's* answer and never on a finding of its own.

**What counts as a finding.** A step in the `repairable` set that supplied an **`event`** — its
own statement that a repository event happened — or that reported **`degraded`** or
**`blocked`**, because our own machinery failing is the loop's debt as surely as a stuck pull
request is. Everything else the tick found is **`left`**, a count and never a list: those
findings reach a person through their own questions, and re-listing them here is the report
addressed to nobody this repository has twice retired posts for.

**The issue is composed, never pasted.** A step's `summary` is written for a maintainer
diagnosing the tick and reads badly as an issue body; the agent writes it for the person and for
the `[Specificate]` run that will read it — what the tick found, which step found it, and the
repair the finding names.

**The brake: at most one open finding issue in flight.** An hourly step that filed whatever it
found would put the tick's whole debt into the inbox in a day. The bound is read off the
open-issue ledger with **no cursor and no stored state**, in the exact shape `open_proposal`
already uses: the two states hand off with no window, because a merged repair closes its own
issue and the finding leaves the candidate set with it. **A per-day cap is refused by name** —
the ask is for an *hourly* loop, and a daily bound on the only path from the tick's debt to the
work queue would cap that path at one turn a day. One in flight is deliberately strict; if it
measurably starves the queue that is a finding for a later ask, not a number to raise here.

**An unreadable ledger files nothing, and says so distinctly.** A brake that cannot be read is
not a brake. `brake_held` (one is in flight, named by number) and `brake_<reason>` (we could not
look) are **different facts about the loop**, and collapsing them is how a broken gate reads as
a working one.

**The dedup is structural and keyed on the step id.** The key comes from `lib/question-id.sh` —
the one derivation of a question's identity — so the filing and the asking cannot disagree about
what "the same finding" is, which is what lets the suppression hold exactly the question a
filing answers. It is keyed on the **step id** and nothing else: a finding's summary moves as
the world moves, and keying on it would re-file the same finding whenever its wording changed.
A candidate whose id is already on an issue is dropped and **counted**, never silently.

**The marker rides the issue, visibly.** `file-inbound-ask.sh` — still the one writer of a
marker — takes `--finding <step id>:<finding id>` beside its `--slack-ref` and writes one
`finding: <step id> / id: <finding id>` line into the body, with `source: moderate`. Exactly one
of the two markers is allowed: an issue claiming to be both a channel message and a tick finding
would be matched by two dedups. It is in the **body**, not the title, so it survives a person
retitling the issue.

**Filed, held and left never render alike.** Each is a different fact about the loop and asks
the reader for a different thing — work the loop took on, the brake doing its job, and what only
a person can settle — and collapsing them is exactly what made the tick's debt invisible
(`0 retired` hour after hour with nobody told). The step carries `needs_agent` (to file),
**`held`** (each candidate with the open issue that held it), **`already_filed`** (each dropped
candidate with the issue that already carries it) and **`left`** as a **count, never a list**:
those findings reach a person through their own questions, and re-listing them here is the
report addressed to nobody this repository has twice retired posts for.

**A tick that filed nothing names why, from a closed set of four**: `no_candidates`,
`brake_held`, `all_already_filed`, `brake_unreadable` — never one word for all four. The
ledger's own reason rides the summary rather than the reason word, so a reader keying on the
word never has to enumerate whatever a transport happened to say this hour.

**The summary is stable**: every term is a function of the candidate set and the ledger state
alone — no timestamp, no clock, no count that moves for a reason the reader cannot see. That is
what lets the tick's own diff suppress an unchanged hour; `inbound-sweep`'s embedded timestamp
is the measured failure here, which made its line "changed" on every tick by construction.

**A run that names a candidate and reports no outcome for it is non-conformant on its face** —
the connector retry's enforcement, for the same reason: no mechanical check tells a real filing
from a claimed one, and what this buys is that a report naming no outcome is visibly wrong.

**And the question a filing answers is held.** A finding that has become work must not also ask
a person — the same person, in the same hour, about the thing the loop is already driving.
`finding-suppression.sh` is the one reader: a **sibling** of `ruling-suppression.sh`, in the
same shape and under all four of its rules, but not an extension of it, because the sources
differ (a ruling is an open **pull request**, a finding an open **issue**) and folding them
would put two unrelated network reads behind one call. Every consulting step reads it and none
reads `list-finding-issues.sh` itself: two readings of one fact drift.

- **Keyed on the subject, never on the existence of a filing.** A filing naming one step's
  finding must not silence a different step's question — suppressing on `any_open` would
  silence the whole question queue behind one filing, the bug `ruling-suppression.sh` names in
  its own header.
- **An unreadable read holds nothing** (`ci-retirement-turn.sh`'s discipline).
- **A `needs_ruling` finding still asks, byte-identically** — no filing can ever name it,
  because it is never a candidate. `ask-question.sh` is **untouched**: the gate, the day cap,
  the per-tick cap, the quiet hours, the working-day hold and the one bounded re-ask do not move,
  and the gate never learns what a finding is.
- **It holds the question, never an act.** `retire-claims` still retires what it proved; only
  its `retire-blocked` question is withheld. The consulting steps are the ones that put a
  **question to a person** and are in the repairable set: `retire-claims`, `stuck-prs`,
  `undelivered-units`. `merge-conflicts`, `inbound-sweep`, `doc-drift` and `note-cadence` hand
  the agent an **act** rather than a question, so there is nothing there to suppress and wiring
  them would hold work instead — the opposite of the intent.
- **The suppression is derived and stored nowhere**: merging the repair (which auto-closes its
  issue) or closing it by hand makes the question reachable again. `held` is projected from the
  **open** issues only; the dedup uses the closed ones too, because *has this been filed*
  outlives *is it in flight*.
- **It bites from the next tick.** `file-findings` runs after the steps whose reports are its
  candidates, and the agent files after `run.sh` returns. Reordering the run to close that
  window would put the filing before its own inputs.

**No store, anywhere.** The issues are the memory, so a tick log that died with its container
changes nothing — `filed-records.sh`'s rule, that a `<step>-filed` line is never itself the proof
of a filing, holds here by construction because nothing reads such a line. The ledger's window is
the most recent `WORKAHOLIC_FINDING_ISSUE_LIMIT` issues (default 100, `state=all`, newest first)
rather than a date: `date -d` is GNU-only and `date -v` BSD-only, and a reader that answers
differently on a laptop and in a container is worse than one bounded by a number both can read.
`list_capped` reports when the page bound rather than the repository ended the read.

---

## Repairable, or needing a ruling — which findings may become work

A finding has three destinations, and until 2026-08-29 it had only two: a **question** to a
person, or a **feedback record**. Neither becomes work, because `[Specificate]`'s unattended
entrance reads GitHub **issues** — so the tick's own debt accumulated where nothing could drive
it. The third destination is an `[FB]` issue, filed by `file-findings` (§25), and this table is
the gate on it: **only a `repairable` finding may become work with no person asked.**

**Keyed on the step id, because that is the closed vocabulary the tick already has.** `run.sh`'s
`STEPS` is the whole domain; the table is read from there rather than restating it, and the pin
in `scripts/test-workflow-scripts.mjs` fails in **both** directions — a `STEPS` entry missing
from the table, and a table row `STEPS` does not name — so the two cannot drift. No artifact
gains a field, no second vocabulary is created, and no store is added. **There is no
`classify.sh`**: a function returning the answer would be the second derivation of one fact this
table exists to prevent, exactly as `drive/reference/claims.md`'s *Proofs and judgements* is
prose plus a pin and not a classifier.

**An unclassified step id is `needs_ruling`.** Mislabelling a ruling as mechanical is the
failure the classification exists to prevent, so the default is the safe side and a new step is
**silent** until somebody classifies it deliberately.

**The question is who must act, never how severe the finding is.** A severe mechanical repair is
still mechanical, and a trivial ruling is still a ruling. `repairable` means *a change to this
repository fixes it, and no human owes a decision first*; `needs_ruling` means *a person must
decide something before any change is the right one*.

| Step id | Classification | Why |
| ------- | -------------- | --- |
| `open-log` | `needs_ruling` | Bookkeeping; it produces no finding to file. |
| `inbound-sweep` | **`repairable`** | A diverged channel default or a broken transport config is a change to this repository. |
| `workload-logs` | `needs_ruling` | An unreachable environment is somebody's credentials, not our code. |
| `merge-conflicts` | **`repairable`** | A pull request conflicting with the base names a seam that keeps colliding; the filing yields a **plan**, never a push onto a claimed branch. |
| `stuck-prs` | **`repairable`** | What failed to auto-merge names a gate or a transport that a change can fix. |
| `issue-triage` | `needs_ruling` | Whether a stale issue is still wanted is the filer's call. |
| `doc-drift` | **`repairable`** | Documentation that no longer matches the code it describes is this repository's own debt. |
| `release-status` | `needs_ruling` | A target's confirmation method is a human declaration; deploying is a human instruction. |
| `note-cadence` | **`repairable`** | A draft note that stopped refreshing is a defect in the workflow that writes it. |
| `strategy-pace` | `needs_ruling` | Whether a direction is still the right one is the operator's. |
| `direction-health` | `needs_ruling` | Re-dating, closing or declaring a direction arrived is the operator's, by that step's own contract — and since 2026-08-29 so is **moving its declared stage**, which is precisely what a machine may not decide: `direction-cutover:<slug>` and `direction-settled:<slug>` are asked, never filed as repairable work. |
| `date-will-not-hold` | `needs_ruling` | Whether a direction's date still holds, and whether to re-date it or cut what is queued, is the operator's — the same ground `direction-health` stands on, and the step's own contract already refuses the re-dating half by name. |
| `stalled-units` | `needs_ruling` | Whether a stalled claim is taken over or abandoned is the holder's. |
| `raced-units` | `needs_ruling` | **Which of two live branches keeps driving the unit is the claim holders'**, and picking between them is the one act `ambiguous_claim` refuses everywhere in the protocol — filing it as work would be the loop deciding what it refuses to decide. Its readings are besides that **judgements** (`drive/reference/claims.md`, *Whether a unit is being driven twice*). The repair that would stop races happening at all is a **different** finding, already recorded on its own mission: it rests on an arbitration this container's transport refuses. |
| `undrivable-units` | `needs_ruling` | Which account an address belongs to is a human's ruling, by that step's own contract. |
| `standing-rulings` | `needs_ruling` | It exists **because** the loop cannot make those rulings itself. |
| `undelivered-units` | **`repairable`** | A merge the transport refused names the transport seam, which is code. |
| `stranded-publications` | `needs_ruling` | Every class `/implement` can attempt is attempted — `mechanical`, `clean` and, since 2026-09-02, `content` — through `settle-stranded-publication.sh`, so filing any of them would ask for work already in flight. What the merge itself cannot settle is the **act's** residue and is reported where the act is, not filed as a finding and not deferred to the publication's author (2026-09-02). What is left for a person is the step's *other* question — whether a publication open long enough for its plan to be stale is still wanted — and that is a judgement, so the row keeps `needs_ruling`. |
| `handoff-units` | `needs_ruling` | The declared verification is the one act nothing unattended can take. |
| `operator-pulls` | `needs_ruling` | The publication exists **because** merging it is the operator's ruling and closing it is their refusal; the seam refused to auto-merge it for exactly that reason. Filing it as work would be the loop asking itself to settle what it opened a diff to have settled. Every reading it carries is besides that a **judgement** (`drive/reference/claims.md`, *Whether an operator-facing pull request was acted on*). |
| `thread-reconcile` | `needs_ruling` | Its repair is the tick's own reply, already taken; it owes the queue nothing. |
| `retire-claims` | **`repairable`** | A branch CI could not delete names an executor or a bound that a change can fix. |
| `closable-missions` | `needs_ruling` | The tick closes what it proved; a rejected re-proof is a person's to read. |
| `unrecorded-missions` | `needs_ruling` | **Whether to close the mission or drive it again is the assignee's**, and the step exists because the loop cannot tell them apart: what it establishes is that nothing *recorded* the work, never that the work is undone. `closable-missions`' row, one state over — and filing it as work would have the loop closing a mission on a reading its own header refuses to treat as a proof. |
| `base-health` | `needs_ruling` | Its four readings are **judgements** a consumer may only report or ask about (`drive/reference/claims.md`), so turning one into work would be a consumer acting on a judgement. |
| `drill-health` | `needs_ruling` | `base-health`'s row, for `base-health`'s reason: it composes the same check-run reader, so every value it carries is a judgement a re-run can turn green. The finding reaches the person who shipped the mechanism as that step's own keyed question, which is the delivery the mission asked for. |
| `strategy-digest` | `needs_ruling` | A render; it produces no finding to file. |
| `question-answers` | `needs_ruling` | A person's own words, already filed by that step through the one filer. |
| `unanswered-asks` | `needs_ruling` | A person is waiting; that is the finding, and only a person clears it. A channel the tick could not read is the same kind of finding — a connector, a token or a name only a person can fix — and it reaches that person as the keyed `inbound-channel-unreadable:<channel>` question rather than as a filed issue. |
| `blocked-tick` | `needs_ruling` | The reading says a tick **stopped** and cannot say why — the record that would carry the reason is the one the stop prevented — so filing it as work would have the loop repairing a cause it never established (`cadence-lapse`'s row, for `cadence-lapse`'s reason). The repair is besides that routinely a person's: answering or removing a prompt, or reading the run in the session list. |
| `cadence-lapse` | `needs_ruling` | The reading says an artifact **stopped** and cannot say **why** — a routine switched off, a credential that expired, a producer that moved, or a declaration that is now wrong — and which of those it is decides whether any change is the right one. `note-cadence` is the row worth arguing against and it loses on exactly that: it names one workflow **this repository owns and can fix**, while a declared cadence names an artifact whose producer the declaration does not identify. Filing it as work would have the loop repairing a cause it never established. |
| `file-findings` | `needs_ruling` | Filing its own findings as work is the loop asking itself for work. |
| `human-checkin` | `needs_ruling` | The asking step itself. |

**`merge-conflicts` is the row worth arguing about**, and it is `repairable` deliberately.
`workaholic:drive` said resolving a conflict on a claimed branch is nobody's job here, and
**that rule was narrowed on 2026-08-29** (mission
`land-the-loop-s-own-work-when-the-base-moves-under-it`) rather than dropped: a run may now
merge the base into **its own** claim branch. Since 2026-09-02 it attempts a **`content`**
reading too — the class is a prediction, and the tick tests it rather than trusting it — and
what the merge itself cannot settle refuses `content_conflict` with the branch byte-identical
and is **reported by the act**, in `/implement`'s own run report. Nobody is asked about it:
`catchup-blocked` was retired in the same change, because a conflict handed to a claim holder
is handed to somebody who never comes.
What is untouched is exactly what this row rests on: the filing produces an issue, then a plan,
then a `review`-policy unit on a **fresh** claim — never an unattended push onto somebody
else's branch. Were the reading ever to be that the repair is not mechanical, the row moves to
`needs_ruling` and the default is already on that side.

---

## A refused action is reported, never silently skipped

`rules/interaction.md`, *An unattended run never waits for a person*, admits two outcomes and
refuses a third. Its second — *refuse the single action and carry on, recording what was refused
and why* — is only admissible if the record reaches somebody: without one a refusal is
indistinguishable from an action that silently did nothing, which is the shape this whole tick
exists to remove one level up.

**Three facts and no more**: the action refused, the reason, and that the rest of the run
continued. A refusal is not a stack trace, and a fourth fact is how a refusal line becomes
something nobody reads.

**It uses the surfaces and the vocabulary that already exist.** A step that refuses an action
reports **`blocked`** — already in `run.sh`'s closed status vocabulary and already accepted by
`log-append.sh` — with its own `reason` and a `summary` naming those three facts. That puts it in
the tick log line and the run report a person already reads, keeps it out of `ok`, and carries it
into the root's impairment clause beside a `degraded` read, which renders the two under one clause
because *they differ in cause and are identical in consequence to the reader*. **No new status, no
new store, no field on any artifact, and no new surface**: everything a refusal needs was already
there and unsaid.

**The agent's own refusals** — taken after `run.sh` returns, acting on `needs_agent` — are recorded
the same way, through `log-append.sh` under `<step>-refused`, which is the `<step>-filed`
convention applied to the other outcome.

**It moves no token and gates nothing.** A refused action is a fact about one step, not a verdict
on the run; no route, gate, hold, claim or sort reads it, and the person who must act is reached by
the tick's own questions.

**What it records, and what it cannot see.** This covers a refusal **this repository's own code
decides to make**. A permission prompt denied by the harness is not observable from inside a script
at all — a script has no notion of having been refused one — and the documented routine model says
such prompts should not arise in the first place (`workaholic:workaholify`, *Where an unattended
run's prompt policy is configured*, which also records that the measured behaviour diverges from
it). Where one does arise it surfaces, if at all, as an ordinary `step_error`. **The limit is
stated rather than glossed**: a reader must not take this contract as evidence that every refusal
in a tick is visible.

## What `run.sh` guarantees around the steps

- **The report carries each step's `needs_agent` array, with `needs_agent_count` beside it**
  (2026-08-26). It carried the count alone, against this file's own stated shape, on the reasoning
  that the report only needed the length — and two readers needed the payload.
  `question-liveness.sh` matches a question's key as a string **inside** `needs_agent`, so against a
  counted report it answered `settled` for every key by construction: the bounded re-ask could never
  fire, and the `✅ 解消を確認` confirmation would fire on every open question, every tick. The agent
  hit the same wall from the other side — acting on `needs_agent` after the run returns, it had to
  re-invoke every step to see what the tick had found, which is extra network and clock in a
  container nobody is watching, and a second reading of steps whose window moves between
  invocations. One defect, two symptoms: a report that named how much there was and not what it was.
- **Every step is invoked and every step reports.** Missing script → `degraded`/`step_missing`;
  non-zero exit → `degraded`/`step_error`; empty or unparseable output → `degraded`/`no_output` or
  `bad_output`; a status outside the log vocabulary → `degraded`/`bad_output`. A step never
  disappears from the report.
- **A step that could not compile its own reading is `degraded`, and that is derived in one
  place** (2026-08-29, mission `make-a-direction-s-lifecycle-a-declared-stage`). Every reader here
  carries `… | jq -c '…' 2>/dev/null || echo '[]'` — a fallback that is right for a **data**
  problem and catastrophic for our own, because a jq program that does not **compile** discards
  identically: the step emits an empty finding and reports `ok`. Measured on
  `step-direction-health.sh`, which reported `1 expiring … 1 to ask` with the expiring direction's
  own question silently gone, one missing parenthesis inside the embedded program. The two cases
  are told apart by **jq's own exit status** — 3 is a compile error (our defect, the step cannot
  run at all); 5 is a runtime or data error and keeps every existing fallback exactly as it was.
  `scripts/lib/jq-guard.sh`, sourced by every script here that embeds a jq program, **records**
  the fact and decides nothing; this loop **reads** the record and reclassifies →
  `degraded`/`jq_compile_error`, beside the four causes above. `needs_agent` is deliberately left
  alone rather than zeroed: a step's other readings may have compiled fine, and dropping a
  question a person is owed to punish a defect elsewhere in the same script trades one silence for
  another. The `2>/dev/null` is **not** removed — the stderr of a legitimately degraded read is
  noise on an hourly unattended run, and the fix is to classify, not to shout. The build-time half
  is the suite's `every embedded jq program compiles` row, which names the exact program and jq's
  own words before a tick ever runs; the scripts *outside* this skill are covered by that row
  alone, because they report no step status for anything to reclassify.
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

**The question, under the composition contract** (2026-08-31, mission
`make-the-tick-s-questions-readable-and-close-them-in-the-thread`). Keyed `handoff-unit:<unit>`,
unchanged.

- **Heading** — *`<unit>` is finished and waiting on a check this environment cannot run*, then
  the **declared reason verbatim** (which is the whole point of the step and is never
  paraphrased) and the open pull request.
- **Body** — the one act: *run that verification where the credentials are, then merge.*
- **Never alone**: `awaiting_verification`, `verification_handoff`. Both are this repository's
  field names; the reader's fact is that the work is done and one human check is outstanding.

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

**What it never does, as it stands after 2026-08-31** (mission
`make-the-tick-s-questions-readable-and-close-them-in-the-thread`). It never re-asks or confirms
anything (`answered` is already its own refusal at the gate, and `✅ 解消を確認` keys on `settled`,
not on `answered` — both paths untouched), never opens an issue except through
`file-inbound-ask.sh`, never adds an edit path for a correction (a person who answers twice
appends a later line and the newest wins), and never reads a channel. **It posts exactly one
reply, after the act** — `🧾 対応結果`, once ever per question, and only on a `settled:` reading —
and no reply at all for the *recording* event, which is where the no-reply rule was written and
where it still holds. That sentence used to read *never posts a reply for this event*, full stop;
the narrowing and its bounds live in `workaholic:notify`'s catalog beside the shape. The overlap with `unanswered-asks` is deliberate and must
not be collapsed: that step asks about a **channel message nobody answered**; this files an
**answer to the tick's own question**. One is a question, the other is work.

**Degradations, named one by one**: `no_log_reader`, `log_unreadable` (any refusal but an absent
log — `no_log_area` is a readable answer meaning nothing has been asked), `candidates_underivable`
from the step; `no_slack_transport` and `thread_unreadable` from the agent's read. An unread
thread is never reported as a thread nobody answered.

### The second candidate set: what became of the answers we already have

(2026-08-31, mission `make-the-tick-s-questions-readable-and-close-them-in-the-thread`.) The
reaction says *received*, which is not *acted on*, and nothing said the second thing at all: from
the thread, an answer that became a merged mission and one that was read and dropped looked
identical.

**The candidates.** A question reading `answered`, **with a recorded coordinate**, whose
`answer-outcome.sh` reading is `settled:`, and with **no `human-checkin-outcome-<slug>` line**
already in the log. All four terms are load-bearing and none is a cursor.

**One pass, two sets.** The answered slugs were already derived here, to *exclude* them from the
thread reads; naming them as their own set costs **no second walk of the log and no second
reader**, which is why this step owns both halves rather than a new step owning one. The
person's own words ride the same pass — the newest `human-checkin-answered-<slug>` summary — so
the reply carries **the answer as recorded** rather than a paraphrase.

**Only `settled:` posts.** `pending` (the filed issue is still open, or the agent has not written
a filing line yet) and `unreadable:<reason>` post nothing and are **counted** in the summary: an
unread outcome rendered as a settled one would tell somebody their answer was acted on when
nobody knows.

**The bound is the step's own.** The pool is capped by the same `WORKAHOLIC_ANSWER_READ_MAX` the
thread reads use — one constant for one step, because the two sets grow the same way and a
second bound would be a second thing to keep current — and the remainder is reported rather than
dropped. The reader spends **one bounded issue read per *filed* candidate and none for the
rest**; the step itself still makes no call of its own.

**The holds are `✅ 解消を確認`'s, applied the same way**: the off-day and quiet-hours holds
apply, stated in the bound rather than recomputed here, because a third copy of the clock gate
is how three copies start disagreeing. **Held is not dropped** — a held candidate simply
re-derives on the next eligible tick, since the dedup is the ledger line and not a cursor.

**A candidate with no recorded coordinate is named, never searched for**, exactly as on the read
half: the alternative (find the thread by searching the channel) is what the recorded coordinate
exists to keep out.

**The reply, the record, and what is never load-bearing.** One `🧾 対応結果` per candidate into
that question's own thread, on the coordinate already in hand — no lookup, no search, no mention
token, once ever. Each post is logged under `human-checkin-outcome-<slug>` through
`log-append.sh`, then `persist-log.sh --tick` runs again — **the second persist**, without which
the line dies with the container and the reply is posted a second time next tick. A failed post
is `outcome_post_failed: <reason>` and changes **nothing** about the recording, the filing, the
stamp, the question's state or the reading; every one of those happened in an earlier tick.

**Its `event` stays empty**, for the step's existing reason: the agent acts after `run.sh`
returns, so an event here would be a claim about a post not yet made.

**Report per candidate**: posted, held, or the named reason it was not. A candidate handed back
with no outcome is non-conformant on its face — the enforcement the read half already carries.

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

## 27. `drill-health` — a proof the loop already made that stopped holding

```sh
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/step-drill-health.sh --tick <id> [--root <repo-root>]
```

The base's own **drill run**, read once per tick through `drive/scripts/read-drill-verdicts.sh`
— which composes `drive/scripts/read-base-checks.sh`, still the one derivation of a commit's
check state, and the drill register in `docs/loop-drill-runbook.md` §9. Every failing drill is
handed to the check-in as **one question addressed to the mission that shipped it**.

**Why it exists** (2026-08-29, mission `run-the-loop-s-own-proofs-on-every-turn`). Thirty
`verify-*` drills, one per mechanism an earlier turn of the loop built, and until that mission
none of them ran anywhere: CI executed two of them indirectly and related to eight more by a
regex proving a drill *exists*, never that it *passes*. Once `Loop Drills` runs them on every
push, a broken proof is a red check — and a red check reaches whoever happens to look at the
merge. This tick is the one surface that reaches a **named person**.

**Which sibling it follows, on each axis:**

| Axis | Follows | Why |
| ---- | ------- | --- |
| whose question | its own | the **shipping mission's assignee** built the mechanism and knows what it was for. It is a judgement, and stated as one: a drill can outlive its author's involvement, so the question **names the mission** and whoever reads it can redirect |
| the running identity | `undrivable-units` | never consulted — a failing drill is a fact about the **repository** |
| what it may read | `base-health` | the verdict reader and nothing else; **`plan-units.sh` is refused** for the reason `closable-missions` records |

**The key is the drill, not the commit.** `drill-failing:<drill>` asks once per broken proof
however many ticks see it; keying on the commit would re-ask on every merge that followed the
break, which is the hourly restatement two roots were retired for.

**A green run produces no question, no event and no root line** — the standing rule, held by
the same mechanism `base-health` uses: a step with no `event` renders no line. A **degraded**
read asks nothing and is named (`drill_run_unreadable:<reason>`), and a repository shipping no
`Loop Drills` workflow reads `unavailable` and asks nothing at all. It reads the **last
completed** run: a pending one lands as `checks_pending`, a named degradation, because a
pending run is not a verdict.

**It asks and nothing else.** No leg is re-run ("flake" is not a root cause and a re-run is an
*act*), nothing is reverted, merged, held or gated, no claim is touched, and it writes nothing
anywhere but its own tick-log line. Every value it composes is a **judgement**
(`drive/reference/claims.md`, *Proofs and judgements*): a re-run can turn a red check green.

---

**The question, under the composition contract** (2026-08-31, mission
`make-the-tick-s-questions-readable-and-close-them-in-the-thread`). Keyed
`drill-failing:<drill>`, unchanged.

- **Heading** — *the drill that proves `<what it proves>` is failing on `main`*, then the drill
  name and the mission that shipped it, so whoever reads it can redirect.
- **Body** — the one act: *fix the mechanism or the drill, whichever stopped being true.* Never
  *re-run it*: this step takes no act, and a red drill is a proof that stopped holding rather
  than a flake.
- **Never alone**: the drill's own verb (`verify-catch-up`, `verify-retire`, …). It is how the
  reader finds the check run — the check run is named after it — and it is not what the drill
  is about, so the plain fact leads.

## 28. `operator-pulls` — a pull request the loop opened for a person, still unanswered

**What it does.** Names every open pull request that is **the operator's** — the ones
`publish-tree-pr.sh` refused to auto-merge — reads whether each has been acted on, and hands
every un-acted one to the check-in as a question addressed to the operator, keyed
`operator-pull:<number>` so one pull request costs exactly one question however many ticks see
it. It **asks and nothing else**.

**Why it exists** (2026-08-29, mission `follow-the-pull-requests-the-loop-opens-for-a-person`).
The seam refuses to merge a ruling or a strategy publication precisely because *merging is the
ruling and closing is the refusal*. Having opened the diff, the loop then stopped following it.
Measured: #694 sat 18 hours unanswered.

**No other step could see it.** `stuck-prs` and `merge-conflicts` read the open pull requests
and find this one perfectly healthy — it is not stuck, it is **waiting**, which is what it was
opened to do. Every claim-side verdict (`undelivered-units`, `handoff-units`, `stalled-units`) is bounded to
a **claim**, and a publication carries none: `publish-tree-pr.sh`
pushes `publish-main` to a `work-*` name with no `Claim` commit in it, which is exactly what
keeps a publication invisible to the claim protocol.

**Membership is the seam's refusal word, never a title.** `list-operator-facing-pulls.sh`
derives it through the same `branching/scripts/lib/publication-refusal.sh` the seam itself
reads, from the **shape of the change**: a path under `.workaholic/strategies/`
(`strategy_touching`), a touch of `.claude/git-identities`, or a mission that already existed on
the base whose `feedback:` line the diff moves (`ruling_touching`). A pull request the operator
retitled or opened by hand is still theirs; an ordinary `[Proposal]` that auto-merged never
appears, whatever its title says.

**`list-open-rulings.sh` is untouched and is a different question.** That one is a **brake** —
*at most one open ruling at a time* — and its header records why the **title** decides its
membership: for a brake, over-inclusion is the safe direction. Two consumers, two questions, one
derivation each.

**Which sibling it follows, on each axis:**

| Axis | Follows | Why |
| ---- | ------- | --- |
| whose question | `direction-health` | the **operator**, resolved from the active directions' assignees — the one place this repository records a person as owning a direction (`validate-strategy.sh` floors `assignees` non-empty for exactly that reason). An unresolved address leaves the question addressed to **nobody** rather than stamping one nobody verified (`base-health`'s rule) |
| the running identity | `undrivable-units` | never consulted — an unanswered publication is a fact about the **repository**, so an hourly question that depended on which container asked it would answer differently per account |
| what it may read | `undrivable-units` | the two readers and `ruling-suppression.sh`; **`plan-units.sh` is refused** — that survey reaches the mission readers, which carry the living migrations and **stage** what they converge, and a step whose contract is *writes nothing* may not reach it through something that writes |

**What merging it would unblock comes from the hold's own reader.** `ruling-suppression.sh` is
the one script that knows which subjects an open ruling holds, and this step **composes** it
rather than re-deriving the subject list — the rule that reader's header already states for its
own two consumers. **This question is what breaks the silence**: the hold stays exactly as it
is, and the person who can end it is now told, once, that a pull request waits on them and what
it holds. Releasing the hold *as well* would ask one person twice, in two vocabularies, about
one pull request — the doubling `handoff-units` and `stalled-units` were split to avoid.

**`merged` and `closed` are settled and draw nothing.** An **`unreadable`** reading draws **no
question** and is counted in the summary — `strategy-pace`'s rule that a person's attention is
not spent on our own degradation. A tick with no candidate supplies **no `event`** and renders
no root line.

**The summary carries no age and no timestamp**, for the correctness reason
`undelivered-units`' header records: `open 18h` increments every tick, so it would make this
step changed **hourly** by construction and the root would restate the same pull request all
day. The age still reaches the person, in the question that names it.

**It asks and nothing else.** No merge, no close, no comment, no gate, no hold of work, no
lifted gate, and nothing written anywhere but its own tick-log line (`run.sh` writes that).
Every reading it carries is a **judgement** (`drive/reference/claims.md`, *Whether an
operator-facing pull request was acted on*).

**The question, under the composition contract** (2026-08-31, mission
`make-the-tick-s-questions-readable-and-close-them-in-the-thread`). Keyed
`operator-pull:<number>`, unchanged, and this is the one question whose age comes from the pull
request's own `created_at` and the tick log not at all.

- **Heading** — *a change only you can approve has been waiting `<n>` hours*, then the pull
  request's number and title, the refusal that made it yours, and what merging it would unblock.
- **Body** — the one act, and it genuinely has two options, so both are named: *merge it to
  make the ruling, or close it to refuse.*
- **Never alone**: `ruling_touching`, `strategy_touching`. Those are the publish seam's words
  and they say *why this one is yours*, which is worth carrying beside the fact — but a reader
  who has not read `publish-tree-pr.sh` learns nothing from either on its own.

### 28b. `headless-pull:<number>` — an open pull request with no branch left

**A second question on the same step, under its own key** (2026-09-01, ticket
`20260901112558-name-an-open-pull-request-with-no-head-branch.md`). `list-headless-pulls.sh`
names every open pull request whose `head.ref` names no branch on the remote. GitHub does not
close a pull request when its head branch is deleted, and such a pull request is **unmergeable
by construction** — a fact about the repository, not a judgement.

**Why here.** This is the step that reads pull requests waiting on a person. **Why its own
key**: the act asked for is different. `operator-pull:<number>` asks for a **ruling** on a diff
— merging it is the ruling and closing it is the refusal; this asks for a **close**, because
merging is not available to anybody. The existing candidates, key and addressee did not move.

**Why not a widened `list-operator-facing-pulls.sh`.** That reader answers *which open pull
requests wait on the operator's ruling*, derived from the publish seam's refusal word. A
headless pull request waits on nothing and has no refusal word. Two questions, one derivation
each — the rule that reader's own header already states for itself.

**The ref set is one repository-scoped REST listing** (`repos/{slug}/branches`), never the local
remote-tracking refs. The cheaper local read is wrong in the direction that costs: a clone that
never fetched a branch renders a **live** pull request headless and sends a person to close work
that is still going. A head on another repository (a fork) is **counted** (`foreign_head`) and
never reported headless — *we could not look* must never render as *the branch is gone*.

**It is reported exactly once.** `list-stranded-publications.sh` drops such a pull request by
its own term 2b and counts it (`headless`), so `settle-stranded-publication.sh` is never handed
an act that cannot succeed; a catch-up candidate is structurally impossible, since
`list-catchable-claims.sh` needs a **claim**, which needs an unmerged remote branch.

**A degraded read is named in the summary and asks nobody**, and is never rendered as *nothing
headless*.

**The question, under the composition contract.**

- **Heading** — *a pull request here can never be merged: its branch is gone*, then the number,
  the title and how long it has been open.
- **Body** — the one act: *close it.* The loop closes nothing itself — closing another person's
  pull request is not a bounded act the way a branch delete is, and the five measured cases were
  closed by a person who first verified the content was on `main` file by file.
- **Never alone**: the number. Lead with what happened; the identifier comes after it.

## 29. `raced-units` — a unit two runs are driving at once

```
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/step-raced-units.sh --tick <id> [--root <repo-root>]
```

**Why it exists** (2026-08-30, mission `stop-two-runs-from-claiming-and-driving-one-unit`).
`ambiguous_claim` — two or more **live** claims for one unit — is refused by every writer that
meets it and was **asked about by nobody**. Measured 2026-08-30: `work-20260830-055314` and
`work-20260830-055318` were both claimed for one unit four seconds apart and each drove the same
four tickets for over an hour; the run that lost reported an ordinary undelivered unit, and the
duplicated hour reached no person at all. `/implement` may not ask, so without this step there
was no path from *the loop is doing one job twice* to *a person is told*.

**No other step could see the shape.** `stalled-units` finds one claim that has not moved,
`undelivered-units` finds one refused merge — each a *consequence* whose question hides the
cause, because each of the two rows is
individually healthy and what is wrong is that both exist.

**Which sibling it follows, on each axis**

| Axis | Follows | Why |
| ---- | ------- | --- |
| whose question | `stalled-units` | the **claim holders** drove the unit and are the people who can decide which branch keeps going; both claims' `author` values are the addressees |
| running identity | `undrivable-units` | never consulted — a race is a fact about the unit, and an hourly question that answered differently per account would be asked once per runner rather than once per unit |
| what it may read | `undrivable-units` | `list-claims.sh` is a pure read, composed through `drive/scripts/list-raced-units.sh`; **`plan-units.sh` is refused**, because the survey reaches the mission readers, which carry the living migrations and **stage** what they converge |

**This step owns the raced unit's question; three siblings filter and count.** That is the
`handoff-units`/`stalled-units` division — one step asks, the others filter, and either half
alone is a defect — and all four candidates are settled explicitly rather than left to whichever
runs first. `stalled-units` and `undelivered-units` filter and count;
**`retire-claims` needs no change and gets none**, because its candidates are `superseded` rows
and a unit resolving `ambiguous` has none by definition (every one of its claims is live), so
the two sets are disjoint by construction. The full table, with each reason, is
`drive/reference/claims.md`, *Whether a unit is being driven twice*.

**The filter is one helper, not three copies.** `lib/raced-units.sh` reads the library's own
`claims_unit_resolution` over the scan each step has **already** made — no second walk of the
refs, and no second definition of a race, which is how a filtering step would start disagreeing
with the step that asks and drop a finding entirely. A step whose claims payload is unreadable
filters **nothing**, the safe direction: an over-eager question beats a silently dropped one.

**The aftermath is deliberately not a candidate.** One live claim beside a `superseded` one is
byte-identical to the *sanctioned* recovery in which a superseded claim's work is resurveyed and
taken on a fresh claim (`plan-units.sh`'s `resurveyed[]`); telling them apart would need a clock
threshold between the two claims' creation times or a field stored on an artifact, and this
repository refuses both by name. The aftermath is already handled — the loser reads
`superseded`, `retire-claims` retires it, `stalled-units` counts it.

**The question names both branches and picks between neither**, which is `ambiguous_claim`'s
standing everywhere in the protocol: choosing one of two live claims silently is how a runner
would discard work another run is still driving. Keyed `raced-unit:<unit>`, so one unit costs
exactly one question however many ticks see it; `ask-question.sh` gains nothing — no key, cap or
hold moves.

**The summary carries no age and no timestamp**, for the correctness reason
`step-stalled-units.sh`'s header records: the root calls a step changed when its summary differs
from the same step's an hour ago, and an age increments every tick, which would make this step
changed hourly by construction. A degraded read is named by its reason and asks nothing — a scan
that could not be read has not found *no unit is being driven twice*, it has found nothing.

**It asks and nothing else.** No claim released, no branch deleted or picked, no pull request
merged or closed, no worktree touched, no gate lifted, and nothing written anywhere but its own
tick-log line (`run.sh` writes that). Every reading it carries is a **judgement**
(`drive/reference/claims.md`, *Whether a unit is being driven twice*): a race resolves the
moment one of the two branches merges.

**The question, under the composition contract** (2026-08-31, mission
`make-the-tick-s-questions-readable-and-close-them-in-the-thread`). Keyed `raced-unit:<unit>`,
unchanged.

- **Heading** — *two runs are implementing `<unit>` at the same time*, then **both** branches by
  name and their claim times. Both branches ride the heading because the question is
  unanswerable without them.
- **Body** — the one act: *decide which branch keeps going.* It never proposes one — that is
  `ambiguous_claim`'s standing everywhere in the protocol.
- **Never alone**: `ambiguous_claim`. It is the only word in this vocabulary that names two
  things at once, which is exactly why the sentence has to spell it out.

---

## 30. `cadence-lapse` — a periodic artifact that stopped being produced

```
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/step-cadence-lapse.sh --tick <id> [--root <repo-root>]
```

**Why it exists** (2026-08-31, mission `notice-a-periodic-artifact-that-stopped-being-produced`).
Every other step of this tick is driven by an object that **exists** — an open pull request, a
commit, a claim, a ticket, a record — so a producer that dies produces nothing and no step has
anything to find. Measured: a daily record stopped for four days while hourly ticks ran
throughout, and not one of them reported it. The tick watches presence; this is the step that
watches **absence**. `/implement` may not ask and a run report is read by nobody on the day it
matters, so without it there is no path from *something stopped being produced* to *a person is
told*.

**What it reads.** `cadence-state.sh`, the one reader, and nothing else. That script owns the
declaration's parse, the age and the three states; this step reads its answer and decides only
who hears about it. A second parse of the declaration here is how the offer and the reading
would start disagreeing. **Where the declaration lives and what it says** is stated once in
`workaholic:moderate`, *Where a cadence is declared, and what it says*, with the two rejected
homes and their costs — it is not restated here or in the reader.

**What it asks.** One question per `lapsed` cadence, keyed `cadence-lapsed:<name>` through the
existing gate, so one lapse costs one question however many ticks see it; `ask-question.sh` is
byte-identical and no key, cap or hold moved. The question names the cadence, its pattern, its
period, when its newest artifact was last produced and how long ago — and says plainly that the
loop can see the artifact stopped and **cannot see why**.

**Which sibling it follows, on each axis**

| Axis | Follows | Why |
| ---- | ------- | --- |
| whose question | *nobody* | the declaration names a cadence, a pattern and a period and **no person**, so there is no addressee to name and the step will not stamp one nothing verified (`base-health`'s rule for an unmapped login). The question is still visible on the root, which is where a person scanning the channel meets it |
| running identity | `undrivable-units` | never consulted — a lapsed cadence is lapsed for every account, and a repository-scoped question that answered differently per container would be asked once per runner rather than once per repository |
| what it may read | `undrivable-units` | one pure reader; **`plan-units.sh` is refused**, because that survey reaches the mission readers, which carry the living migrations and **stage** what they converge |

**An unreadable cadence is named and asked about by nobody.** A pattern that resolves to
nothing, a malformed entry and a bad period are **our** degradation rather than a lapse, and
spending a person's attention on a reading we could not make is what `strategy-pace` already
refuses. The step reports `degraded` with reason `cadence_unreadable`, so the root's impairment
clause names it (`name-the-steps-a-tick-could-not-read`) — and it **still hands over any cadence
that did read `lapsed`**, because losing a question because a *different* cadence was unreadable
trades one silence for another, the trade `run.sh` refuses when it declines to zero
`needs_agent` on a jq compile error.

**A repository declaring nothing is `skipped`, not `degraded`.** It is a step declining to run
for a stated, healthy reason — the `no_log_source` split §3 draws — and `skipped` is
deliberately not impairment, so such a repository is byte-identical to one before this step
existed: no candidate, no event, no root line.

**It carries no question-ledger age, deliberately.** The four steps that compose
`condition-age.sh` do so because their own readings are instantaneous and they borrow the age of
the *question* as a lower bound. This reading answers the condition's **own** age directly, off
the newest commit that produced the artifact, which is the stronger fact; attaching the ledger
age beside it would put two numbers for one question in front of a person and add a fifth
consumer to a table pinned at four (`drive/reference/claims.md`, *Which question reads which
age*).

**The summary carries no age and no timestamp**, for the correctness reason
`step-stalled-units.sh`'s header records: the root calls a step changed when its summary differs
from the same step's an hour ago, and an age increments every tick, which would mark this step
changed hourly by construction — the retired `📦 Release Preparation` shape. The summary is
counts only, so a standing lapse renders no new line while a **new** one moves it the hour it
appears.

**Abort reasons**: `reader_missing` (the reader is not present beside this skill),
`cadence_unreadable` (the reader answered nothing parseable, or at least one cadence read
`unreadable`), and the reader's own `reason` when the declaration set could not be read at all.

**It asks and nothing else.** It re-runs no routine, writes no artifact to satisfy a cadence,
repairs or rewrites no declaration, touches no claim, lifts no gate, and writes nothing anywhere
but its own tick-log line, which `run.sh` writes. Drilled offline by `verify-cadence-lapse`.

## 31. `blocked-tick` — a tick that opened and never closed

```
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/step-blocked-tick.sh --tick <id> [--root <repo-root>]
```

**Why it exists** (2026-08-31, mission `stop-an-unattended-tick-from-waiting-on-a-person`). An
opening on the base with no closing is the signature of a tick that **stopped**, and nothing read
for it. Measured: three consecutive ticks sat at `requires_action` waiting on a permission prompt
raised by two reads of a plugin script — a routine has nobody to answer one — and the base carried
no trace of any of them, because `persist-log.sh` was the tick's *closing* act and the record that
would show the stop is the record the stop prevents. `run.sh`'s **opening persist** puts the
opening there; this step reads for it. Without both halves neither is worth anything.

**What it reads.** `log-read.sh`, the log's one parser, bounded to the newest **two** day files
(enough to hold the previous two ticks across a UTC midnight rollover; the log grows forever, so an
unbounded walk gets more expensive every day). It groups the entries by the tick id that reader
already returns — no second parser, no cursor, no store, no field on any artifact.

**What "closed" means, and why it is not the persist.** The tempting signal is the closing
persist's own `persist-log` line, and it is **wrong**: `run.sh` writes that line *after* the push,
so it never reaches the base on the tick that wrote it — it arrives only if the agent persists
again, which a tick with an empty `needs_agent` has no reason to do, and a healthy tick would
therefore read as stopped. The signal is a **`human-checkin` line**: it is the last member of
`STEPS` and is deliberately exempt from `--deadline-seconds`, so a tick that reached the end of its
run always logged it. The coupling is **stated** in the step's header rather than derived, because
a step that read `run.sh`'s `STEPS` to find the last one would be inspecting a plugin script to
find something out (`rules/shell.md`), and a second definition of *the tick's closing step* is
exactly what would drift.

**Which tick, and why not the previous one.** A tick still **running** when the next one starts
also has an opening and no closing, and the two are distinguishable only by time. Rather than tune
a threshold, the bound is structural: it reads **the tick before last** — the second-newest tick
other than this one — which has had a full extra hour to finish. A merely slow run is not
reported; one that has outlived a whole further tick is. **The cost is stated rather than hidden**:
a stopped tick is named one hour later than the earliest possible moment, and the measured failure
lasted hours.

**IT READS TWO SUBJECTS, NOT ONE** (2026-09-02, ticket `20260902043117`). The second is the
**propose tick**, which writes `propose-open` at the start of its run and `propose-close` as its
last act (`plugins/workaholic/commands/propose.md`, where that widening of `/propose`'s pure-reader
contract is stated). `[Propose]` originates the loop's work and was the one measured parked hourly
on a permission prompt — spending its fire, producing nothing, and reading as scheduled and healthy
because it wrote no trace anywhere at all.

It is read **here rather than in a step of its own**: the question is identical — *this opened and
never closed* — and the log is already in hand from the one read this step makes. A sibling step
would be a second reader of one file answering one question, which is how two readings of one fact
start to disagree. The bound is the same **structural** one, the tick **before last**, so a propose
tick still running when the next starts is never called stopped, and the closing signal is
`propose-close` for the same reason the moderate arm's is `human-checkin`: it is the last line the
run writes, and it is written **before** the push rather than after it.

**A log with no `propose-open` line anywhere is silent, never a stop.** That is the ordinary state
of every checkout that has not yet run the widened `/propose`, and reporting it as a stop would fire
on every one of them. Drilled: `blocked_tick_no_propose_line_is_silent`.

**What it asks.** One question per stopped tick, keyed `blocked-tick:<tick-id>` — or
`blocked-tick:propose:<tick-id>` for the propose arm, a key of its own so the two are asked and
settled separately — through the
existing gate, so a stopped hour costs exactly one question however many later ticks see it;
`ask-question.sh` is untouched. **Addressed to nobody** — a stopped tick is a fact about the
repository, and the running identity is never consulted (`undrivable-units`' axis). The question
names the tick, how many steps it recorded and the last one it reached, and **says plainly that the
reason is not recoverable from the base**, so nobody is sent after a cause the step did not
establish; it points at `rules/interaction.md`, *An unattended run never waits for a person*, as
the likeliest shape on record and at the session list as where the run itself is readable.

**Abort reasons**: `no_log_reader` (the parser is not present beside this skill), `no_log_area` /
`no_log_area` on an empty log area (a repository that keeps no tick log is `skipped`, not
`degraded` — a step declining to run for a stated, healthy reason did not fail to see),
`log_unreadable`, and the reader's own `reason` when the log exists and could not be read. An
`event` is supplied **only** when a stopped tick is found, so a healthy hour renders no root line.

**It asks and nothing else.** It re-runs no tick, writes nothing anywhere but its own tick-log line
(which `run.sh` writes), touches no claim, lifts no gate and never reaches `plan-units.sh`.
Drilled offline by `verify-blocked-tick`.

## 32. `stranded-publications` — a publication the loop opened and only a person can settle

```
sh ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/step-stranded-publications.sh --tick <id> [--root <repo-root>]
```

**Why it exists** (2026-08-31, mission
`repair-a-mechanically-resolvable-conflict-instead-of-reporting-it`). A publish-tree publication
is not a claim — `publish-tree-pr.sh` pushes onto a `work-…` name and carries no `Claim …` commit
— so the oracle gives it no row, no claim-side step can see it, and a proposal whose
auto-merge was refused reached **no question at all**. Measured on a consuming repository: three
open proposals colliding on `.workaholic/feedbacks/index.md` and nothing else, the repair
mechanical and total, the tick reporting the blockage hourly to nobody in particular for a day.

**What it reads.** `branching/scripts/list-stranded-publications.sh` — a pure read that composes
`list-claims.sh` (a branch the oracle owns is a claim, not a publication) and
`claim-mergeability.sh` (the one derivation of the class, carried through verbatim).
`plan-units.sh` is **refused**, on `undrivable-units`' axis: the survey reaches the mission
readers, which carry the living migrations and stage what they converge.

**Only `content` draws a question.** `mechanical` **and `clean`** are the loop's own work —
`/implement` settles both through `settle-stranded-publication.sh` (a `mechanical` one after a
catch-up, a `clean` one with no catch-up at all), and asking about either would ask a person for
the act the machinery is about to take. `unanswerable` is the **absence** of a reading, never
actable; it is **counted** in the summary so it stays visible rather than vanishing.

**The candidate set did not move when `clean` became settleable** (2026-09-01, mission
`deliver-a-stranded-publication-that-needs-nothing-but-a-merge`). `content` is still the whole of
it, for its own unchanged reason: only a person can judge a collision. What moved is the
**`settleable` count** in the summary, which is a reader-facing number rather than a candidate
set — left at `mechanical` it would have understated by four on the morning the class was widened,
and a count that understates what the loop owns is how a reader stops trusting it. **No question,
key, cap, addressee or gate moved with it.**

**One publication never draws two questions, and no filter was added.** The ticket asked for the
`retire-claims` / `stalled-units` division; it does not apply, and the reason is recorded rather
than a counter that could only ever be zero. The claim-side steps' candidates are `list-claims.sh`
rows, which a publication can never be, and this step's own reader drops any branch the oracle
names — so the sets are disjoint **from both sides**. `merge-conflicts` (step 4) may still report
the same pull request and that is deliberate, on its own recorded reasoning: it **asks nobody
anything**, so the only question a person receives about such a publication is this one.
`scripts/test-workflow-scripts.mjs` pins the disjointness rather than leaving it to a reading of
two headers.

**Degradation is named, never rendered as quiet.** The reader answers `ok: false` with its own
reason and a **null** count; this step repeats that word as its own `degraded` reason rather than
inventing one, because *nothing is stranded* and *we could not look* are opposite facts.

**The summary carries no age and no timestamp**, for the correctness reason `stalled-units`'
header records: an incrementing summary makes the step "changed" hourly by construction.

**It asks and nothing else**: no merge, no catch-up, no push, no close, no claim touched, no gate
lifted, and nothing written anywhere but its own tick-log line. Drilled offline by
`verify-stranded-publication`.

**The question, under the composition contract.** Keyed `stranded-publication:<number>`, so one
pull request costs one question however many ticks see it.

- **Heading** — *an artifact the loop published is waiting because its change and the base
  changed the same lines*, then the pull request, then the colliding files by name.
- **Body** — the one act: *resolve it on the pull request.*
- **Addressed to** the publication's author. An operator-facing publication
  (`strategy_touching`, `ruling_touching`) is `operator-pulls`' subject and is excluded by the
  reader, so it is never asked about twice.
- **Never alone**: `content_conflict`, `mechanical`, `unanswerable`, a branch name, a number.
- **The age** rides `lib/read-age.sh`, keyed on the key the step already composes, the reader's
  words verbatim; an unreadable age is named as unreadable and an absent one is not mentioned.

**A second question: a publication old enough that its plan may be stale** (2026-09-01, ticket
`20260901062000-check-a-stranded-proposal-is-still-worth-landing.md`). Keyed
`stranded-publication-stale:<number>`.

`publish-tree-pr.sh` auto-merges on opening, so a proposal is normally written and landed minutes
apart and its age says nothing; only one the **transport** refused stays open long enough for the
plan it carries to go stale. **Measured 2026-09-01**: five of six open publications read `clean`,
the oldest six days old, and landing them queued roughly fifteen tickets for work the loop had
already finished — two whole missions of it, one of them a second plan of an ask that had already
been driven.

- **Candidates** — `mergeability` of `mechanical` or `clean` whose `age_hours` is at least
  `WORKAHOLIC_PUBLICATION_STALE_HOURS` (default 48). **Disjoint from the `content` set by
  construction**, so no publication ever draws both questions — the `retire-claims` /
  `stalled-units` division applied to one reader's rows. An **unreadable** age is not a candidate:
  asking on an absence is what the three-valued readings exist to avoid.
- **Heading** — *something the loop wrote days ago is about to be published, and what it plans may
  already be done*, then the pull request and how long it has been open.
- **Body** — the one act: *say whether that plan is still wanted, or close the pull request.*
- **Addressed to** the publication's author.
- **It holds nothing, and that is the design.** `/implement` settles a `clean` or `mechanical`
  publication unconditionally, exactly as before this question existed — an age threshold on the
  **act** would strand precisely the publications the `clean` widening exists to deliver, and this
  repository has paid repeatedly for a reading that stops something and tells nobody. So the two
  run independently: usually the act wins the hour and the question is the record that nothing was
  landed silently; when a person gets there first, they can close it. **The rejected alternatives**
  are the act refusing on an age (it strands the deliverable set) and a survey-side test for a
  queued ticket whose work already exists (*already implemented* is a judgement about behaviour,
  not a file test — measured the same day, five of eight queued tickets had exact-title archived
  twins while three had none and their work existed anyway).
- **Two ages, never conflated**: `open_hours` is how long the **pull request** has been open;
  `age` is how long the **question** has been asked, through `lib/read-age.sh` as above.

---

## What did not move with any of this wording

Ticket `20260831200959-rewrite-each-step-s-question-to-that-contract` (2026-08-31) rewrote the
specs above and **touched no script**. Every question key expression, the per-tick cap, the
daily bound, the quiet-hours window, the working-day gate, each question's addressee derivation
and each question's age reading are byte-identical, and **changing a body never re-asks**:
`already_asked` keys on the step id `lib/question-id.sh` derives from the key, never on the text.
That is what made a sweep of thirteen steps' wording safe to make in one change, and it is the
reason the contract is stated in `workaholic:notify`'s catalog rather than enforced by a gate —
nothing mechanical tells a self-explanatory question from a cryptic one. What it buys is that a
question leading with an identifier is **visibly non-conformant**, the enforcement the connector
retry and the Open Decisions floor already rest on.

**A step added after the sweep is held to the same contract.** `cadence-lapse` (§30) landed in
parallel with this one, so its spec was not rewritten here; the contract is the catalog's and
applies to every question-asking step, whenever it was written. A new step's question is
conformant or it is not, and nothing about the order in which two missions merged changes that.

**The steps that ask nothing were not given a voice.** `merge-conflicts`, `issue-triage`,
`doc-drift`, `release-status`, `note-cadence`, `closable-missions`, `thread-reconcile`,
`file-findings` and `standing-rulings` reach a person through some other seam or through no
seam at all, and the contract governs the `🙋` reply only.

**One case could not be made self-contained inside the bound, and is named rather than
stretched**: `direction-arrived` carries the residue — up to three mission slugs then `and N
more` — because the operator is being asked to *close a direction* and cannot rule on that
without seeing what the reading could not attribute. It rides the **heading**, where the named
details already ride, and the body keeps its one sentence. The bound was not raised for it: the
measured failure was a question that said the wrong things, not one that said too few.
