---
name: propose
description: Use when the proposal batch runs — headlessly (cron) or by hand via /propose — to survey the repository's recent state and either stay silent or propose a mission with its ticket set on a work branch behind a pull request. Defines the cursor contract, the judgment bar, the proposal schema, and the batch's scripts.
allowed-tools: Bash
user-invocable: false
metadata:
  internal: true
---

# Propose

The AI half of "humans supply feedback, the AI proposes missions" (`docs/loop-engineering-workflow.md` §6.3, decisions C2–C4, B1): a batch that surveys the repository's recent state and either does nothing or proposes **a mission together with the ticket set it implies** — unowned, `feedback:`-linked, `merge_policy` empty — on a `work-*` branch behind a pull request, for humans to discuss and accept. **Merging that pull request is the approval** (2026-07-31, `docs/loop-engineering-workflow.md` K1); the batch marks nothing as unapproved, because the PR already is that state.

**The model, stated before the mechanics** (`workaholic:planning` / `modeling-centric-design`): the relation direction is **mission → feedback** — a proposed mission records the feedback records it grew from in its `feedback:` frontmatter list; nothing is ever stored on the feedback side. The stream stays immutable, dedup reads the missions, and traceability is a walk from any proposal back to the human words that caused it.

**What the batch answers.** Not "has anyone written feedback lately" but **what should be done next** — and that answer is constrained by more than the feedback stream. Three further signals shape it, and the batch reads all of them (`survey-state.sh`): what is already **planned** (the missions and their derived progress), what is already **queued** (the todo tickets), and what has just been **built** (the commits since the cursor). A proposer blind to those re-proposes work that is underway or already decided, which is the noise the judgment bar exists to prevent — so widening the inputs is what makes the bar's job possible, not a relaxation of it.

**A proposal is a mission *and* its tickets — at least two of them, or it is not proposed at all.** This is the ticket floor (`workaholic:mission`, *Granularity → The ticket floor*) applied to the seam that matters most: this batch creates missions on a schedule with nobody watching, so a creator that can emit a malformed artifact emits many before anyone looks. A candidate the batch cannot decompose into two or more tickets is **dropped, and the drop is reported in the batch's own output** — never published and never left silent. Staying silent is already a valid outcome of this run, so this adds no new failure mode; what it adds is that the reason is stated. The check reads `queue-size.sh`'s `meets_floor` at the publish seam, not in `scaffold-draft.sh`, which runs before any ticket exists.

A mission with a provisional acceptance sketch and no ticket set is a title and a hope, not something a developer can judge; `/drive`'s own survey says so mechanically by dropping such a mission as `no_tickets`. Nothing here is claimable before the pull request merges — the proposal does not exist on `main` until then — and everything here is claimable after it, which is the intended contract. `drive/scripts/plan-units.sh` additionally excludes **any** ticket carrying a `mission:` relation from the *backlog* offer (`mission_member`), so a proposed ticket is never picked up loose, only as part of its mission's unit. Re-check that property if the exclusion is ever narrowed.

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

A proposal is scaffolded by `scaffold-draft.sh` (NOT `mission/scripts/create.sh` — that scaffold seeds the creator as owner, and **this batch has no business owning what it proposes**):

```yaml
type: Mission
status: active           # the one in-flight state — in flight, not history
merge_policy:            # empty — the approval records it, never this batch
assignees: []            # unowned — claimable by anyone once merged
assignee:
feedback: [<record filenames>]   # the mission→feedback relation
```

