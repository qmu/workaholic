---
created_at: 2026-04-04T02:31:55+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Move Ship Command from Core Plugin to Work Plugin

## Overview

Move the `/ship` command and its `ship` skill (including all shell scripts) from `plugins/core/` to `plugins/work/`. The ship command is tightly coupled to work workflows -- it references `work:trip-protocol` as a preloaded skill, uses work-specific context detection (drive/trip modes), and handles worktree cleanup for trip workflows. Core should remain a dependency-free base layer with generic shared utilities, not workflow-specific commands. After this move, core retains only `/report` and shared skills (branching, commit, etc.), while work owns both development commands (`/ticket`, `/drive`, `/scan`, `/trip`) and lifecycle commands (`/ship`).

## Key Files

- `plugins/core/commands/ship.md` - Ship command to move (65 lines, orchestration only)
- `plugins/core/skills/ship/SKILL.md` - Ship skill with cloud.md convention docs (67 lines)
- `plugins/core/skills/ship/scripts/pre-check.sh` - PR pre-check script (35 lines)
- `plugins/core/skills/ship/scripts/merge-pr.sh` - PR merge and main sync script (28 lines)
- `plugins/core/skills/ship/scripts/find-cloud-md.sh` - Cloud.md discovery script (16 lines)
- `plugins/core/.claude-plugin/plugin.json` - Core plugin manifest (remove ship references if any)
- `plugins/core/README.md` - Core README lists `/ship` command
- `plugins/work/README.md` - Work README references `/ship` but does not list it as a work command
- `plugins/work/.claude-plugin/plugin.json` - Work plugin manifest (no changes needed, ship becomes same-plugin)
- `CLAUDE.md` - Project structure showing core commands, commands table
- `README.md` - Top-level README with `/ship` command reference

## Related History

The ship command has been through multiple relocations as the plugin architecture evolved -- originating in drivin, moving to trippin, then to core as a unified command, and now the logical final destination is work where it belongs alongside the workflows it serves.

Past tickets that touched similar areas:

- [20260311212023-unify-ship-command-across-plugins.md](.workaholic/tickets/archive/drive-20260311-125319/20260311212023-unify-ship-command-across-plugins.md) - Created unified `/ship` in core plugin by merging `/ship-drive` and `/ship-trip` (established current placement in core)
- [20260329213021-move-ship-scripts-from-trippin-to-core.md](.workaholic/tickets/archive/drive-20260329-173608/20260329213021-move-ship-scripts-from-trippin-to-core.md) - Moved ship scripts from trippin to core (same pattern being reversed here)
- [20260404014400-create-work-plugin-merge-drivin-trippin.md](.workaholic/tickets/archive/drive-20260403-230430/20260404014400-create-work-plugin-merge-drivin-trippin.md) - Merged drivin and trippin into work plugin (ship stayed in core due to scope)
- [20260404014402-update-core-crossrefs-for-work-plugin.md](.workaholic/tickets/archive/drive-20260403-230430/20260404014402-update-core-crossrefs-for-work-plugin.md) - Updated core cross-references from drivin/trippin to work (established current `work:trip-protocol` reference in ship.md)

## Implementation Steps

1. **Move `plugins/core/skills/ship/` to `plugins/work/skills/ship/`**:
   - Move `SKILL.md`, and all scripts in `scripts/` directory (`pre-check.sh`, `merge-pr.sh`, `find-cloud-md.sh`)
   - No content changes needed in the scripts -- they are self-contained
   - Update `SKILL.md` path references: all already use `${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/` which resolves correctly in either plugin

2. **Move `plugins/core/commands/ship.md` to `plugins/work/commands/ship.md`**:
   - Update frontmatter skills list: change `ship` to just `ship` (still same-plugin, no prefix needed), change `work:trip-protocol` to `trip-protocol` (now same-plugin), keep `branching` as `core:branching` (now cross-plugin)
   - Update all `${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/` references -- these remain the same since the skill moves with the command
   - Update `${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/` references to `${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/` (now cross-plugin)

3. **Delete originals from core**:
   - Remove `plugins/core/commands/ship.md`
   - Remove `plugins/core/skills/ship/` directory entirely (SKILL.md + scripts/)

