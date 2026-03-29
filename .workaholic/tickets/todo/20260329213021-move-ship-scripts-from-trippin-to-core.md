---
created_at: 2026-03-29T21:30:21+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Move Ship Scripts from Trippin to Core

## Overview

Move the three ship shell scripts (`pre-check.sh`, `merge-pr.sh`, `find-cloud-md.sh`) from `plugins/trippin/skills/ship/sh/` to a new `plugins/core/skills/ship/` skill. The core plugin's `ship.md` command already orchestrates shipping but currently reaches into trippin for scripts via `${CLAUDE_PLUGIN_ROOT}/../trippin/skills/ship/sh/`. After the move, all references in `core/commands/ship.md` become local (`${CLAUDE_PLUGIN_ROOT}/skills/ship/sh/`). The trippin `ship` skill is removed entirely since its SKILL.md content merges into core's new skill.

## Key Files

- `plugins/trippin/skills/ship/sh/pre-check.sh` - PR pre-check script (35 lines), moves to `plugins/core/skills/ship/sh/pre-check.sh`
- `plugins/trippin/skills/ship/sh/merge-pr.sh` - PR merge and main sync script (28 lines), moves to `plugins/core/skills/ship/sh/merge-pr.sh`
- `plugins/trippin/skills/ship/sh/find-cloud-md.sh` - Cloud.md discovery script (16 lines), moves to `plugins/core/skills/ship/sh/find-cloud-md.sh`
- `plugins/trippin/skills/ship/SKILL.md` - Ship skill definition with cloud.md convention documentation, merges into `plugins/core/skills/ship/SKILL.md`
- `plugins/core/commands/ship.md` - Unified ship command with 8 cross-plugin references to trippin ship scripts (lines 44-46, 54-55)
- `plugins/trippin/.claude-plugin/plugin.json` - May need skills list update if skills are registered
- `plugins/core/.claude-plugin/plugin.json` - May need skills list update if skills are registered

## Related History

Ship scripts have been through multiple relocations. They originated in drivin, were duplicated to trippin to eliminate cross-plugin dependency, then the unified `/ship` command was created in core but continued referencing trippin's copies.

- [20260311121300-extract-shared-ship-scripts.md](.workaholic/tickets/archive/drive-20260310-220224/20260311121300-extract-shared-ship-scripts.md) - Extracted ship scripts from drivin to trippin; established the pattern this ticket reverses by moving to core
- [20260311212023-unify-ship-command-across-plugins.md](.workaholic/tickets/archive/drive-20260311-125319/20260311212023-unify-ship-command-across-plugins.md) - Created unified /ship in core plugin; moved ship scripts to core but left them in trippin with cross-plugin references
- [20260319163918-migrate-hardcoded-plugin-paths-to-variable.md](.workaholic/tickets/archive/trip/trip-20260319-040153/20260319163918-migrate-hardcoded-plugin-paths-to-variable.md) - Migrated hardcoded paths to `${CLAUDE_PLUGIN_ROOT}` variable notation (same concern: path management)

## Implementation Steps

1. **Create `plugins/core/skills/ship/` directory structure**:
   - Create `plugins/core/skills/ship/SKILL.md` merging content from trippin's ship SKILL.md
   - Create `plugins/core/skills/ship/sh/` directory

2. **Move the three shell scripts** from `plugins/trippin/skills/ship/sh/` to `plugins/core/skills/ship/sh/`:
   - `pre-check.sh` - copy verbatim (no path changes needed, scripts are self-contained)
   - `merge-pr.sh` - copy verbatim
   - `find-cloud-md.sh` - copy verbatim

3. **Create `plugins/core/skills/ship/SKILL.md`**:
   - Merge content from `plugins/trippin/skills/ship/SKILL.md`
   - Update all script path references to use `${CLAUDE_PLUGIN_ROOT}/skills/ship/sh/`
   - Document the cloud.md convention, pre-check, merge, and find-cloud-md scripts

4. **Update `plugins/core/commands/ship.md`**:
   - Replace all `${CLAUDE_PLUGIN_ROOT}/../trippin/skills/ship/sh/` references with `${CLAUDE_PLUGIN_ROOT}/skills/ship/sh/`
   - Update the skills frontmatter: replace `trippin:ship` with `ship` (now local to core)
   - This affects lines 44-46 (drive context) and lines 54-55 (trip context)

