---
name: propose
description: Use when the proposal batch runs — headlessly (cron) or by hand via /propose — to survey the repository's recent state and either stay silent or propose a draft mission with its ticket set on a work branch behind a pull request. Defines the cursor contract, the judgment bar, the draft schema, and the batch's scripts.
allowed-tools: Bash
user-invocable: false
metadata:
  internal: true
---

# Propose

The AI half of "humans supply feedback, the AI proposes missions" (`docs/loop-engineering-workflow.md` §6.3, decisions C2–C4, B1): a batch that surveys the repository's recent state and either does nothing or proposes **a draft mission together with the ticket set it implies** — `status: draft`, unowned, `feedback:`-linked — on a `work-*` branch behind a pull request, for humans to discuss and approve.

**The model, stated before the mechanics** (`workaholic:planning` / `modeling-centric-design`): the relation direction is **mission → feedback** — a proposed mission records the feedback records it grew from in its `feedback:` frontmatter list; nothing is ever stored on the feedback side. The stream stays immutable, dedup reads the missions, and traceability is a walk from any draft back to the human words that caused it.

**What the batch answers.** Not "has anyone written feedback lately" but **what should be done next** — and that answer is constrained by more than the feedback stream. Three further signals shape it, and the batch reads all of them (`survey-state.sh`): what is already **planned** (the missions and their derived progress), what is already **queued** (the todo tickets), and what has just been **built** (the commits since the cursor). A proposer blind to those re-proposes work that is underway or already decided, which is the noise the judgment bar exists to prevent — so widening the inputs is what makes the bar's job possible, not a relaxation of it.

**A proposal is a mission *and* its tickets.** A draft mission with a provisional acceptance sketch and no ticket set is a title and a hope, not something a developer can judge; `/drive`'s own survey says so mechanically by dropping such a mission as `no_tickets`. This is safe without inventing a gate: `drive/scripts/plan-units.sh` excludes **any** ticket carrying a `mission:` relation from the backlog offer (`mission_member`), whatever the mission's status — so a ticket proposed under a draft is unclaimable by construction, protected by the same draft gate as the mission. Re-check that property if the exclusion is ever narrowed.

**A proposal arrives as a pull request.** Every workaholic artifact — feedback, mission, ticket — is committed on a `work-*` branch and reaches `main` through a **merged** pull request, because the merge is the event that can be announced. The batch therefore writes through the **publish tree** and lands on a branch via `branching/scripts/publish-tree-pr.sh`, never straight to the base. Writing through the publish tree is what keeps this compatible with an interactive caller: `.publish/` is an independent checkout, so a developer's branch and uncommitted work are untouched (`workaholic:branching`, decision J2).

## Headless — the defining constraint

This skill runs where **nobody can answer**: a cron tick on a server. Therefore:

- **No `AskUserQuestion`, ever.** There is no interactive fallback; a situation that would need a human is an abort with a machine-readable reason (or silence), never a prompt.
- **Silence is a valid outcome.** No new feedback, nothing warranting a mission, everything already referenced — each ends the run quietly with the cursor advanced.
- **The cursor advances only after success.** A run that aborts (dirty tree, failed push, failed pull request) must re-read the same window next tick; advancing on failure loses feedback silently.

  **Success means "the pull request is open", not "it is merged"** — and that choice is deliberate. Merging is a human act with no deadline, so a cursor that waited for it would re-read the same window on every tick until someone reviewed, and re-propose what is already sitting in an open PR. Once the PR exists the feedback *has been acted on*, which is what the cursor records. The cost is that a **closed-unmerged** proposal is not re-proposed: its feedback is behind the cursor. That is correct — a human closed it, which is a decision, not an omission.

## The judgment bar

Whether the surveyed state warrants a proposal is a **model judgment with a conservative, written bar**. The bar is stated per input, because the inputs differ in what they can license:

**Feedback is the only input that can *originate* a proposal.**

