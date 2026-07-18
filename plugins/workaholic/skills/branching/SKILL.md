---
name: branching
description: Context detection and branch pattern matching for unified commands.
allowed-tools: Bash, Read
user-invocable: false
metadata:
  internal: true
---

# Branching

Detect development context from the current git branch pattern to route unified commands to the appropriate workflow.

## Context Detection

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/detect-context.sh
```

### Output Format

| Context | Branch Pattern | JSON |
| ------- | -------------- | ---- |
| `work` | `work-*` (created); `drive-*`, `trip/*` (legacy, detected only) | `{"context": "work", "branch": "<branch>", "mode": "<mode>"}` |
| `worktree` | Other (with worktrees) | `{"context": "worktree", "branch": "<branch>"}` |
| `unknown` | `main`, `master`, or other | `{"context": "unknown", "branch": "<branch>"}` |

### Mode Detection

The `mode` field distinguishes workflow style within the `work` context. Both predicates are **scoped to the caller**, never to the repository: trips to *this branch*, tickets to *this user*.

| Mode | Condition | Routing |
| ---- | --------- | ------- |
| `drive` | No trip artifacts **for this branch** (with or without tickets in todo) | Story generation, version bump, drive-style PR |
| `trip` | Trip artifacts **for this branch**, no tickets in this user's todo | Artifact gathering, journey report, worktree cleanup |
| `hybrid` | Both this branch's trip artifacts and this user's tickets exist | Offer choice between drive and trip workflows |

**"For this branch" is narrow, and deliberately so.** The only trip↔branch association this repository records is the legacy naming convention — branch `trip/<name>` owns `.workaholic/trips/<name>`. A modern `work-*` branch stores no link to any trip: `init-trip.sh` records no branch, `plan.md` carries no branch field, and a trip's branch is an independent `work-YYYYMMDD-HHMMSS` from `create.sh`. **A `work-*`/`drive-*` branch therefore never reports `trip` or `hybrid`**, regardless of what exists under `.workaholic/trips/`.

Before this, `has_trips` was a repo-wide `find` for *any* trip directory, so one March 2026 trip dir on `main` made every branch after it report `trip` or `hybrid` forever. Restoring a real mode for modern trips requires *deciding* the association, which is its own change — `trip_name` is likewise emitted only for `trip/*` branches, so `report/SKILL.md`'s Trip Mode step 3 cannot resolve `<trip-name>` on a `work-*` branch either. Both must be answered together.

### Context Routing

- **work**: Route to the appropriate workflow based on `mode` (drive, trip, or hybrid)
- **worktree**: Not on a work branch, but worktrees exist. List worktrees and let the user choose.
- **unknown**: Cannot determine context. Ask the user which workflow to use.

### Backward Compatibility

Legacy `drive-*` and `trip/*` branches are **detected** as `work` context with the appropriate mode. They are recognized for backward compatibility only — **never created**. New branches are always `work-<timestamp>` (see Create Topic Branch).

## Worktree Guard

Lightweight check for the existence of worktrees. Used by commands that should warn the user before proceeding when worktrees are available.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check-worktrees.sh
```

### Output Format

```json
{
  "has_worktrees": true,
  "count": 2,
  "work_count": 2
}
```

- `has_worktrees`: Boolean indicating if any worktrees exist
- `count`: Total number of worktrees found
- `work_count`: Number of work branch worktrees (`work-*`, `drive-*`, `trip/*`)

Unlike `list-worktrees.sh`, this script does not query GitHub API for PR status. It is designed for fast, non-blocking guard checks.

## Workspace Guard

Check whether the working directory has unstaged, untracked, or staged changes. Used by commands that should warn the user before proceeding when the workspace is not clean.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check-workspace.sh
```

### Output Format

```json
{
  "clean": false,
  "untracked_count": 2,
  "unstaged_count": 3,
  "staged_count": 0,
  "summary": "3 unstaged, 2 untracked"
}
```

- `clean`: Boolean indicating if the workspace has no changes
- `untracked_count`: Number of untracked files
- `unstaged_count`: Number of unstaged modifications or deletions
- `staged_count`: Number of staged changes
- `summary`: Human-readable description of changes (empty string when clean)

Unlike context detection, this script does not inspect branch patterns. It only reports workspace cleanliness.

## Worktree Management

### Adopt

Take an existing branch and create a worktree for it at `.worktrees/<branch-name>/`. Handles the case where the user is currently on that branch by switching to `main` first.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/adopt-worktree.sh <branch-name>
```

Output: `{"worktree_path": "<path>", "branch": "<branch>", "switched_from": true|false}`

Error cases: branch not found, worktree already exists, uncommitted changes.

### Eject

Collapse a worktree back to a regular branch in the main working tree. Preserves the branch (unlike `cleanup-worktree.sh` which deletes it).

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/eject-worktree.sh <worktree-path>
```

Output: `{"ejected": true, "branch": "<branch>", "main_repo": "<path>"}`

Error cases: not a valid worktree, main tree has uncommitted changes.

### List All Worktrees

List all active worktrees with type detection (`work`, `other`). No GitHub API calls.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/list-all-worktrees.sh
```

Output:
```json
{
  "count": 2,
  "worktrees": [
    {"name": "work-20260404-014400", "branch": "work-20260404-014400", "worktree_path": "/path/.worktrees/work-20260404-014400", "type": "work"},
    {"name": "work-20260403-230430", "branch": "work-20260403-230430", "worktree_path": "/path/.worktrees/work-20260403-230430", "type": "work"}
  ]
}
```

### List Worktrees with PR Status

List active work worktrees with PR status. Queries GitHub API for each worktree, so slower than `list-all-worktrees.sh`.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/list-worktrees.sh
```

Output:
```json
{
  "count": 1,
  "worktrees": [
    {"name": "work-20260404-014400", "branch": "work-20260404-014400", "worktree_path": "/path/.worktrees/work-20260404-014400", "has_pr": true, "pr_number": 42, "pr_url": "https://github.com/..."}
  ]
}
```

### Ensure Worktree

Create an isolated worktree and branch. Creates `.worktrees/<branch-name>/` directory and a new branch.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/ensure-worktree.sh <branch-name>
```

Output: `{"worktree_path": "<path>", "branch": "<branch-name>"}`

Error cases: branch name missing, worktree already exists, branch already exists.

### Cleanup Worktree

Remove a worktree and its local branch after PR merge. Force-removes the worktree directory, prunes stale entries, and deletes the local branch.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/cleanup-worktree.sh <branch-name>
```

Output: `{"cleaned": true, "worktree_path": "<path>", "branch": "<branch-name>", "worktree_removed": true, "branch_removed": true}`

### Mission Worktrees

A **mission** runs in a dedicated, persistent worktree keyed by a **descriptive slug directory** — `.worktrees/<mission-slug>/` (e.g. `.worktrees/real-time-notifications/`), *not* a `work-*` directory. The branch checked out inside is still an ordinary `work-YYYYMMDD-HHMMSS` branch (the branch-name invariant is preserved); only the directory carries the mission's name. The worktree persists across many branches (each cut from `main`, merged, and re-cut) and is removed only when the mission is closed.

Create a mission worktree — cuts a fresh `work-*` branch off the base (default `main`) into `.worktrees/<slug>/` and copies the root `.env` in. The base is **resolved to a concrete commit SHA** (local ref, else `origin/<base>`) before it reaches `git worktree add`, so git's remote-tracking DWIM can never silently discard the `-b` and land the worktree on the base branch itself (the desk / fresh-clone state where no local `main` exists); the reported `branch` is then **read back from the worktree's real HEAD**, so it is an observation, not a restatement of intent:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/create-mission-worktree.sh <slug> [base-branch]
```

Output: `{"worktree_path": "<path>", "branch": "work-YYYYMMDD-HHMMSS", "slug": "<slug>", "port_base": N, "dev_port": N, "docs_port": N+1}`. Errors on a missing/invalid slug, a non-git dir, an existing worktree, a base that resolves to no commit, or a created worktree whose HEAD disagrees with the minted branch (never an exit-0 JSON on a wrong-branch worktree).

Each mission worktree is assigned a **unique local port base** (via `allocate-worktree-port.sh` below) written into its `.env` as `WORKAHOLIC_PORT_BASE`/`WORKAHOLIC_DEV_PORT`/`WORKAHOLIC_DOCS_PORT`, so several worktrees can run dev/docs servers at once without colliding on `localhost` (and each can be driven/verified independently, e.g. via Playwright). A project's serve scripts read these variables with their own env precedence; workaholic supplies the unique numbers and the convention, not the servers.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/allocate-worktree-port.sh
```

Returns the next free port base (`{port_base, dev_port, docs_port}`), scanning the bases already assigned in existing `.worktrees/*/.env` — so a removed worktree's base is reusable (allocation tracks live worktrees, not an ever-growing counter).

Remove a mission worktree (only sanctioned at `/mission close`) — **never discards uncommitted work**: refuses a dirty worktree and reports it; idempotent when already gone:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/cleanup-mission-worktree.sh <slug>
```

