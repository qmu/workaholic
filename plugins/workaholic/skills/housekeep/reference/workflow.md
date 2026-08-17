# The nine-step contract — reference

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

- **Reads**: the layout allowlist; `.workaholic/housekeeping/`.
- **Writes**: nothing. The log line `run.sh` writes for it *is* the open.
- **Aborts**: `no_workaholic_dir` (nothing here to keep), `area_unregistered` (this checkout's
  plugin predates the area — the tick still runs, its log does not), `unwritable`.
- **Never**: creates the area behind the layout gate's back. A step that made its own directory
  would be routing around the gate rather than reporting it.

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
  self-filed *assigned* issue would be re-discovered by `[Propose]` every hour forever — a record
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
  `[Propose]` only takes issues assigned to the running identity, so someone else's issue lands
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
- **One reminder per distinct state.** The key is `stuck:<digest>` over the sorted
  `<number>:<blocked_by>` set, so an unchanged answer is never repeated while a new pull request or
  a changed reason earns a post. **Two gates, both required**: something actionable, and no earlier
  post for this exact state — the tick log answers the second, and `workaholic:notify`'s stateless
  lookup answers it again on the wire. The key is deliberately distinct from `[Release Status]`'s
  `deploy:<digest>`: one reports what is waiting to deploy, this what is waiting on a human, and a
  shared key would let either dedup the other away.
- **Aborts**: `gh_unavailable`. Already-posted state is `ok`/`already_filed`, not a second post.

## 7. `doc-drift` — the documentation against the current concept

- **Reads**: `report/scripts/doc-drift.sh` (structural presence changes versus the documents that
  enumerate them) and `report/scripts/area-freshness.sh` (a hand-maintained record naming something
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

## 8. `strategy-proposals` — GATED: it proposes nothing until the operator rules

- **Reads**: `strategy/scripts/list.sh`. Nothing else, because it acts on nothing.
- **Writes**: **nothing at all**, by decision (2026-08-17). Its own mission says why: *every step
  reversing a standing decision is ruled on by the operator or left unbuilt, never inferred* — and
  this step reverses one. `workaholic:propose`'s judgment bar states that **missions, the queue and
  commits are constraints, never triggers**; feedback is the only input that can originate a
  proposal, and the retired `[Propose Batch]` routine was exactly the state-sweep this step
  reintroduces, with a recorded failure mode of "a channel full of plausible noise".
- **Three independent rulings are outstanding**, and the step names them in every report:
  1. **Does a strategy originate a proposal at all?** The argument in favour is real and is
     *recorded rather than acted on*: a strategy is not repository state — it is the operator's own
     resolved, dated, owned direction, which sits far closer to feedback than to a backlog sweep.
     If it is accepted, it belongs in `workaholic:propose` as a second originator, so there is one
     bar and not two. Accepting it is the operator's act.
  2. **Which Slack shape?** The ask's `🟡 Proposing` collides twice — 🟡 is the handoff finish line
     today, and the start post was retired on 2026-08-11 ("a routine posts its finish only"). And
     `workaholic:notify`'s *the prompt is the ceiling* means no session may emit a shape the
     routine's own prompt does not name, so a shape settled here alone would still be inert.
  3. **What counts as "negative feedback"?** A reaction, a token in a reply, a human closing the
     pull request, and a model's reading of a thread have four very different false-positive
     rates, and an auto-close on a misread reply destroys a proposal nobody rejected. Of the four,
     an **explicit token** is the only one whose false-positive rate is a property of the rule
     rather than of the reader.
- **Aborts**: `no_strategies` — today's actual state, reported rather than left silently empty;
  `awaiting_operator_ruling` (`blocked`) once a strategy exists, because then the ruling is live;
  `no_strategy_reader` when the strategy skill is absent.
- **When it is built**: reuse `/propose`'s emission machinery (publish tree → record → scaffold →
  one pull request) rather than a second copy of it — only the *trigger* differs — put the ask's
  "about a week" reaction window in **one named constant**, derive the in-flight state from the
  open pull request's age rather than a stored cursor (the repository is the coordination medium),
  and make a decline leave a record naming the reason **and** a closed pull request, never a closed
  pull request alone.

## 9. `human-checkin` — up to five questions, never late at night

- **Reads**: what the earlier steps returned; the clock, in the workspace's timezone.
- **Writes**: nothing to the repository. Questions are **Slack posts** — a routine-fired session
  has no `AskUserQuestion`, and this skill's standing rule forbids one anyway.
- **Aborts**: `quiet_hours` (with the boundary and timezone named), `no_surface`, `nothing_to_ask`.
- **Bounded**: at most five questions per tick, and the bound is enforced in the step, not left to
  the model's judgment.
- Ticket: `20260817113754`.

---

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