- Propose only when a record contains **actionable direction warranting a bounded batch of tickets** — typically `kind: instruction` ("build/change X") or a substantial `insight` that names concrete work. One mission may draw on several records; several independent directions may become several missions.
- A lone `kind: concern`, a `material`/`answer` record, or a purely informational note is **not** a trigger — concerns feed later replans and planning sessions, not fresh proposals.

**Missions, the queue, and commits are *constraints*, never triggers.** They can only shrink a proposal or veto it — never license one on their own. This asymmetry is the whole reason widening the inputs does not widen the output:

- **Missions** — a direction that merely restates an existing mission's scope is silence, not a second mission (check titles and `feedback:` refs). A direction that *sharpens* an active mission belongs in a replan (`/mission "<instruction>"`), which is a human act, not a proposal.
- **The queue** — work already specified as a todo ticket is not proposed again, and a proposal must not duplicate a queued ticket's implementation steps.
- **Commits** — recently built work narrows what remains. A commit log is evidence about what is *done*; it never by itself says what should come next, and treating "this area changed a lot" as a reason to propose is exactly the pattern that fills a channel with plausible noise.

**The asymmetry is written policy**: a false negative costs one cron cycle (a human can always run `/mission` by hand); a false positive spams the channel and erodes trust in the loop. When unsure, stay silent. On a 15-minute tick, "there is always something proposable" is a symptom of a broken bar, not a productive batch.

## Draft missions

A draft is scaffolded by `scaffold-draft.sh` (NOT `mission/scripts/create.sh` — that scaffold seeds the creator as owner, and a draft **predates approval, so it has no approver yet**):

```yaml
type: Mission
status: draft            # in the ACTIVE area — a draft is in flight, not history
merge_policy:            # empty — the approval records it, never this batch
assignees: []            # unowned until a human approves
assignee:
feedback: [<record filenames>]   # the mission→feedback relation
```

