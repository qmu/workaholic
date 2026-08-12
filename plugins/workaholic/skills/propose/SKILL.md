---
name: propose
description: Use when a session has an ask in hand — the [Propose] routine's clock tick that discovers one (the open GitHub issues assigned to this identity), or /propose by hand — to judge it against the conservative bar and emit, in one publish-tree pull request, the feedback record together with whatever the judgment warrants. Defines the clock-fired discovery, the judgment bar, the three forms a proposal takes, the proposal schema, and the scripts.
allowed-tools: Bash
user-invocable: false
skills:
  - workaholic:notify
metadata:
  internal: true
---

# Propose

The AI half of "humans supply feedback, the AI proposes missions" (`docs/loop-engineering-workflow.md` §6.3): a session with an ask in hand judges it and emits, in **one** pull request, the feedback record together with whatever the judgment warrants — a mission with its ticket set, one loose ticket, or the record alone. Everything it proposes is `feedback:`-linked with `merge_policy` empty (reads as `review`), on a `work-*` branch whose pull request **merges immediately after it opens** (`WORKAHOLIC_AUTO_MERGE=1`; mission `auto-merge-propose-and-implement-prs-under-a-dev-release-branch-split`, 2026-08-11, superseding K1's approval-by-merge for this flow): `main` is the continuously auto-merged development branch, and quality is gated downstream — the `release/*` QA window and the scoped QA/release-planning/post-release loops — not at merge time. A release-scan finding is the one thing that leaves the PR open for a human.

## Propose at the capture seam

The judgment happens in the session that receives the ask (developer's ruling, 2026-08-04, superseding a batch sweep over merged `main` — that proposer could not see the record its own capture session had just written, so a second seat, a cron cadence and a shared cursor existed only to compensate; `docs/proposal-loop-runbook.md`). The capture session holds what no later reader can recover: the reporter's words, the thread they arrived in, and the record it just wrote. The inputs keep their asymmetry: the **ask in hand** originates a proposal, while the repository's own state — what is planned, queued, and recently built, read from the base (`survey-state.sh`, `list-proposed-refs.sh`), never from the caller's imagination — can only shrink one or veto it. The relation direction is **artifact → feedback**: a proposal records its source records in its own `feedback:` frontmatter list; nothing is ever stored on the feedback side, so the stream stays immutable and dedup reads the artifacts.

## Clock-fired discovery

Since `[Propose]` fires on an hourly schedule rather than a GitHub issue trigger (FB
`20260810085032`), no event hands the session an issue — so a run that starts with
nothing in hand **discovers its own asks** before conceding `nothing_in_hand`
(developer's instruction, 2026-08-12, closing the gap the schedule migration left
open): `list-inbound-issues.sh` lists the open GitHub issues on this repository
**assigned to the session's own identity**, excludes any a feedback record already
names (`already_captured` — reported, never silently dropped), and hands back the rest
oldest-first. Each returned issue is an ask in hand exactly as if the retired trigger
had delivered it: run the full workflow per issue — its own record, its own judgment,
its own pull request with `Closes #<N>` — one at a time.

The inbox is read through **REST** (`gather/scripts/gh-rest.sh` → `gh api
repos/{owner}/{repo}/issues`), never through `gh issue list` (2026-08-12, FB
`20260812172522`). That subcommand is GraphQL-backed, and a Claude Code Web session is
not guaranteed to serve that surface: measured HTTP 403 "only the pinned set of
PR-review operations is served" in this repository's own tick, 80 minutes after the same
path had worked — the capability is a property of the **session**, so a run must degrade
rather than stop. Two consequences of the REST endpoint are handled deliberately and
must not be undone: it returns pull requests alongside issues (rows carrying
`.pull_request` are dropped, or a routine would propose against its own PRs), and it
paginates where `--limit` truncated (`per_page` carries the cap, so a single page
reproduces the old ceiling).

Three boundaries keep this from becoming the retired `[Propose Batch]` sweep:

- **It reads the inbound ask channel, never the repository's own state.** Issues are
  what people (and `/fb`'s cross-repository mode) open *at* this repository — the same
  input the retired event trigger delivered one at a time. Missions, the queue, and
  commits stay constraints (*The judgment bar*); nothing here reads them for something
  to propose.
- **Assigned to me only, never unassigned** — every developer's copy fires hourly, so
  an unassigned issue offered to every copy would have N runners race for it (the
  measured failure P8 records). An unassigned issue still reaches `/propose` by hand
  (`/propose #<N>`), where a human chose the one session that acts. The server-side
  filter also makes `not_mine` impossible on this path by construction.
- **No title filter.** `/fb`'s crossing deliberately adds no `[FB]`-style prefix to
  the issues it opens (`feedback/scripts/open-issue.sh` — the title is the target's,
  not ours), so a title filter would drop exactly the asks this loop exists to ingest.
  Assignment is the routing signal; the title is prose.

An unreadable inbox is reported, never rendered as an empty one: `ok: false` carries
its reason (`gh_unavailable` / `identity_unresolved` / `list_failed`) into the run's
report beside `nothing_in_hand`. For the exclusion to hold, the record each run writes
**must carry the issue's URL** (its `/issues/<N>` form) — the capture step's contract.

## Workflow

The run, in order — the step-by-step contract, with every script invocation, env-var
envelope, and abort reason, is [`reference/workflow.md`](reference/workflow.md):

1. **Take the ask in hand** — the command's argument, the record this session just
   wrote, or a record the caller named. **With none of those** — the clock-fired
   `[Propose]` tick — **discover the inbound issues** (`list-inbound-issues.sh`; below,
   *Clock-fired discovery*): each open GitHub issue assigned to this session's own
   identity is an ask in hand, taken oldest-first, each through the full run. Still
   none → `nothing_in_hand`; an ask assigned to someone else → `not_mine` (*Act only
   on an ask that is yours*, below).
2. **Open the publish tree** and **register the record** inside it — written whatever
   the judgment concludes.
3. **Read the constraints** (`survey-state.sh`), **discover** the mechanism the ask
   names or reports a failure of (below, *Discovery before scaffolding*), and **dedup**
   (`list-proposed-refs.sh`) — all before scaffolding anything.
4. **Judge and decide the form** (below); scaffold the mission and/or tickets, stamp the
   acceptance links, and check the ticket floor.
5. **Publish everything as one pull request** (`publish-tree-pr.sh` under
   `WORKAHOLIC_PR_TITLE`, and `WORKAHOLIC_CLOSES_ISSUE` when step 1 captured a
   triggering issue number — its merge then auto-closes that issue), close the
   publish tree,
   **notify**, and **report** one line: the form chosen with its reason, the record's
   filename, the PR URL, and the `notified` flag.

## Discovery before scaffolding

`/ticket` runs history/source/policy discovery before it writes anything (`workaholic:create-ticket`
§2); `/propose` had none, which let a store-location fork `/ticket`'s §4b would have
interrogated a human on get silently inherited from a reporter's framing instead of
inspected (qmu/workaholic#374). Step 3 of `reference/workflow.md` closes that gap: for an
ask that names an existing mechanism or reports a failure of one, run at least a
history-mode pass (`workaholic:discover`'s Discover History) before judging the form —
**inline, in this session**: unlike `/ticket`'s three parallel discovery modes, which
fan out to `general-purpose` subagents because they run concurrently, a single
history-mode pass has nothing to fan out to, so it runs directly in the command's own
context (Architecture Policy already permits this — no subagent, no open question).
Carry the resulting `diagnosis_first` verdict into the emitted ticket's
Implementation Steps (`workaholic:discover`, *Diagnosis-First Rule*). Scoped to the ask in
hand — this is not a second sweep of the backlog (the retired `[Propose Batch]` design).

### Open decisions

`/ticket` resolves a genuinely unrecommendable fork by asking the developer directly
(§4b); `/propose` cannot ask anyone. When discovery surfaces that kind of fork, record it
verbatim as an item in the emitted ticket's `## Open Decisions` section
(`create-ticket/reference/ticket-format.md`) instead of choosing for the reporter — the
driving session resolves it explicitly and records the resolution in its Final Report,
never a silent guess. Most proposals carry none; write the section only when a fork this
session cannot recommend one side of actually surfaced.

## The form follows the work's shape

The judgment decides cardinality before anything else, and there are exactly three answers:

| The direction | What the pull request carries |
| ------------- | ---------------------------- |
| Decomposes into **two or more** units of work | The record **plus a mission with its whole ordered ticket set** |
| Is **atomic** — one clearly actionable thing | The record **plus one loose backlog ticket**, no mission wrapper |
| Is neither decomposable nor clearly actionable (vague, a wish, a direction nobody can start) | **The record alone**, with the reason it warranted no work reported |

- **Record-only is an outcome of the judgment, never of the mechanics**: the session can always see the record it wrote, so "no proposal" means "this ask warrants none" — a statement a reader can disagree with. Say which it is, every time.
- **A mission is never one ticket** — the ticket floor, checked at the publish seam (`mission/scripts/check-floor.sh <slug>`; non-zero exit means this candidate is not published as a mission — fall back to a loose ticket or record-only and report the script's `alternative`), not in `scaffold-draft.sh`, which runs before any ticket exists.
- A **loose ticket** lands in the flat `todo/` behind the same pull request, carries no `mission:` key — so `plan-units.sh` offers it as ordinary backlog, while a mission's tickets are excluded from the loose offer as `mission_member` and driven only in their mission's unit — and its `feedback:` refs are mandatory (`no_feedback`): with no mission to hold the relation they are the only record of what it answers, and without them a re-asked direction has nothing to collide with.
- Do not dress a decomposable direction as one loose ticket, or an atomic one as a mission, to get something published: both trade the artifact's honesty for a publication. Nothing here is claimable before the pull request merges, and everything is after.

**Record and proposal arrive as one pull request.** Everything is written into the publish tree (`.publish/` is an independent checkout, so an interactive caller's branch and uncommitted work are untouched) and landed with a single `branching/scripts/publish-tree-pr.sh` call — never straight to the base and never as two pull requests: the record and the work it warrants are one decision, and splitting them would let a reviewer accept half of it. The pull request's **title carries the `[Proposal]` prefix** (`[提案]` when Japanese) — load-bearing, not cosmetic: the `[Implement]` routine's GitHub trigger filters merged pull requests by `title contains [Proposal]`, so a dropped prefix opens a pull request whose merge starts nothing. Set it through `WORKAHOLIC_PR_TITLE`, never the commit subject — the two are different surfaces with different rules (`check-subject.sh` forbids a `[bracket]` prefix on a subject; conflating them made every publish die at `commit_failed`, P4). The body carries **no notification target** (Q1, 2026-08-07 — P4's carried-target propagation is retired and its P9 disclosure withdrawn with it): `/implement`, started by the pull request's merge, finds the item's thread itself through the stateless exact-token lookup in `workaholic:notify` (*One thread per feedback item*), and this session's own finish post finds it the same way — the key is the record's `fb:<stem>`, in hand on both sides. Never thread by similarity or recency; a lookup that matches nothing posts a new keyed root.

## Act only on an ask that is yours

When the ask arrives from a GitHub issue carrying an assignee, compare it against the session's own GitHub identity (`gh api user` — the credential the session already holds, never an env var); when they differ, report `{"proposed": 0, "reason": "not_mine"}` and stop (P8). An unassigned issue is anyone's, exactly as an unowned artifact is. The check lives in the command, never in the routine prompt: the routines UI offers no assignee filter, so every developer's `[Propose]` fires on every assigned issue, and the dedup only sees proposals that already reached a branch. (`/implement` filters at its *survey* because its artifacts already carry `assignees`; `/propose` filters at its *input* because it creates them — one rule, asked at the only place each command can ask it.)

"Who" enters once, at the trigger, and rides the artifacts from there (P6):

```bash
scaffold-draft.sh "<title>" --assignee <email> <feedback-record>...
scaffold-proposed-ticket.sh "<title>" <mission-slug> --assignee <email>
```

Both write `assignees: [<email>]`; both write an empty field when no assignee is given — team-owned, claimable by anyone, a real state that stays available. Do not fall back to the running identity: that stamps whichever container executed the batch and silently assigns work to a runner rather than a person (measured: every unowned proposal had every developer's runner racing for it, whose push landed first deciding whose job it was).

## Unattended — the defining constraint

- **No `AskUserQuestion`, ever.** A situation that would need a human is an abort with a machine-readable reason; an ask too vague to judge is record-only, its ambiguity reported in the pull request.
- **The record is written whatever the judgment concludes** — capture is not conditional on proposing.
- **A failed publish loses nothing**: the publish tree is disposable and the ask stays in its thread. The exception is `pr_failed` — the artifact **is** pushed, so open the pull request by hand; never re-publish, which duplicates it.

## The judgment bar

A model judgment with a conservative, written bar, stated per input:

- **Feedback is the only input that can *originate* a proposal** — typically `kind: instruction`, or a substantial `insight` naming concrete work; one mission may draw on several records. A lone `concern`, a `material`/`answer` record, or a purely informational note is never a trigger — concerns feed replans and planning sessions. The `kind` is decided at capture (`workaholic:feedback`, *Choosing the kind*), and at this seam the same session decides both, so a misclassified ask is a self-inflicted record-only; the correction is a superseding record, never a bar loose enough to read concerns.
- **Missions, the queue, and commits are constraints, never triggers** — they can only shrink or veto: a direction restating an existing mission's scope is record-only (a direction that *sharpens* one belongs in a replan, a human act); work already specified as a todo ticket is not proposed again; commits say what is done, never what should come next — "this area changed a lot" is exactly the pattern that fills a channel with plausible noise.
- **Discovery is a fourth input, and it can only inform or veto, never originate** (*Discovery before scaffolding*, above): a history-mode pass over a named mechanism can turn an apparently-atomic ask into a mission (the mechanism is more entangled than the ask implies), surface a duplicate that makes the ask record-only, or leave the judgment unchanged — it never manufactures a proposal feedback did not originate.
- **When unsure, record-only** — and say what made you unsure. A false negative costs one reading (a human can run `/mission` from the merged record); a false positive publishes work nobody asked for and erodes trust in the loop.

## Draft missions

Scaffolded by `scaffold-draft.sh`, NOT `mission/scripts/create.sh` — that scaffold seeds the creator as owner, and an unattended proposer has no business owning what it proposes:

```yaml
type: Mission
status: active           # the one in-flight state — in flight, not history
merge_policy:            # empty — the approval records it, never this session
assignees: []            # unowned — claimable by anyone once merged
assignee:
feedback: [<record filenames>]   # the mission→feedback relation
```

What keeps the proposal out of an executor's reach is not a status word but the **pull request**: it is not on `main`, so no survey can see it. Fill `## Goal`/`## Experience` and a clearly provisional `## Acceptance` sketch in the same write (`hooks/validate-mission.sh` fires on any active mission). Approval is the merge of the one pull request carrying record and proposal; a thin sketch is interrogated to drive-ready by its reviewer via `/mission <instruction>`.

## Scripts

Full invocations with `${CLAUDE_PLUGIN_ROOT}` paths are in [`reference/workflow.md`](reference/workflow.md).

- **`survey-state.sh [since-commit] [base]`** — the constraints: `{missions, queue, commits, since, since_reason}`. Pure read; composes `mission/scripts/list.sh` and `drive/scripts/list-todo.sh` rather than parsing frontmatter itself. `since_reason` names how the commit window was chosen (`given` / `recent`, the last `WORKAHOLIC_PROPOSE_COMMIT_WINDOW` commits, default 20 / `unresolvable` / `none`) — a constraint that quietly became empty must not read like one that found nothing. Run it against the base (the publish tree, or a synced `main`).
- **`read-feedback-relation.sh <artifact-file>...`** — the single reader of `feedback:` lists (mirror of `mission/scripts/read-relation.sh`); takes missions or tickets, many at once. Every consumer goes through it — two parsers of one field eventually disagree, and the side that under-reads re-proposes answered feedback.
- **`list-proposed-refs.sh`** — the dedup set: the union of `feedback:` refs across every mission (active + archive) and every ticket (todo + archive) — the archive counts, since a driven ticket is the strongest evidence its feedback was acted on — **plus the same artifacts on unmerged remote branches**, via the claim protocol's own oracle, so an open proposal pull request counts as proposed (added 2026-08-05, after an ask proposed ten minutes earlier was proposed again). Deleting the branch is what frees the feedback again, and ambiguity resolves toward *including* a ref — a shallow clone over-reads and says so on stderr, because a duplicate proposal is loud and a suppressed one is quiet. At this seam the veto keys on the records the ask *restates* (the new record has no refs pointing at it yet); read the set before scaffolding, since what this session writes joins it immediately.
- **`scaffold-draft.sh "<title>" [--assignee <email>] <feedback-filename>...`** — writes the proposed `mission.md` (schema above; slug via `mission/scripts/slug.sh`), refreshes the OKF indexes, git-stages; refuses an existing slug. Emits `{created, slug, path}`.
- **`scaffold-proposed-ticket.sh "<title>" <mission-slug> | --loose --feedback <record>... [--assignee <email>]`** — one ticket into the flat `todo/`; the mission form carries `mission: <slug>`, the loose form carries `feedback:` instead (refused `no_feedback` without refs); `merge_policy` left empty; the mandatory `## Policies`/`## Quality Gate` sections scaffolded so the artifact is valid at write. Emits `{created, path, slug, mission, feedback, loose}` or a `reason` (`no_title`/`no_mission`/`mission_missing`/`no_feedback`/`exists`). **Stamp the acceptance links after the set is written** — `mission/scripts/link-acceptance.sh <slug> <item-selector> <ticket-filename>` once per satisfied item, naming the pairing decided at decomposition, never inferring; an unsatisfied item stays unlinked and is named in the PR body (37 unlinked items across six proposed missions is the measured cost of skipping this).
- **`branching/scripts/publish-tree-pr.sh <title> <why> <changes> <concerns> <insights> <verify>`** — one call, everything written; emits `{ok, sha, branch, pr_url, base}`; `pr_failed` still reports `branch` and `sha`. `WORKAHOLIC_CLOSES_ISSUE=<N>` threads a native `Closes #<N>` line into the body, so merging the pull request auto-closes the "[FB] ***" issue the ask came from — empty (the common case) emits no line.
- **`extract-issue-number.sh ["<argument>"]`** — the source for that env var: `CCR_TRIGGER_ISSUE_NUMBER` under a routine, else a `#<N>`/issue URL in the argument; emits `{"issue_number": "<N>"}` or `""`. Run at step 1, kept in hand through to step 10.
- **`list-inbound-issues.sh [feedbacks-dir]`** — the clock-fired discovery (*Clock-fired discovery*, above): the open GitHub issues assigned to the session's own identity, oldest-first, minus those a feedback record already names (each exclusion reported as `already_captured`); `WORKAHOLIC_PROPOSE_ISSUE_LIMIT` caps the page (default 20). Pure read, never load-bearing: a missing `gh` or a failed lookup is `{ok: false, reason, detail}` with exit 0 — an unreadable inbox is reported, never rendered as an empty one.

## Notifier contract

After a successful push, `notify-slack.sh "<text>"` posts the proposal message as the bot (`SLACK_BOT_TOKEN` + `WORKAHOLIC_SLACK_CHANNEL`; `WORKAHOLIC_SLACK_API_URL` overrides the endpoint for tests; the token is read at call time and never persisted or echoed). **Never load-bearing**: a missing token/channel or an API failure is `{"notified": false, "reason": ...}` with exit 0 — a proposal that pushed is a success whether or not anyone was told; the report records `notified` rather than retrying. The `[Propose]` routine posts its thread root through the account's Slack connector instead; provisioning and failure modes are `docs/proposal-loop-runbook.md`.

## Agent Compatibility

This skill works on any Agent-Skills-compatible agent; all logic lives in the bundled POSIX scripts. The judgment bar is prose the running model applies — on any agent, attended or not, the no-prompt rule holds.
