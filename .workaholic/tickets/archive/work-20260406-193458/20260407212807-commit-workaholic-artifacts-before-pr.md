---
created_at: 2026-04-07T21:28:07+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.1h
commit_hash: 7ffa8c0
category: Changed
---

# Generate trip artifacts in the trip worktree, not the main worktree

## Overview

When a trip session runs, Claude Code generates trip-related artifacts (plan.md, event-log.md, directions/, models/, designs/, reviews/) in `.workaholic/trips/` of the main worktree instead of the trip worktree. Since the trip worktree is where commits happen, these artifacts are left uncommitted in the main worktree and never make it into the trip branch history or PR. The fix is to ensure trip artifact generation happens inside the trip worktree so they are committed alongside the code changes.

## Key Files

- `plugins/work/skills/trip-protocol/scripts/init-trip.sh` - Uses `git rev-parse --show-toplevel` (line 22) to determine root, which always resolves to the main worktree even when the trip runs in a separate worktree. This is the root cause.
- `plugins/work/commands/trip.md` - Step 2 (line 58-60) calls `init-trip.sh` without passing `<working_dir>`, so the script has no way to know the trip worktree path
- `plugins/work/skills/trip-protocol/scripts/log-event.sh` - Takes `<trip-path>` as argument; will work correctly once trip_path points to the worktree
- `plugins/work/skills/trip-protocol/scripts/trip-commit.sh` - Commits from the working directory; already operates in the worktree correctly

## Related History

The trip worktree system was designed to isolate code changes, but artifact generation was not updated to respect the worktree boundary. The `init-trip.sh` script uses the standard git root detection pattern that predates worktree support.

- [20260406002124-prompt-gitignored-file-sync-before-worktree-erase.md](.workaholic/tickets/archive/work-20260404-101424-fix-trip-report-dir-path/20260406002124-prompt-gitignored-file-sync-before-worktree-erase.md) - Added gitignored file sync before worktree cleanup (same boundary: main worktree vs trip worktree)
- [20260403230427-unify-trip-report-to-drive-format.md](.workaholic/tickets/archive/drive-20260403-230430/20260403230427-unify-trip-report-to-drive-format.md) - Unified trip report format (same area: trip workflow)

## Implementation Steps

1. **Update `init-trip.sh` to accept an optional working directory argument**

   Add an optional third argument for the working directory. When provided, use it as root instead of `git rev-parse --show-toplevel`. This lets the trip command pass the worktree path so artifacts are created inside the worktree.

2. **Update `trip.md` Step 2 to pass `<working_dir>` to `init-trip.sh`**

   After Step 1 determines `<working_dir>` (either worktree path or repo root), pass it to init-trip.sh so trip artifacts are generated in the correct location.

## Patches

### `plugins/work/skills/trip-protocol/scripts/init-trip.sh`

> **Note**: This patch is speculative - verify line numbers before applying.

```diff
--- a/plugins/work/skills/trip-protocol/scripts/init-trip.sh
+++ b/plugins/work/skills/trip-protocol/scripts/init-trip.sh
@@ -1,6 +1,7 @@
 #!/bin/bash
 # Initialize a trip directory structure under .workaholic/trips/
-# Usage: bash init-trip.sh <trip-name> [instruction]
+# Usage: bash init-trip.sh <trip-name> [instruction] [working-dir]
+# When working-dir is provided, artifacts are created there instead of the git root.
 # The optional instruction argument is the user's original trip description.
 # Output: JSON with trip_path and plan_path
 
@@ -19,7 +20,7 @@
   exit 1
 fi
 
-root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
+root="${3:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
 
 trip_path="${root}/.workaholic/trips/${trip_name}"
```

### `plugins/work/commands/trip.md`

> **Note**: This patch is speculative - verify line numbers before applying.

```diff
--- a/plugins/work/commands/trip.md
+++ b/plugins/work/commands/trip.md
@@ -56,7 +56,7 @@
 ## Step 2: Initialize Trip Artifacts
 
 ```bash
-bash ${CLAUDE_PLUGIN_ROOT}/skills/trip-protocol/scripts/init-trip.sh "<trip-name>" "$ARGUMENT"
+bash ${CLAUDE_PLUGIN_ROOT}/skills/trip-protocol/scripts/init-trip.sh "<trip-name>" "$ARGUMENT" "<working_dir>"
 ```
```

## Considerations

- The `init-trip.sh` change is backward-compatible: when no third argument is provided, it falls back to `git rev-parse --show-toplevel`, preserving behavior for branch-only mode and any other callers. (`plugins/work/skills/trip-protocol/scripts/init-trip.sh` line 22)
- The `<trip_path>` passed to the team lead (trip.md line 77) is derived from `init-trip.sh` output. Once the script uses the worktree root, the trip_path will automatically point inside the worktree, and all downstream artifact writes (directions, models, designs, reviews, event-log, plan) will land in the correct location. (`plugins/work/commands/trip.md` lines 76-77)
- When `/ship` cleans up the worktree, the gitignored file sync step already copies files from the worktree back to the main repo. Trip artifacts in `.workaholic/trips/` are tracked (not gitignored), so they will be part of the branch and merged via the PR naturally. (`plugins/core/commands/ship.md`)
- **Separate bug**: `trip-commit.sh` line 32 uses `sed 's/./\U&/'` to capitalize the agent name, but `\U` is a GNU sed extension. On macOS (BSD sed), this produces literal `UConstructor` instead of `Constructor`. This should be fixed with a portable alternative like `$(echo "$agent" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')`. (`plugins/work/skills/trip-protocol/scripts/trip-commit.sh` line 32)

## Final Report

### Changes Made

1. **`plugins/work/skills/trip-protocol/scripts/init-trip.sh`** - Added optional third argument `working-dir`; when provided, uses it as root instead of `git rev-parse --show-toplevel`, so trip artifacts are created in the worktree
2. **`plugins/work/commands/trip.md`** - Updated Step 2 to pass `<working_dir>` to `init-trip.sh`
3. **`plugins/work/skills/trip-protocol/scripts/trip-commit.sh`** - Replaced GNU-only `sed 's/./\U&/'` with portable `awk '{print toupper(substr($0,1,1)) substr($0,2)}'` to fix `[UConstructor]` on macOS

### Test Plan

- [ ] Run `init-trip.sh` with a working-dir argument and verify artifacts are created in that directory
- [ ] Run `init-trip.sh` without working-dir and verify fallback to git root still works
- [ ] Run `trip-commit.sh` on macOS and verify commit messages show `[Constructor]` not `[UConstructor]`
- [ ] Run a full `/trip` session with worktree and verify all artifacts land in the worktree

### Release Prep

- No version bump needed (bugfix to existing scripts)
- No new dependencies
- Backward-compatible: omitting the third argument preserves existing behavior