Reset a mission worktree for its next batch after a merge — cuts a fresh `work-*` branch off `main` inside the same worktree (the worktree persists; only the branch is renewed). `/ship` calls this instead of `cleanup-worktree.sh` for a mission worktree:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/reset-mission-worktree.sh <slug> [base-branch]
```

`list-all-worktrees.sh` tags a `.worktrees/<slug>` worktree with `"type": "mission"` (ordinary `work-*` dirs stay `"type": "work"`), so `/ship` and the mission lens can distinguish a mission worktree from a drive/trip one. `create-mission-worktree.sh` also adds `.worktrees/` to `.git/info/exclude` so a linked worktree is never accidentally embedded as a gitlink by a main-tree `git add -A`.

## Credentials — root `.env`

Development credentials live in **one** git-ignored `.env` at the repository root — the single credential source (not per-package, not per-worktree-authored). When working with worktrees, treat the `.env` as something to carry along:

- **New worktrees carry it automatically.** `ensure-worktree.sh` **copies** the root `.env` into each worktree it creates (a *copy*, not a symlink — so worktrees diverge credentials independently), and silently skips the copy when the root has no `.env`. A branch created in the main tree via `create.sh` already sits beside the root `.env`, so no copy is needed there.
- **Pre-existing / externally-created worktrees need a manual copy.** A worktree that predates this convention, or was created outside `ensure-worktree.sh`, has **no** `.env` — before it can serve or authenticate, copy it in: `cp <repo-root>/.env .env`. Bring the `.env` along as a matter of judgment, not only when `ensure-worktree.sh` happens to run.

The cleanup side is symmetric: `/trip`'s worktree teardown **preserves** git-ignored files like `.env` when syncing a worktree back (see `workaholic:trip-protocol`).

## Branch State Check

Check if the current branch is main/master or a topic branch.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check.sh
```

### Output Format

```json
{
  "on_main": true,
  "branch": "main"
}
```

- `on_main`: Boolean indicating if on main/master branch
- `branch`: Current branch name

Topic branch patterns: `work-*`

## Create Topic Branch

Create a new timestamped topic branch from the current branch.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/create.sh
```

**Sole branch-name format (mandatory):** branches are **always** named exactly `work-<YYYYMMDD-HHMMSS>` by `create.sh`. This is the only branch-creation path. Never name a branch yourself, never append a feature/description suffix, and never use another prefix. The `drive-*` and `trip/*` forms below are **legacy, detection-only** — recognized for backward compatibility, never created anew.

### Output Format

```json
{
  "branch": "work-20260404-014400"
}
```

## Check Version Bump

Check if a "Bump version" commit already exists in the current branch.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check-version-bump.sh
```

### Output Format

```json
{
  "already_bumped": true
}
```

- `already_bumped`: Boolean indicating if a version bump commit exists in the branch
