---
created_at: 2026-04-06T00:21:24+09:00
author: a@qmu.jp
type: enhancement
layer: [UX, Infrastructure]
effort:
commit_hash:
category:
---

# Prompt to sync gitignored file changes before worktree erase

## Overview

When `/ship` erases a worktree after PR merge, any changes to gitignored files (`.env`, `.local.md`, `.claude/settings.local.json`, or other project-specific ignored state) are permanently lost. Add an interactive prompt during the ship workflow that discovers modified gitignored files in the worktree, shows the developer what will be lost, and asks whether to copy those changes back to the main worktree before cleanup.

## Key Files

- `plugins/core/skills/branching/scripts/cleanup-worktree.sh` - Current worktree removal script; `git worktree remove --force` destroys all untracked/ignored files with no recovery
- `plugins/work/commands/ship.md` - Ship command workflow; step 3 ("Clean up worktree") calls cleanup-worktree.sh without any pre-cleanup guard for ignored files
- `plugins/work/skills/ship/SKILL.md` - Ship skill documentation; needs new section for the gitignored file sync step
- `plugins/work/skills/trip-protocol/scripts/validate-dev-env.sh` - Existing script that checks for `.env`/`.env.local` in worktrees; demonstrates the pattern of inspecting worktree state files

## Related History

The ship/worktree cleanup flow has been consolidated across several iterations: from separate ship-drive and ship-trip commands to a unified `/ship` with context-aware worktree cleanup, with the cleanup script itself moved from trippin to core.

Past tickets that touched similar areas:

- [20260404023155-move-ship-command-from-core-to-work.md](.workaholic/tickets/archive/drive-20260403-230430/20260404023155-move-ship-command-from-core-to-work.md) - Moved /ship from core to work plugin, updated all cleanup-worktree.sh path references (same layer: Infrastructure)
- [20260329213022-move-worktree-lifecycle-scripts-to-core.md](.workaholic/tickets/archive/drive-20260329-173608/20260329213022-move-worktree-lifecycle-scripts-to-core.md) - Moved ensure/cleanup/list worktree scripts to core branching skill (same files)
- [20260329213024-make-worktree-optional-for-trip.md](.workaholic/tickets/archive/drive-20260329-173608/20260329213024-make-worktree-optional-for-trip.md) - Made worktree cleanup conditional on worktree existence in /ship (same flow)
- [20260311212023-unify-ship-command-across-plugins.md](.workaholic/tickets/archive/drive-20260311-125319/20260311212023-unify-ship-command-across-plugins.md) - Unified /ship-drive and /ship-trip into single /ship with worktree cleanup step (same command)
- [20260328155752-add-clean-workspace-guard.md](.workaholic/tickets/archive/drive-20260326-183949/20260328155752-add-clean-workspace-guard.md) - Added workspace cleanliness guard to /ship and /report; similar pre-flight check pattern (same UX pattern)

## Implementation Steps

1. Create a new script `plugins/work/skills/ship/scripts/find-gitignored-files.sh` that:
   - Accepts a worktree path as argument
   - Uses `git -C <worktree> ls-files --others --ignored --exclude-standard` to list all gitignored files in the worktree
   - Compares each gitignored file against the main repo root to detect differences (new files in worktree, modified files vs main copy)
   - Outputs JSON: `{"has_changes": true/false, "files": [{"path": "relative/path", "status": "new|modified", "size": "123B"}]}`
   - Excludes common non-portable directories like `node_modules/`, `.venv/`, `vendor/bundle/`, `.cache/` from the diff (these are reinstallable)

2. Add a new step in `plugins/work/commands/ship.md` between the current step 2 ("Merge PR") and step 3 ("Clean up worktree"):
   - Run the `find-gitignored-files.sh` script against the worktree path
   - If `has_changes` is `false`, proceed silently to cleanup
   - If `has_changes` is `true`, display the file list and ask via AskUserQuestion with options:
     - **"Copy all to main worktree"** -- copy every changed gitignored file to the corresponding path in the main repo root
     - **"Select files to copy"** -- show the list and let the developer pick which files to sync
     - **"Skip and erase"** -- proceed with cleanup, discarding all gitignored changes
   - Execute the chosen action, then proceed to cleanup

