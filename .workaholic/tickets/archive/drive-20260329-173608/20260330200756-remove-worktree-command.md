---
created_at: 2026-03-30T20:07:56+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort: 0.1h
commit_hash: 5481401
category: Removed
---

# Remove /worktree Command from Core Plugin

## Overview

Remove the standalone `/worktree` command (`plugins/core/commands/worktree.md`) from the core plugin. All worktree operations (adopt, eject, list) are already available as skill scripts in `plugins/core/skills/branching/sh/` and are invoked by other commands (`/trip`, `/ship`, `/drive`, `/ticket`) through those scripts. A dedicated `/worktree` command is unnecessary since no workflow requires users to manage worktrees directly -- the higher-level commands handle worktree lifecycle automatically. After deletion, update `CLAUDE.md` and `plugins/core/README.md` to remove references to the command.

## Key Files

- `plugins/core/commands/worktree.md` - The command file to delete (66 lines, orchestrates adopt/eject/list via branching skill scripts)
- `CLAUDE.md` - Project Structure section lists `worktree` under `core/commands/` (line 29); no entry in Commands table (already absent)
- `plugins/core/README.md` - Does not list `/worktree` in its Commands table (only lists `/report` and `/ship`)
- `plugins/core/skills/branching/SKILL.md` - Documents worktree management scripts; remains unchanged (this is the retained functionality)
- `plugins/core/skills/branching/sh/adopt-worktree.sh` - Adopt script; remains unchanged
- `plugins/core/skills/branching/sh/eject-worktree.sh` - Eject script; remains unchanged
- `plugins/core/skills/branching/sh/list-all-worktrees.sh` - List script; remains unchanged

## Related History

The worktree management functionality was built incrementally: first as trip-specific scripts in trippin, then unified into core's branching skill. The `/worktree` command was added as a user-facing convenience but the underlying operations are now fully covered by automated workflows in `/trip`, `/ship`, `/drive`, and `/ticket`.

- [20260329213022-move-worktree-lifecycle-scripts-to-core.md](.workaholic/tickets/archive/drive-20260329-173608/20260329213022-move-worktree-lifecycle-scripts-to-core.md) - Moved ensure/cleanup/list-trip worktree scripts to core branching skill, completing the worktree lifecycle in core (same layer: Config)
- [20260329213024-make-worktree-optional-for-trip.md](.workaholic/tickets/archive/drive-20260329-173608/20260329213024-make-worktree-optional-for-trip.md) - Made worktrees optional for /trip, reducing the need for standalone worktree management (same area: worktree operations)
- [20260316143754-add-worktree-detection-guard.md](.workaholic/tickets/archive/drive-20260312-102414/20260316143754-add-worktree-detection-guard.md) - Added worktree detection guard to /drive and /ticket commands, establishing that commands auto-handle worktree awareness (same concern: worktree UX)
- [20260311193203-worktree-aware-report-ship-trip.md](.workaholic/tickets/archive/drive-20260311-125319/20260311193203-worktree-aware-report-ship-trip.md) - Made /report and /ship worktree-aware via detect-context.sh routing (same concern: commands managing worktrees automatically)

## Implementation Steps

1. **Delete `plugins/core/commands/worktree.md`**: Remove the file entirely. The worktree management scripts in `plugins/core/skills/branching/sh/` remain untouched.

2. **Update `CLAUDE.md` Project Structure section**: Remove `worktree` from the `core/commands/` line so it reads `commands/            # report, ship`.

3. **Verify no other files reference the `/worktree` command**: Confirm that no command, skill, or agent markdown file references `worktree.md` as a command invocation or cross-reference. The only self-reference is within `worktree.md` itself.

## Patches

### `CLAUDE.md`

```diff
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -26,7 +26,7 @@
   core/                  # Core shared plugin (no dependencies)
     .claude-plugin/      # Plugin configuration
-    commands/            # report, ship, worktree
+    commands/            # report, ship
     skills/              # branching, ship, system-safety
```

## Considerations

- The `/worktree` command is the only command that uses `AskUserQuestion` for interactive worktree selection during eject. Other commands that manage worktrees do so automatically without user prompts. Removing this command eliminates the last interactive worktree management path. Users who need manual worktree operations can still use `git worktree` directly. (`plugins/core/commands/worktree.md` lines 43-48)
- The `plugins/core/README.md` Commands table already only lists `/report` and `/ship` -- it does not mention `/worktree`, so no update is needed there. (`plugins/core/README.md`)
- The branching skill's SKILL.md documents all worktree management scripts (Adopt, Eject, List All, List Trip, Ensure, Create Trip Branch, Cleanup). This documentation remains the canonical reference for worktree operations after the command is removed. (`plugins/core/skills/branching/SKILL.md`)
- If a user explicitly asks to "adopt a worktree" or "eject a worktree" after removal, Claude Code will no longer have a dedicated command entry point. The user would need to use `/trip` or `/ship` for automated worktree lifecycle, or invoke git worktree commands manually. This is intentional -- the design philosophy is that worktree operations are implementation details of higher-level workflows, not user-facing operations.

## Final Report

Deleted `plugins/core/commands/worktree.md` and removed the `worktree` entry from CLAUDE.md project structure. No other files referenced the command. Worktree management scripts remain in core branching skill, invoked automatically by /trip, /ship, /drive, and /ticket workflows.
