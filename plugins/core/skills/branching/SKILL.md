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