`status: active` is the one in-flight state of the mission lifecycle axis (`workaholic:mission`'s *Lifecycle*), living in `missions/active/` (the area split keys archive on `achieved|abandoned|carried` only). What keeps the proposal out of an executor's reach is not a status word but the **pull request**: it is not on `main`, so no survey can see it. The batch fills `## Goal`/`## Scope`/`## Experience` and a **proposed** `## Acceptance` sketch (clearly provisional). Note that `hooks/validate-mission.sh` now fires on any active mission, so the batch's Edit filling those sections must land a non-empty `## Experience` and at least one `## Acceptance` item in that write.

**Approval is a real, human act, and it is the merge**: a reviewer reads the proposal's pull request, interrogates it to drive-ready via `/mission <instruction referencing it>` if the sketch is thin, and merges — at which point `/drive` can claim it. This batch never seeds `assignees` and never records a merge policy, so its proposals arrive unowned with an empty `merge_policy`, which reads as `review`.

## Scripts

### cursor.sh — the processed-commit cursor

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/cursor.sh read
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/cursor.sh advance <commit>
```

Stores the last-processed main commit as **`refs/workaholic/proposal-cursor` on origin** — a pushed ref every runner reads, with the local ref of the same name as the read-through copy. Decision C1's "the cursor may be runner-local" premise is **superseded**: the batch's live deployment is a scheduled routine in a **fresh container each tick**, where a runner-local file never exists — so every read bootstrapped, reported `initialized: true`, and the run stopped there forever. Storing the cursor the way the claim protocol stores claims makes initialization happen **once per repository** instead of once per container.

- `read` → `{commit, initialized, fetched}`. Absent on origin → bootstrap to `origin/main` HEAD **and push it** (`initialized: true`, `pushed: true`); pre-existing feedback is treated as already-seen, the safe cold start. Origin unreachable → the **reader degrades**: the last-fetched local value with `fetched: false` (a stale cursor only re-reads an old window, and dedup absorbs that).
- `advance <commit>` → pushes under `--force-with-lease` against the value this batch read, so **push is the race arbiter and no clock is ever compared**. A lost race is a reported no-op (`{"advanced": false, "reason": "raced"}`, exit 0) — the winner has already covered that window. A genuine push failure is **loud** (exit 1), because the next tick then re-reads the same window, which is the safe direction. A non-commit is refused.
- **Migration is living and idempotent**: a legacy `.workaholic/proposal-cursor` file seeds the bootstrap when the shared ref is absent, and is removed once the ref holds the value — after that it is never consulted.

The advance-only-after-the-pull-request-is-open semantics above are unchanged; only where the value lives has changed.

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

### scaffold-draft.sh — the proposal writer

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/scaffold-draft.sh "<title>" <feedback-filename>...
```

Writes the proposed `mission.md` (schema above; slug via `mission/scripts/slug.sh`; the four body sections scaffolded), refreshes the OKF indexes, git-stages. The script keeps its name — what it writes is still a *draft in the ordinary sense*, a proposal nobody has accepted — but that state lives in the pull request now, not in the file. Refuses an existing slug in either area. Emits `{created, slug, path}`.

### scaffold-proposed-ticket.sh — the ticket writer

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/scaffold-proposed-ticket.sh "<title>" <mission-slug> [type] [layer]
```

Writes one proposed ticket into `todo/<user>/` carrying `mission: <slug>` — the relation that makes it driveable only as part of its mission's unit, never as loose backlog.

**Stamp the acceptance link after the set is written.** This batch is an emitting seam like the Creation Interrogation and the replan, and it is the seam where the defect was measured: every one of the 37 acceptance items across the six missions this batch has scaffolded was unlinked, so no board it wrote could ever move. Once the tickets exist, run `mission/scripts/link-acceptance.sh <slug> <item-selector> <ticket-filename>` once per acceptance item the set satisfies. The batch decided the pairing when it decomposed the proposal, so it is naming what it already knows — **never inferring**; an item no proposed ticket satisfies stays unlinked and is named in the pull request body instead. Refuses a mission that does not resolve (`mission_missing`), because a dangling relation is exactly what `validate-ticket.sh` rejects. `merge_policy` is left **empty**, which reads as `review`: an unattended proposer must not decide that its own output may merge unattended. The mandatory `## Policies` and `## Quality Gate` sections are scaffolded with guidance rather than omitted, so the artifact is valid the moment it is written. Emits `{created, path, slug, mission}`.

### publish-tree-pr.sh — the destination

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/publish-tree-pr.sh <title> <why> <changes> <concerns> <insights> <verify> [files...]
```

Lives in `workaholic:branching` because every artifact writer needs it, not just this batch. Commits what was written into the publish tree, pushes it to a fresh `work-*` remote branch, and opens the pull request. Emits `{ok, sha, branch, pr_url, base}`, or `{ok: false, reason}` — and note that `pr_failed` still reports `branch` and `sha`, because the artifact **is** pushed: the recovery is to open the PR by hand, never to re-publish and duplicate it.

## Notifier contract

After each successful proposal push, the batch calls `notify-slack.sh` (this skill's `scripts/`) with the proposal message — posted **as the bot** (decision E2). The notifier is **environment-driven and never load-bearing**:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/notify-slack.sh "<text>"
```

- Config: `SLACK_BOT_TOKEN` (xoxb, `chat:write`) + `WORKAHOLIC_SLACK_CHANNEL` (channel id); `WORKAHOLIC_SLACK_API_URL` overrides the endpoint for tests (the hermetic suite never calls Slack). The token is read at call time and never persisted, logged, or echoed.
- No token/channel → `{"notified": false, "reason": "no_token"|"no_channel"}`, exit 0 — a proposal that pushed is a success whether or not anyone was told; the run report records `notified` per proposal rather than retrying in-loop. Endpoint/API failures are recorded the same way (`http_<code>`/`slack_<error>`/`curl_failed`), never fatal.
- Provisioning, the cron entry, and failure modes live in `docs/proposal-loop-runbook.md` — the runbook is the developer's page; agents never install the crontab themselves.

## Agent Compatibility

This skill works on any Agent-Skills-compatible agent; all logic lives in the bundled POSIX scripts. The judgment bar is prose the running model applies — on any agent, headless or not, the no-prompt rule holds.
