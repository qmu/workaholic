---
created_at: 2026-03-11T10:56:14+09:00
author: a@qmu.jp
type: enhancement
layer: [UX, Config, Infrastructure]
effort: 0.25h
commit_hash: b69c0db
category: Added
---

# Add /ship-trip Command to Trippin Plugin

## Overview

Create a new `/ship-trip` command in the Trippin plugin that completes the delivery workflow after `/report-trip` has created a pull request. The command merges the PR, cleans up the worktree, deploys to production, and verifies the deployment. Like its Drivin counterpart, Claude Code acts as the deployment agent, following instructions in a user-provided `cloud.md` file.

The key difference from `/ship-drive` is worktree cleanup: trip sessions run in isolated git worktrees, and after the PR is merged, the worktree and its local branch must be removed. The cloud.md convention and deployment/verification logic are shared with the Drivin plugin's ship skill.

## Key Files

- `plugins/trippin/commands/report-trip.md` - Existing report command that creates the PR; ship-trip runs after this
- `plugins/trippin/skills/trip-protocol/SKILL.md` - Worktree isolation conventions and branch naming (`trip/<trip-name>`)
- `plugins/trippin/skills/trip-protocol/sh/ensure-worktree.sh` - Worktree creation script; reference for path and branch conventions
- `plugins/drivin/skills/ship/SKILL.md` - Cloud.md convention and deployment knowledge (established by ship-drive ticket)
- `plugins/drivin/skills/ship/sh/pre-check.sh` - PR pre-check script (reusable across plugins)
- `plugins/drivin/skills/ship/sh/merge-pr.sh` - PR merge script (reusable across plugins)
- `plugins/drivin/skills/ship/sh/find-cloud-md.sh` - Cloud.md discovery script (reusable across plugins)
- `plugins/trippin/README.md` - Needs new command entry
- `plugins/trippin/.claude-plugin/plugin.json` - Plugin configuration
- `README.md` - Trippin command table needs updating
- `CLAUDE.md` - Project Structure comment needs updating if Trippin commands are listed

## Related History

The Trippin plugin currently ends its workflow at PR creation via `/report-trip`. The worktree lifecycle is partially managed: `ensure-worktree.sh` creates worktrees but there is no corresponding cleanup mechanism. The ship command closes this gap by removing the worktree after the PR is merged.

Past tickets that touched similar areas:

- [20260311103508-add-report-trip-command.md](.workaholic/tickets/archive/drive-20260310-220224/20260311103508-add-report-trip-command.md) - Added /report-trip, the immediate predecessor step in the trip workflow
- [20260309214650-implement-trip-command.md](.workaholic/tickets/archive/drive-20260302-213941/20260309214650-implement-trip-command.md) - Implemented the trip command with worktree creation and Agent Teams workflow
- [20260311103507-rename-report-to-report-drive.md](.workaholic/tickets/archive/drive-20260310-220224/20260311103507-rename-report-to-report-drive.md) - Established the command naming convention with plugin suffix (-drive, -trip)

## Implementation Steps

1. **Create a worktree cleanup shell script** at `plugins/trippin/skills/trip-protocol/sh/cleanup-worktree.sh`:
   - Accept the trip name as argument
   - Determine the worktree path (`.worktrees/<trip-name>/`) and branch name (`trip/<trip-name>`)
   - Remove the worktree with `git worktree remove <path>`
   - Delete the local branch with `git branch -d <branch>` (safe delete since it was merged)
   - Output JSON: `{"cleaned": true, "worktree_path": "...", "branch": "..."}`
   - Handle edge cases: worktree already removed, branch already deleted
   - This script complements `ensure-worktree.sh` (create) with the corresponding teardown

2. **Create the ship-trip command** at `plugins/trippin/commands/ship-trip.md`:
   - Frontmatter: `name: ship-trip`, description referencing PR merge, worktree cleanup, and deployment
   - Preload the `trip-protocol` skill for worktree conventions
   - **Step 1: Identify trip context** - Determine the trip name from the current branch (`trip/<trip-name>` format) or from `$ARGUMENT`. If not on a trip branch and no argument provided, inform user and stop.
   - **Step 2: Pre-check** - Run the Drivin ship skill's `pre-check.sh` with the trip branch name. If no PR found, inform user and stop. If PR is already merged, skip to worktree cleanup.
   - **Step 3: Merge PR** - Run the Drivin ship skill's `merge-pr.sh` with the PR number. After merge succeeds, the local main branch is synced.
   - **Step 4: Clean up worktree** - Run `cleanup-worktree.sh` with the trip name. Remove the worktree directory and delete the local trip branch.
   - **Step 5: Deploy** - Run the Drivin ship skill's `find-cloud-md.sh` to locate cloud.md. If found, read the `## Deploy` section and execute the instructions from the main branch (now at the merged revision). If not found, inform user that deployment was skipped.
   - **Step 6: Verify** - If cloud.md was found, read the `## Verify` section and execute verification steps. Report success or failure.
   - Keep to ~60-90 lines (orchestration only)

