---
name: branching
description: Context detection and branch pattern matching for unified commands.
allowed-tools: Bash, Read
user-invocable: false
---

# Branching

Detect development context from the current git branch pattern to route unified commands to the appropriate workflow.

## Context Detection

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/detect-context.sh
```

### Output Format

| Context | Branch Pattern | JSON |
| ------- | -------------- | ---- |
| `drive` | `drive-*` | `{"context": "drive", "branch": "<branch>"}` |
| `trip` | `trip/*` (no tickets in todo) | `{"context": "trip", "branch": "<branch>", "trip_name": "<name>"}` |
| `trip_drive` | `trip/*` (with tickets in todo) | `{"context": "trip_drive", "branch": "<branch>", "trip_name": "<name>"}` |
| `trip_worktree` | Other (with trip worktrees) | `{"context": "trip_worktree", "branch": "<branch>"}` |
| `unknown` | `main`, `master`, or other | `{"context": "unknown", "branch": "<branch>"}` |

### Context Routing

- **drive**: Route to Drivin workflows (story generation, version bump, drive-style PR)
- **trip**: Route to Trippin workflows (artifact gathering, journey report, worktree cleanup)
- **trip_drive**: Trip branch that has transitioned to drive-style development (tickets exist in todo). Commands offer a choice between drive and trip workflows.
- **trip_worktree**: Not on a trip branch, but trip worktrees exist. List worktrees and let the user choose.
- **unknown**: Cannot determine context. Ask the user which workflow to use.

## Worktree Guard

Lightweight check for the existence of worktrees. Used by commands that should warn the user before proceeding when worktrees are available.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/check-worktrees.sh
```

### Output Format

```json
{
  "has_worktrees": true,
  "count": 2,
  "trip_count": 1,
  "drive_count": 1
}
```

- `has_worktrees`: Boolean indicating if any worktrees exist
- `count`: Total number of worktrees found
- `trip_count`: Number of `trip/*` branch worktrees
- `drive_count`: Number of `drive-*` branch worktrees

Unlike `list-trip-worktrees.sh`, this script does not query GitHub API for PR status. It is designed for fast, non-blocking guard checks.

## Workspace Guard

Check whether the working directory has unstaged, untracked, or staged changes. Used by commands that should warn the user before proceeding when the workspace is not clean.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/check-workspace.sh
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
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/adopt-worktree.sh <branch-name>
```

Output: `{"worktree_path": "<path>", "branch": "<branch>", "switched_from": true|false}`

Error cases: branch not found, worktree already exists, uncommitted changes.

### Eject

Collapse a worktree back to a regular branch in the main working tree. Preserves the branch (unlike `cleanup-worktree.sh` which deletes it).

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/eject-worktree.sh <worktree-path>
```

Output: `{"ejected": true, "branch": "<branch>", "main_repo": "<path>"}`

Error cases: not a valid worktree, main tree has uncommitted changes.

### List All Worktrees

List all active worktrees with type detection (`trip`, `drive`, `other`). No GitHub API calls.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/list-all-worktrees.sh
```

Output:
```json
{
  "count": 2,
  "worktrees": [
    {"name": "drive-20260320-123456", "branch": "drive-20260320-123456", "worktree_path": "/path/.worktrees/drive-20260320-123456", "type": "drive"},
    {"name": "trip-20260319-040153", "branch": "trip/trip-20260319-040153", "worktree_path": "/path/.worktrees/trip-20260319-040153", "type": "trip"}
  ]
}
```

### List Trip Worktrees

List active trip worktrees with PR status. Queries GitHub API for each worktree, so slower than `list-all-worktrees.sh`.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/list-trip-worktrees.sh
```

Output:
```json
{
  "count": 1,
  "worktrees": [
    {"trip_name": "trip-20260319-040153", "branch": "trip/trip-20260319-040153", "worktree_path": "/path/.worktrees/trip-20260319-040153", "has_pr": true, "pr_number": 42, "pr_url": "https://github.com/..."}
  ]
}
```

### Ensure Worktree

Create an isolated worktree and branch for a trip session. Creates `.worktrees/<trip-name>/` directory and a `trip/<trip-name>` branch.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/ensure-worktree.sh <trip-name>
```

Output: `{"worktree_path": "<path>", "branch": "trip/<trip-name>"}`

Error cases: trip name missing, worktree already exists, branch already exists.

### Create Trip Branch

Create a `trip/*` branch without a worktree. The trip runs in the main working tree.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/create-trip-branch.sh <trip-name>
```

Output: `{"branch": "trip/<trip-name>", "worktree": false}`

Error cases: trip name missing, branch already exists.

### Cleanup Worktree

Remove a trip worktree and its local branch after PR merge. Force-removes the worktree directory, prunes stale entries, and deletes the local branch.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/cleanup-worktree.sh <trip-name>
```

Output: `{"cleaned": true, "worktree_path": "<path>", "branch": "trip/<trip-name>", "worktree_removed": true, "branch_removed": true}`

## Branch State Check

Check if the current branch is main/master or a topic branch.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/check.sh
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

Topic branch patterns: `drive-*`, `trip-*`

## Create Topic Branch

Create a new timestamped topic branch from the current branch.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/create.sh [prefix]
```

### Arguments

- `prefix` (optional): Branch prefix. Defaults to "drive".
  - **drive** - for TiDD style development
  - **trip** - for more AI oriented development

### Output Format

```json
{
  "branch": "drive-20260202-204753"
}
```

## Check Version Bump

Check if a "Bump version" commit already exists in the current branch.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/check-version-bump.sh
```

### Output Format

```json
{
  "already_bumped": true
}
```

- `already_bumped`: Boolean indicating if a version bump commit exists in the branch
