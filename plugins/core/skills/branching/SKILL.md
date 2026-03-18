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
bash ~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/branching/sh/detect-context.sh
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

Lightweight check for the existence of trip worktrees. Used by commands that should warn the user before proceeding when worktrees are available.

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/branching/sh/check-worktrees.sh
```

### Output Format

```json
{
  "has_worktrees": true,
  "count": 2
}
```

- `has_worktrees`: Boolean indicating if any trip worktrees exist
- `count`: Number of trip worktrees found

Unlike `list-trip-worktrees.sh`, this script does not query GitHub API for PR status. It is designed for fast, non-blocking guard checks.