5. **Remove `plugins/trippin/skills/ship/` directory entirely**:
   - Delete `plugins/trippin/skills/ship/SKILL.md`
   - Delete `plugins/trippin/skills/ship/sh/pre-check.sh`
   - Delete `plugins/trippin/skills/ship/sh/merge-pr.sh`
   - Delete `plugins/trippin/skills/ship/sh/find-cloud-md.sh`

6. **Update `plugins/core/commands/ship.md` frontmatter**:
   - Change `trippin:ship` to `ship` in the skills list (now a core-local skill)

## Patches

### `plugins/core/commands/ship.md`

> **Note**: This patch covers the frontmatter and drive context references. Apply similar changes to trip context and other sections.

```diff
--- a/plugins/core/commands/ship.md
+++ b/plugins/core/commands/ship.md
@@ -3,7 +3,7 @@
 description: Context-aware ship workflow - merge PR, deploy, and verify (with worktree cleanup for trips).
 skills:
   - trippin:trip-protocol
-  - trippin:ship
+  - ship
   - branching
 ---
@@ -41,9 +41,9 @@
 #### Drive Context (`context: "drive"`)

-1. **Pre-check**: Run `bash ${CLAUDE_PLUGIN_ROOT}/../trippin/skills/ship/sh/pre-check.sh "<branch>"`. If `found` is `false`: inform user "No PR found for this branch. Run `/report` first." and stop. If `merged` is `true`: skip to Deploy.
-2. **Merge PR**: Run `bash ${CLAUDE_PLUGIN_ROOT}/../trippin/skills/ship/sh/merge-pr.sh "<pr-number>"`. On failure, inform user and stop.
-3. **Deploy**: Run `bash ${CLAUDE_PLUGIN_ROOT}/../trippin/skills/ship/sh/find-cloud-md.sh`. If `found` is `false`: inform user "No cloud.md found. Deployment skipped." and skip to summary. If `found` is `true`: read the file, find `## Deploy` section, ask confirmation via AskUserQuestion, execute if confirmed.
+1. **Pre-check**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/sh/pre-check.sh "<branch>"`. If `found` is `false`: inform user "No PR found for this branch. Run `/report` first." and stop. If `merged` is `true`: skip to Deploy.
+2. **Merge PR**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/sh/merge-pr.sh "<pr-number>"`. On failure, inform user and stop.
+3. **Deploy**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/sh/find-cloud-md.sh`. If `found` is `false`: inform user "No cloud.md found. Deployment skipped." and skip to summary. If `found` is `true`: read the file, find `## Deploy` section, ask confirmation via AskUserQuestion, execute if confirmed.
@@ -51,8 +51,8 @@
 #### Trip Context (`context: "trip"`)

-1. **Pre-check**: Run `bash ${CLAUDE_PLUGIN_ROOT}/../trippin/skills/ship/sh/pre-check.sh "trip/<trip-name>"`. If `found` is `false`: inform user "No PR found for this trip. Run `/report` first." and stop. If `merged` is `true`: skip to Clean up worktree.
-2. **Merge PR**: Run `bash ${CLAUDE_PLUGIN_ROOT}/../trippin/skills/ship/sh/merge-pr.sh "<pr-number>"`. On failure, inform user and stop (worktree preserved).
+1. **Pre-check**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/sh/pre-check.sh "trip/<trip-name>"`. If `found` is `false`: inform user "No PR found for this trip. Run `/report` first." and stop. If `merged` is `true`: skip to Clean up worktree.
+2. **Merge PR**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/sh/merge-pr.sh "<pr-number>"`. On failure, inform user and stop (worktree preserved).
```

## Considerations

- The three shell scripts are entirely self-contained (no internal cross-references to other trippin scripts), so they can be moved without modification (`plugins/trippin/skills/ship/sh/`)
- The trippin ship SKILL.md references its own scripts with `${CLAUDE_PLUGIN_ROOT}/skills/ship/sh/` which already matches the target path pattern in core. The content can be merged with minimal path edits. (`plugins/trippin/skills/ship/SKILL.md`)
- After removing trippin's ship skill, verify no other trippin files reference it. Currently only `core/commands/ship.md` uses these scripts. (`plugins/trippin/`)
- This is the foundation ticket in the dependency reorganization series. Tickets 2-5 depend on the pattern established here. Cross-reference: `20260329213022-move-worktree-lifecycle-scripts-to-core.md`, `20260329213023-move-system-safety-to-core.md`
