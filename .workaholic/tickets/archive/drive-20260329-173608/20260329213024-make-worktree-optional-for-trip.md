---
created_at: 2026-03-29T21:30:24+09:00
author: a@qmu.jp
type: enhancement
layer: [UX, Config]
effort: 0.25h
commit_hash: e898684
category: Changed
---

# Make Worktree Optional for /trip Command

## Overview

Currently `/trip` always creates a worktree for isolation. After this change, `/trip` offers a choice: create a worktree (isolated environment) or create a branch only (`trip/*` branch in the main working tree). This means trip branches no longer imply worktrees. A new core script `create-trip-branch.sh` creates a `trip/*` branch without a worktree. The `detect-context.sh` script must also handle trip branches without worktrees -- a `trip/*` branch in the main tree should still be detected as "trip" context.

## Key Files

- `plugins/core/skills/branching/sh/create-trip-branch.sh` - NEW: create `trip/*` branch without worktree, output JSON with branch name
- `plugins/trippin/commands/trip.md` - Step 1: add choice between "Create worktree" and "Branch only" for new trips
- `plugins/core/skills/branching/sh/detect-context.sh` - Verify `trip/*` detection works regardless of whether a worktree exists (currently checks `trip/*` branch pattern directly, which should work)
- `plugins/core/skills/branching/SKILL.md` - Document new `create-trip-branch.sh` script and branch-only trip mode
- `plugins/core/commands/ship.md` - Trip context cleanup step must handle the case where no worktree exists (skip cleanup gracefully)

## Related History

The trip workflow was designed around worktree isolation from inception. The `/trip` command always created a worktree as a fundamental assumption. The trip-drive hybrid context was added later to support drive-style development on trip branches, but it still assumed the worktree existed.

- [20260316143858-trip-drive-cross-command-compatibility.md](.workaholic/tickets/archive/drive-20260312-102414/20260316143858-trip-drive-cross-command-compatibility.md) - Added trip_drive hybrid context; established that trip branches can participate in drive workflows (same branch pattern concern)
- [20260311212022-unify-report-command-across-plugins.md](.workaholic/tickets/archive/drive-20260311-125319/20260311212022-unify-report-command-across-plugins.md) - Created detect-context.sh with branch-pattern-based routing; trip/* pattern detection is already branch-based, not worktree-based
- [20260311212023-unify-ship-command-across-plugins.md](.workaholic/tickets/archive/drive-20260311-125319/20260311212023-unify-ship-command-across-plugins.md) - Unified /ship with worktree cleanup step for trip context; cleanup must become conditional

## Implementation Steps

1. **Create `plugins/core/skills/branching/sh/create-trip-branch.sh`**:
   - Accept a trip name argument (e.g., `trip-20260329-213024`)
   - Create branch `trip/<trip-name>` from HEAD
   - Switch to the new branch (`git checkout -b trip/<trip-name>`)
   - Output JSON: `{"branch": "trip/<trip-name>", "worktree": false}`
   - Do NOT create a worktree directory

2. **Update `plugins/trippin/commands/trip.md` Step 1**:
   - After checking for existing trip worktrees (resume flow unchanged)
   - For new trips, present a choice via AskUserQuestion:
     - **"Create worktree"** - Follow existing flow: run `ensure-worktree.sh` (from core branching after ticket 2)
     - **"Branch only"** - Run `create-trip-branch.sh` from core branching; trip runs in the main working tree
   - Adjust subsequent steps: when "Branch only" is chosen, the working directory is the current directory (not a worktree path)

3. **Update `plugins/core/skills/branching/sh/detect-context.sh`**:
   - Review the existing trip/* detection logic (lines 22-33)
   - The current code checks `[[ "$branch" == trip/* ]]` which matches regardless of worktree presence -- this is already correct
   - No changes needed unless the hybrid check (ticket file count) needs adjustment

4. **Update `plugins/core/commands/ship.md`** trip context:
   - The cleanup worktree step (line 56) must check whether a worktree exists before attempting cleanup
   - Add a conditional: check if `.worktrees/<trip-name>/` exists before running `cleanup-worktree.sh`
   - If no worktree exists, skip the cleanup step and log "No worktree to clean up"

5. **Update `plugins/core/skills/branching/SKILL.md`**:
   - Add "Create Trip Branch" section documenting `create-trip-branch.sh <trip-name>` usage
   - Document that trip branches can exist with or without worktrees
   - Add a note distinguishing the two modes: worktree (isolated, Agent Teams) vs branch-only (main tree, lightweight)

## Considerations

- Agent Teams during `/trip` Step 4 may have assumptions about the working directory being a worktree. When running in "Branch only" mode, all agents work in the main repository root. This should be transparent to agents since they operate on files via absolute paths, but the `trip-commit.sh` and other trip-protocol scripts may need to handle the non-worktree case. (`plugins/trippin/skills/trip-protocol/sh/trip-commit.sh`)
- The `validate-dev-env.sh` script takes a worktree path argument. In branch-only mode, pass the repository root instead. (`plugins/trippin/skills/trip-protocol/sh/validate-dev-env.sh`)
- The `init-trip.sh` script creates `.workaholic/.trips/<trip-name>/` which works regardless of worktree presence since it is relative to the git root. (`plugins/trippin/skills/trip-protocol/sh/init-trip.sh`)
- The resume flow in `/trip` Step 1 currently lists worktrees. Branch-only trips would not appear in the worktree list. Consider also listing `trip/*` branches without worktrees as resumable sessions, using `git branch --list 'trip/*'` alongside worktree detection. (`plugins/trippin/commands/trip.md`)
- The `/ship` command's `trip_worktree` context (line 68-77) lists worktrees with PRs. Branch-only trips would not appear here. The `detect-context.sh` already routes `trip/*` branches to "trip" context directly, so this is not a problem for the user on the branch. But if the user is on main, branch-only trips are invisible to the worktree discovery. This is acceptable since the user would need to checkout the trip branch first. (`plugins/core/commands/ship.md`)
- This ticket depends on ticket 2 (`20260329213022-move-worktree-lifecycle-scripts-to-core.md`) since the `ensure-worktree.sh` and `create-trip-branch.sh` scripts should both live in `plugins/core/skills/branching/sh/`. Cross-reference: `20260329213025-declare-plugin-dependencies.md`
