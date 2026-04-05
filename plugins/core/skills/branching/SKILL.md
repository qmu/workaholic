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
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/detect-context.sh
```

### Output Format

| Context | Branch Pattern | JSON |
| ------- | -------------- | ---- |
| `work` | `work-*`, `drive-*`, `trip/*` | `{"context": "work", "branch": "<branch>", "mode": "<mode>"}` |
| `worktree` | Other (with worktrees) | `{"context": "worktree", "branch": "<branch>"}` |
| `unknown` | `main`, `master`, or other | `{"context": "unknown", "branch": "<branch>"}` |

### Mode Detection

The `mode` field distinguishes workflow style within the `work` context:

| Mode | Condition | Routing |
| ---- | --------- | ------- |
| `drive` | No trip artifacts, or tickets in todo | Story generation, version bump, drive-style PR |
| `trip` | Trip artifacts exist, no tickets in todo | Artifact gathering, journey report, worktree cleanup |
| `hybrid` | Both trip artifacts and tickets exist | Offer choice between drive and trip workflows |

### Context Routing

- **work**: Route to the appropriate workflow based on `mode` (drive, trip, or hybrid)
- **worktree**: Not on a work branch, but worktrees exist. List worktrees and let the user choose.
- **unknown**: Cannot determine context. Ask the user which workflow to use.

### Backward Compatibility

Legacy `drive-*` and `trip/*` branches are detected as `work` context with appropriate mode.

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
