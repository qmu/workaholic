---
name: worktree
description: Manage worktrees - adopt existing branches, eject back, or list all worktrees.
skills:
  - branching
---

# Worktree

**Notice:** When user input contains `/worktree` -- whether "run /worktree", "adopt worktree", "eject worktree", "list worktrees", or similar -- they likely want this command.

Manage git worktrees: adopt an existing branch into a worktree, eject a worktree back to a regular branch, or list all active worktrees.

## Instructions

### Step 1: Determine Operation

Parse `$ARGUMENT` to determine the operation:

- If argument contains "adopt" or a branch name (e.g., `drive-20260320-123456`): **Adopt**
- If argument contains "eject": **Eject**
- If argument contains "list" or is empty: **List**

### Step 2: Execute Operation

#### Adopt

Adopt an existing branch into a worktree for isolated development.

1. Determine the branch name from the argument. If not provided, use the current branch.
2. Run:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/adopt-worktree.sh "<branch-name>"
   ```
3. On success: report the worktree path and suggest `cd <worktree_path>` to start working there. If `switched_from` is true, note that the main working tree was switched to `main`.
4. On error: report the error message.

#### Eject

Collapse a worktree back to a regular branch in the main working tree.

1. List worktrees to let the user pick:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/list-all-worktrees.sh
   ```
2. If no worktrees exist, inform the user.
3. If one worktree, confirm with the user via AskUserQuestion.
4. If multiple, let the user pick via AskUserQuestion.
5. Run:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/eject-worktree.sh "<worktree-path>"
   ```
6. On success: report that the branch is now checked out in the main working tree.
7. On error: report the error message.

#### List

Show all active worktrees with type information.

1. Run:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/list-all-worktrees.sh
   ```
2. Display the results in a readable format showing name, branch, path, and type for each worktree.
3. If no worktrees exist, inform the user.
