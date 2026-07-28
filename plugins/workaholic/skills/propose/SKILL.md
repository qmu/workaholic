---
name: propose
description: Use when the proposal batch runs — headlessly (cron) or by hand via /propose — to read feedback newly merged to main and either stay silent or register draft missions with feedback traceability. Defines the cursor contract, the judgment bar, the draft schema, and the batch's scripts.
allowed-tools: Bash
user-invocable: false
metadata:
  internal: true
---

# Propose

The AI half of "humans supply feedback, the AI proposes missions" (`docs/loop-engineering-workflow.md` §6.3, decisions C2–C4, B1): a batch that reads feedback **newly merged to main** and either does nothing or registers **draft missions** — `status: draft`, unowned, `feedback:`-linked — for humans to discuss and approve.

**The model, stated before the mechanics** (`workaholic:planning` / `modeling-centric-design`): the relation direction is **mission → feedback** — a proposed mission records the feedback records it grew from in its `feedback:` frontmatter list; nothing is ever stored on the feedback side. The stream stays immutable, dedup reads the missions, and traceability is a walk from any draft back to the human words that caused it.

## Headless — the defining constraint

This skill runs where **nobody can answer**: a cron tick on a server. Therefore:

- **No `AskUserQuestion`, ever.** There is no interactive fallback; a situation that would need a human is an abort with a machine-readable reason (or silence), never a prompt.
- **Silence is a valid outcome.** No new feedback, nothing warranting a mission, everything already referenced — each ends the run quietly with the cursor advanced.
- **The cursor advances only after success.** A run that aborts (dirty tree, failed push) must re-read the same window next tick; advancing on failure loses feedback silently.

## The judgment bar

Whether new feedback warrants a mission is a **model judgment with a conservative, written bar**:

- Propose a mission only when the feedback contains **actionable direction warranting a bounded batch of tickets** — typically `kind: instruction` ("build/change X") or a substantial `insight` that names concrete work. One mission may draw on several records; several independent directions may become several missions.
- A lone `kind: concern`, a `material`/`answer` record, or a purely informational note is **not** a mission trigger — concerns feed later replans and planning sessions, not fresh proposals.
- Never propose from feedback that merely restates an existing mission's scope (check titles and `feedback:` refs); silence over noise.
- **The asymmetry is written policy**: a false negative costs one cron cycle (a human can always run `/mission` by hand); a false positive spams the channel and erodes trust in the loop. When unsure, stay silent.

## Draft missions

A draft is scaffolded by `scaffold-draft.sh` (NOT `mission/scripts/create.sh` — that scaffold seeds the creator as owner, and a draft **predates approval, so it has no approver yet**):

```yaml
type: Mission
status: draft            # in the ACTIVE area — a draft is in flight, not history
assignees: []            # unowned until a human approves
assignee:
drive_authorized:        # empty — only approval (phase 3) may authorize
feedback: [<record filenames>]   # the mission→feedback relation
```

`status: draft` is a first-class mission status living in `missions/active/` (the area split keys archive on `achieved|abandoned|carried` only). A draft is invisible to executors — `/drive`/`/monitor` run only `drive_authorized` work, and drafts never carry the stamp — and `list.sh` reports it with `ready_reason: "draft"`. The batch fills `## Goal`/`## Scope`/`## Experience` and a **proposed** `## Acceptance` sketch (clearly provisional — approval replans it to drive-ready; the write-time floor stays untouched because a draft is never authorized).

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

## Notifier contract

After each successful draft push, the batch calls `notify-slack.sh` (this skill's `scripts/`) with the proposal message. The notifier is **environment-driven and never load-bearing**: no token → `{"notified": false, "reason": "no_token"}`, exit 0 — a proposal that pushed is a success whether or not anyone was told, and the run report records `notified` per draft rather than retrying in-loop.

## Agent Compatibility

This skill works on any Agent-Skills-compatible agent; all logic lives in the bundled POSIX scripts. The judgment bar is prose the running model applies — on any agent, headless or not, the no-prompt rule holds.