3. Create a companion script `plugins/work/skills/ship/scripts/sync-gitignored-files.sh` that:
   - Accepts worktree path, main repo root, and a JSON list of file paths to copy
   - Copies each file from worktree to main repo root, creating parent directories as needed
   - Outputs JSON: `{"synced": true, "count": N, "files": ["path1", "path2"]}`

4. Update `plugins/work/skills/ship/SKILL.md` to document the new scripts (find-gitignored-files.sh and sync-gitignored-files.sh) with usage and output format

## Patches

### `plugins/work/commands/ship.md`

> **Note**: This patch is speculative - verify before applying.

```diff
--- a/plugins/work/commands/ship.md
+++ b/plugins/work/commands/ship.md
@@ -56,7 +56,9 @@
 
 1. **Pre-check**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/pre-check.sh "<branch>"`. If `found` is `false`: inform user "No PR found for this branch. Run `/report` first." and stop. If `merged` is `true`: skip to Clean up worktree.
 2. **Merge PR**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/merge-pr.sh "<pr-number>"`. On failure, inform user and stop.
-3. **Clean up worktree** (if applicable): Check if `.worktrees/<branch>/` exists. If yes, run `bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/cleanup-worktree.sh "<branch>"` and report what was cleaned up. If no worktree exists, skip this step.
+3. **Sync gitignored files** (if worktree exists): Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/find-gitignored-files.sh "<worktree-path>"`. If `has_changes` is `true`, display the file list and ask via AskUserQuestion with options: "Copy all to main worktree", "Select files to copy", or "Skip and erase". If "Copy all" or "Select files", run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/sync-gitignored-files.sh "<worktree-path>" "<main-repo-root>" '<files-json>'` for the chosen files. If `has_changes` is `false`, proceed silently.
+4. **Clean up worktree** (if applicable): Check if `.worktrees/<branch>/` exists. If yes, run `bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/cleanup-worktree.sh "<branch>"` and report what was cleaned up. If no worktree exists, skip this step.
-4. **Deploy**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/find-cloud-md.sh`. If `found` is `false`: inform user "No cloud.md found. Deployment skipped." and skip to summary. If `found` is `true`: read the file, find `## Deploy` section, ask confirmation via AskUserQuestion, execute if confirmed.
-5. **Verify**: If cloud.md found, read `## Verify` section and execute. Report results.
-6. **Summarize**: PR merge status (number, URL), worktree cleanup status, deployment status, verification results.
+5. **Deploy**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/find-cloud-md.sh`. If `found` is `false`: inform user "No cloud.md found. Deployment skipped." and skip to summary. If `found` is `true`: read the file, find `## Deploy` section, ask confirmation via AskUserQuestion, execute if confirmed.
+6. **Verify**: If cloud.md found, read `## Verify` section and execute. Report results.
+7. **Summarize**: PR merge status (number, URL), gitignored file sync status, worktree cleanup status, deployment status, verification results.
```

## Considerations

- The `find-gitignored-files.sh` script must exclude large reinstallable directories (`node_modules/`, `.venv/`, `vendor/bundle/`) to avoid overwhelming the developer with hundreds of irrelevant files. The exclusion list should be configurable or at least well-documented. (`plugins/work/skills/ship/scripts/find-gitignored-files.sh`)
- The "Select files to copy" option requires the ship command to present a file list and handle user selection, adding UX complexity. Consider whether this option is worth the added logic or if "Copy all" and "Skip" are sufficient for an MVP. (`plugins/work/commands/ship.md`)
- When copying files from the worktree to the main repo root, conflicts are possible if the main repo root already has a different version of the same gitignored file. The sync script should detect this and warn the developer rather than silently overwriting. (`plugins/work/skills/ship/scripts/sync-gitignored-files.sh`)
- The sync step must happen before `cleanup-worktree.sh` runs, since the force removal destroys the worktree directory entirely. The ordering is critical and the ship command must not proceed to cleanup until sync is confirmed or skipped. (`plugins/work/commands/ship.md` step 3 and 4)
- This feature only applies when a worktree exists (trip workflow or adopted drive branches). For non-worktree drive branches, there is no separate directory to sync from, so the step is naturally skipped. (`plugins/work/commands/ship.md`)
- The `validate-dev-env.sh` script already inspects `.env` files in worktrees during trip setup; the new `find-gitignored-files.sh` serves a complementary role at the opposite end of the lifecycle. Pattern and naming should stay consistent. (`plugins/work/skills/trip-protocol/scripts/validate-dev-env.sh`)