`status: draft` is the **unapproved** state of the one mission lifecycle axis (`workaholic:mission`'s *Lifecycle*), living in `missions/active/` (the area split keys archive on `achieved|abandoned|carried` only). A draft is invisible to executors — they run only `status: approved` work — and `list.sh` reports it with `ready_reason: "draft"`. The batch fills `## Goal`/`## Scope`/`## Experience` and a **proposed** `## Acceptance` sketch (clearly provisional; the write-time floor stays untouched because that floor fires on `approved`, never on a draft).

**Approval is a real, human flow, not a phase label**: `/mission approve <slug>` interrogates the draft to drive-ready, asks the one merge-policy ruling (`auto` | `review`), and runs `mission/scripts/approve.sh` — the only path to `status: approved`. This batch never approves, never seeds `assignees`, and never records a merge policy.

## Scripts

### cursor.sh — the processed-commit cursor

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/cursor.sh read
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/cursor.sh advance <commit>
```

Stores the last-processed main commit in `.workaholic/proposal-cursor` — **runner-local state** (decision C1: one server runs the batch; the phase-3 claim protocol is the multi-runner answer), git-ignored via the repo's shared `info/exclude` (the script ensures the line itself, idempotently). `read` bootstraps an absent cursor to the current `origin/main` HEAD and reports `{"initialized": true, ...}` — pre-existing feedback is treated as already-seen (a safe cold start; backdate the file by hand to replay). `advance` refuses a non-commit.

### new-feedback.sh — the window

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/new-feedback.sh <cursor-commit>
```

Feedback records **added** under `.workaholic/feedbacks/` between the cursor and `origin/main` (`index.md` excluded), each with its frontmatter summary (`{path, title, kind, source, author}`). `[]` when none. Pure read.

### survey-state.sh — the constraints

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/survey-state.sh <cursor-commit> [base]
```

Everything the judgment needs beyond the feedback window: `{missions, queue, commits}` — the missions with their derived progress and ownership, the todo queue with titles, and the commit subjects between the cursor and the base. **The commit window is the same window as the feedback window**, so "new" means one thing across the batch. Pure read, and it **composes the existing readers** (`mission/scripts/list.sh`, `drive/scripts/list-todo.sh`) rather than parsing frontmatter itself — a survey that disagreed with the machinery acting on it would be worse than no survey. An unresolvable cursor yields an empty commit list rather than an error; cursor validity belongs to the feedback window reader alone.

### read-feedback-relation.sh — the single reader

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/read-feedback-relation.sh <mission-file>
```

Reads a mission's `feedback:` list (inline-list + bare forms, frontmatter only, one filename per line, never fails) — the mirror of `mission/scripts/read-relation.sh`. Every consumer goes through this; nothing parses the field itself.

### list-proposed-refs.sh — the dedup set

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/list-proposed-refs.sh
```

The union of `feedback:` refs across **every** mission (active + archive), one filename per line. Feedback already referenced by any mission never spawns a second proposal.

### scaffold-draft.sh — the draft writer

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/scaffold-draft.sh "<title>" <feedback-filename>...
```

Writes the draft `mission.md` (schema above; slug via `mission/scripts/slug.sh`; the four body sections scaffolded), refreshes the OKF indexes, git-stages. Refuses an existing slug in either area. Emits `{created, slug, path}`.

### scaffold-proposed-ticket.sh — the ticket writer

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/scaffold-proposed-ticket.sh "<title>" <mission-slug> [type] [layer]
```

Writes one proposed ticket into `todo/<user>/` carrying `mission: <slug>` — the relation that makes it unclaimable until the mission is approved. Refuses a mission that does not resolve (`mission_missing`), because a dangling relation is exactly what `validate-ticket.sh` rejects. `merge_policy` is left **empty**, which reads as `review`: the batch has no authority to grant automatic merging, and that ruling belongs to `/mission approve`. The mandatory `## Policies` and `## Quality Gate` sections are scaffolded with guidance rather than omitted, so the artifact is valid the moment it is written. Emits `{created, path, slug, mission}`.

### publish-tree-pr.sh — the destination

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/publish-tree-pr.sh <title> <why> <changes> <concerns> <insights> <verify> [files...]
```

Lives in `workaholic:branching` because every artifact writer needs it, not just this batch. Commits what was written into the publish tree, pushes it to a fresh `work-*` remote branch, and opens the pull request. Emits `{ok, sha, branch, pr_url, base}`, or `{ok: false, reason}` — and note that `pr_failed` still reports `branch` and `sha`, because the artifact **is** pushed: the recovery is to open the PR by hand, never to re-publish and duplicate it.

## Notifier contract

After each successful draft push, the batch calls `notify-slack.sh` (this skill's `scripts/`) with the proposal message — posted **as the bot** (decision E2). The notifier is **environment-driven and never load-bearing**:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/notify-slack.sh "<text>"
```

- Config: `SLACK_BOT_TOKEN` (xoxb, `chat:write`) + `WORKAHOLIC_SLACK_CHANNEL` (channel id); `WORKAHOLIC_SLACK_API_URL` overrides the endpoint for tests (the hermetic suite never calls Slack). The token is read at call time and never persisted, logged, or echoed.
- No token/channel → `{"notified": false, "reason": "no_token"|"no_channel"}`, exit 0 — a proposal that pushed is a success whether or not anyone was told; the run report records `notified` per draft rather than retrying in-loop. Endpoint/API failures are recorded the same way (`http_<code>`/`slack_<error>`/`curl_failed`), never fatal.
- Provisioning, the cron entry, and failure modes live in `docs/proposal-loop-runbook.md` — the runbook is the developer's page; agents never install the crontab themselves.

## Agent Compatibility

This skill works on any Agent-Skills-compatible agent; all logic lives in the bundled POSIX scripts. The judgment bar is prose the running model applies — on any agent, headless or not, the no-prompt rule holds.