3. **Update `plugins/trippin/README.md`**:
   - Add `/ship-trip` to the Commands table

4. **Update `README.md`**:
   - Add `/ship-trip` to the Trippin command table

5. **Update `CLAUDE.md`**:
   - Update Project Structure comment if Trippin commands are listed

## Patches

### `plugins/trippin/README.md`

```diff
--- a/plugins/trippin/README.md
+++ b/plugins/trippin/README.md
@@ -7,6 +7,7 @@
 | `/trip <instruction>` | Launch Agent Teams session with Planner, Architect, and Constructor |
 | `/report-trip` | Generate trip journey report and create/update PR |
+| `/ship-trip` | Merge PR, clean up worktree, deploy, and verify |

 ## Skills
```

### `README.md`

> **Note**: This patch is speculative - verify line numbers before applying.

```diff
--- a/README.md
+++ b/README.md
@@ -46,6 +46,7 @@
 | Command    | What it does                                          |
 | ---------- | ----------------------------------------------------- |
 | `/trip`    | Launch Agent Teams session for collaborative design   |
 | `/report-trip` | Generate trip journey report and create PR        |
+| `/ship-trip`   | Merge PR, clean up worktree, deploy, and verify   |

 > [!NOTE]
```

## Considerations

- The ship-trip command reuses Drivin's ship skill scripts (`pre-check.sh`, `merge-pr.sh`, `find-cloud-md.sh`) via cross-plugin skill path references (`~/.claude/plugins/marketplaces/workaholic/plugins/drivin/skills/ship/sh/...`). This follows the existing pattern where Trippin already references Drivin skills for common operations. (`plugins/trippin/commands/ship-trip.md`)
- Worktree cleanup must happen AFTER the merge succeeds. If the merge fails, the worktree should be preserved so the user can fix issues and retry. (`plugins/trippin/skills/trip-protocol/sh/cleanup-worktree.sh`)
- The `git branch -d` (safe delete) will fail if the branch was not merged. Use `-d` not `-D` to prevent accidental deletion of unmerged work. The merge step ensures the branch is merged before cleanup. (`plugins/trippin/skills/trip-protocol/sh/cleanup-worktree.sh`)
- After worktree cleanup, the deploy step runs from the main branch at the merged revision. The `merge-pr.sh` script handles `git checkout main && git pull`, so the working directory should be on the correct revision. (`plugins/trippin/commands/ship-trip.md`)
- If the user runs `/ship-trip` from inside the worktree directory, the worktree removal will fail because the current working directory would be deleted. The command should detect this and either `cd` to the repo root first or instruct the user to run from the main repo. (`plugins/trippin/skills/trip-protocol/sh/cleanup-worktree.sh`)
- The cloud.md search should look in the main repository root, not the worktree, since the worktree may already be removed by the time deploy runs. (`plugins/trippin/commands/ship-trip.md`)
- Cross-reference: This ticket depends on the `/ship-drive` ticket which establishes the `ship` skill and cloud.md convention. Implement ship-drive first. (`.workaholic/tickets/todo/20260311105613-add-ship-drive-command.md`)

## Final Report

### Changes Made

- Created `plugins/trippin/skills/trip-protocol/sh/cleanup-worktree.sh` to remove worktree and delete local branch after merge
- Created `plugins/trippin/commands/ship-trip.md` with 7-step orchestration (identify trip, pre-check, merge, cleanup worktree, deploy, verify, complete)
- Updated `plugins/trippin/README.md` with `/ship-trip` command entry
- Updated `README.md` with `/ship-trip` in Trippin command table
- Updated `CLAUDE.md` Trippin project structure to list commands and skills

### Test Plan

- Verify `cleanup-worktree.sh` handles edge cases (already removed worktree, already deleted branch)
- Verify command file references correct absolute paths for both Drivin ship scripts and Trippin cleanup script
- Verify command follows architecture policy (thin orchestration, no inline conditionals)