4. **Update `plugins/core/README.md`**:
   - Remove `/ship` from the Commands table
   - Update description text to reflect core only has `/report`

5. **Update `plugins/work/README.md`**:
   - Add `/ship` to the Commands table with description "Context-aware: merge PR, deploy, verify (with worktree cleanup for trips)"
   - Add `ship` to the Skills table with description "Ship workflow: PR merge, cloud.md deploy, and production verify"

6. **Update `CLAUDE.md`**:
   - Project structure: move `ship` from `core/commands/` to `work/commands/`, move `ship` from `core/skills/` to `work/skills/`
   - Commands table remains unchanged (command name and description stay the same)

7. **Update `README.md`** (top-level):
   - If the commands table references core as the source of `/ship`, update to reference work

## Patches

### `plugins/work/commands/ship.md`

> **Note**: This shows the final state of the file after moving from core. The frontmatter skill references and branching script paths change because ship is now in work instead of core.

```diff
--- a/plugins/core/commands/ship.md
+++ b/plugins/work/commands/ship.md
@@ -1,8 +1,8 @@
 ---
 name: ship
 description: Context-aware ship workflow - merge PR, deploy, and verify (with worktree cleanup for trips).
 skills:
-  - work:trip-protocol
+  - trip-protocol
   - ship
-  - branching
+  - core:branching
 ---
```

### `plugins/work/commands/ship.md` (branching script paths)

> **Note**: This patch is speculative - verify the exact line numbers before applying.

```diff
--- a/plugins/work/commands/ship.md
+++ b/plugins/work/commands/ship.md
@@ -19,7 +19,7 @@
 ### Step 0: Workspace Guard
 
 ```bash
-bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check-workspace.sh
+bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/check-workspace.sh
 ```
 
@@ -33,7 +33,7 @@
 ### Step 1: Detect Context
 
 ```bash
-bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/detect-context.sh
+bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/detect-context.sh
 ```
```

### `plugins/work/commands/ship.md` (worktree scripts)

> **Note**: This patch is speculative - verify all branching script references in the file.

```diff
--- a/plugins/work/commands/ship.md
+++ b/plugins/work/commands/ship.md
@@ -46,1 +46,1 @@
-3. **Clean up worktree** (if applicable): Check if `.worktrees/<branch>/` exists. If yes, run `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/cleanup-worktree.sh "<branch>"` and report what was cleaned up. If no worktree exists, skip this step.
+3. **Clean up worktree** (if applicable): Check if `.worktrees/<branch>/` exists. If yes, run `bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/cleanup-worktree.sh "<branch>"` and report what was cleaned up. If no worktree exists, skip this step.
@@ -55,1 +55,1 @@
-1. Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/list-worktrees.sh`
+1. Run `bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/list-worktrees.sh`
```

## Considerations

- The existing todo ticket `20260404014405-block-ship-when-todo-tickets-remain.md` references `plugins/core/commands/ship.md` and `plugins/core/skills/ship/scripts/check-todo.sh`. After this move, that ticket must be updated to target `plugins/work/commands/ship.md` and `plugins/work/skills/ship/scripts/check-todo.sh` instead. Implement this ticket first, then update the todo-guard ticket. (`plugins/core/commands/ship.md`, `.workaholic/tickets/todo/20260404014405-block-ship-when-todo-tickets-remain.md`)
- The `/report` command remains in core because it is invoked from both drive and trip contexts and has a more balanced dependency profile. However, it also references `work:trip-protocol` and `work:write-trip-report`. A future ticket could evaluate moving `/report` to work as well for consistency. (`plugins/core/commands/report.md`)
- After moving, all `${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/` paths in ship.md must become `${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/` since branching stays in core. There are approximately 5 such references across the workspace guard, context detection, worktree cleanup, and worktree listing steps. (`plugins/work/commands/ship.md`)
- The ship SKILL.md internal script references use `${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/` which remains valid after the move since the skill directory structure is preserved. No changes needed in the SKILL.md. (`plugins/work/skills/ship/SKILL.md`)
- Core's `plugin.json` has no explicit commands or skills list -- it relies on directory convention. Deleting the files is sufficient; no manifest update needed. (`plugins/core/.claude-plugin/plugin.json`)
