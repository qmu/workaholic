---
created_at: 2026-04-06T13:36:47+09:00
author: a@qmu.jp
type: refactoring
layer: [Config, Infrastructure]
effort: 0.5h
commit_hash: be42a3c
category: Changed
---

# Move Ship and Scan Commands from Work Plugin to Core Plugin

## Overview

Move the `/ship` command, `/scan` command, and the `ship` skill (including all shell scripts) from `plugins/work/` to `plugins/core/`. The ship command was recently moved from core to work (ticket `20260404023155`), but this reverses that decision. The rationale is that ship and scan are cross-workflow lifecycle commands -- they are not specific to drive or trip, but rather shared operations that apply to any branch regardless of how it was created. Core already owns `/report` which serves the same cross-workflow purpose. After this move, core becomes the lifecycle command hub (`/report`, `/ship`, `/scan`) while work retains workflow-specific commands (`/ticket`, `/drive`, `/trip`).

## Key Files

### Files to MOVE from work to core

- `plugins/work/commands/ship.md` - Ship command (80 lines, orchestration)
- `plugins/work/commands/scan.md` - Scan command (106 lines, orchestration)
- `plugins/work/skills/ship/SKILL.md` - Ship skill documentation (100 lines)
- `plugins/work/skills/ship/scripts/check-todo.sh` - Todo ticket guard script
- `plugins/work/skills/ship/scripts/pre-check.sh` - PR pre-check script
- `plugins/work/skills/ship/scripts/merge-pr.sh` - PR merge and main sync script
- `plugins/work/skills/ship/scripts/find-cloud-md.sh` - Cloud.md discovery script
- `plugins/work/skills/ship/scripts/find-gitignored-files.sh` - Gitignored file discovery script
- `plugins/work/skills/ship/scripts/sync-gitignored-files.sh` - Gitignored file sync script

### Files to UPDATE (cross-references)

- `plugins/core/.claude-plugin/plugin.json` - No structural change needed (uses directory convention)
- `plugins/work/.claude-plugin/plugin.json` - No structural change needed (uses directory convention)
- `plugins/work/commands/trip.md` - Mentions `/ship` in transition guidance (line 99)
- `plugins/work/README.md` - Lists `/ship` and `/scan` in commands table, `ship` in skills table
- `plugins/work/rules/general.md` - Mentions `/ship` in commit rules (line 8)
- `plugins/core/README.md` - Currently only lists `/report`; add `/ship` and `/scan`
- `CLAUDE.md` - Project structure showing commands/skills in work plugin
- `README.md` - Top-level README already lists `/ship` under Core and `/scan` under Work; update `/scan` to Core
- `.workaholic/guides/commands.md` - Scan command details reference trippin plugin naming
- `.workaholic/guides/workflow.md` - Workflow steps mention `/scan`

## Related History

The ship command has been relocated multiple times as the plugin architecture evolved -- from drivin/trippin to core, then from core to work, and now proposed back to core. The scan command has been in work (and previously drivin) since its creation.

Past tickets that touched similar areas:

- [20260404023155-move-ship-command-from-core-to-work.md](.workaholic/tickets/archive/drive-20260403-230430/20260404023155-move-ship-command-from-core-to-work.md) - Moved /ship from core to work plugin (this ticket reverses that move)
- [20260311212023-unify-ship-command-across-plugins.md](.workaholic/tickets/archive/drive-20260311-125319/20260311212023-unify-ship-command-across-plugins.md) - Created unified /ship in core by merging /ship-drive and /ship-trip
- [20260329213021-move-ship-scripts-from-trippin-to-core.md](.workaholic/tickets/archive/drive-20260329-173608/20260329213021-move-ship-scripts-from-trippin-to-core.md) - Moved ship scripts from trippin to core
- [20260404014400-create-work-plugin-merge-drivin-trippin.md](.workaholic/tickets/archive/drive-20260403-230430/20260404014400-create-work-plugin-merge-drivin-trippin.md) - Merged drivin and trippin into work plugin
- [20260404014402-update-core-crossrefs-for-work-plugin.md](.workaholic/tickets/archive/drive-20260403-230430/20260404014402-update-core-crossrefs-for-work-plugin.md) - Updated core cross-references from drivin/trippin to work

## Implementation Steps

1. **Move `plugins/work/skills/ship/` to `plugins/core/skills/ship/`**:
   - Move entire directory: `SKILL.md` and all scripts in `scripts/`
   - No content changes needed in scripts -- they are self-contained and use `${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/` which resolves correctly in either plugin

2. **Move `plugins/work/commands/ship.md` to `plugins/core/commands/ship.md`**:
   - Update frontmatter skills: change `trip-protocol` to `work:trip-protocol` (now cross-plugin), change `core:branching` to `branching` (now same-plugin), keep `ship` as `ship` (still same-plugin)
   - Update `${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/` to `${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/` (branching is now same-plugin)
   - Update `${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/` -- these remain the same since the skill moves with the command
   - Keep `${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/cleanup-worktree.sh` references as `${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/cleanup-worktree.sh`
   - Keep `${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/list-worktrees.sh` as `${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/list-worktrees.sh`

3. **Move `plugins/work/commands/scan.md` to `plugins/core/commands/scan.md`**:
   - Update frontmatter skills: change `core:gather-git-context` to `gather-git-context` (now same-plugin), keep `standards:select-scan-agents`, `standards:write-spec`, and `standards:validate-writer-output` as-is (remain cross-plugin)
   - Remove the check-deps pre-check step (scan is now IN core, so checking for core is unnecessary)
   - Update `${CLAUDE_PLUGIN_ROOT}/../standards/skills/` paths -- these remain the same pattern since core also has no dependency on standards (uses cross-plugin convention)

4. **Delete originals from work**:
   - Remove `plugins/work/commands/ship.md`
   - Remove `plugins/work/commands/scan.md`
   - Remove `plugins/work/skills/ship/` directory entirely

5. **Update `plugins/core/README.md`**:
   - Add `/ship` and `/scan` to the Commands table
   - Add `ship` to the Skills table

6. **Update `plugins/work/README.md`**:
   - Remove `/ship` and `/scan` from the Commands table
   - Remove `ship` from the Skills table
   - Update workflow descriptions that reference these commands (they still work, just live in core now)

7. **Update `CLAUDE.md`**:
   - Project structure: move `ship` and `scan` from `work/commands/` comment to `core/commands/` comment
   - Move `ship` from `work/skills/` comment to `core/skills/` comment
   - Remove `check-deps` from `work/skills/` comment if it was only used by scan (verify first -- check-deps is also used by trip, drive, ticket)

8. **Update `README.md`** (top-level):
   - Move `/scan` from Work commands table to Core commands table (ship is already listed under Core)

9. **Update `plugins/work/rules/general.md`**:
   - The `/ship` mention in the commit rule context is still valid (the command name hasn't changed, only its plugin location)

10. **Verify all cross-plugin references resolve correctly**:
    - `plugins/core/commands/report.md` already uses `work:trip-protocol` -- confirm ship.md follows the same pattern
    - All `${CLAUDE_PLUGIN_ROOT}/../standards/skills/` paths in scan.md remain valid from core since both core and standards are sibling directories under `plugins/`

## Patches

### `plugins/core/commands/ship.md`

> **Note**: This shows the final state of the frontmatter and branching script paths after moving from work to core. The file content is copied from `plugins/work/commands/ship.md` with these reference updates.

```diff
--- a/plugins/work/commands/ship.md
+++ b/plugins/core/commands/ship.md
@@ -1,8 +1,8 @@
 ---
 name: ship
 description: Context-aware ship workflow - merge PR, deploy, and verify (with worktree cleanup for trips).
 skills:
-  - trip-protocol
+  - work:trip-protocol
   - ship
-  - core:branching
+  - branching
 ---
```

### `plugins/core/commands/ship.md` (branching script paths)

> **Note**: All `core/skills/branching/` cross-plugin references become same-plugin references.

```diff
--- a/plugins/work/commands/ship.md
+++ b/plugins/core/commands/ship.md
@@ -21,7 +21,7 @@
 ### Step 0: Workspace Guard
 
 ```bash
-bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/check-workspace.sh
+bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check-workspace.sh
 ```
@@ -49,7 +49,7 @@
 ### Step 1: Detect Context
 
 ```bash
-bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/detect-context.sh
+bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/detect-context.sh
 ```
```

### `plugins/core/commands/ship.md` (worktree script paths in prose)

> **Note**: This patch is speculative -- verify exact line content before applying.

```diff
--- a/plugins/work/commands/ship.md
+++ b/plugins/core/commands/ship.md
@@ -61,1 +61,1 @@
-4. **Clean up worktree** (if applicable): Check if `.worktrees/<branch>/` exists. If yes, run `bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/cleanup-worktree.sh "<branch>"` and report what was cleaned up. If no worktree exists, skip this step.
+4. **Clean up worktree** (if applicable): Check if `.worktrees/<branch>/` exists. If yes, run `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/cleanup-worktree.sh "<branch>"` and report what was cleaned up. If no worktree exists, skip this step.
@@ -70,1 +70,1 @@
-1. Run `bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/list-worktrees.sh`
+1. Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/list-worktrees.sh`
```

### `plugins/core/commands/scan.md`

> **Note**: Frontmatter and check-deps removal after moving from work to core.

```diff
--- a/plugins/work/commands/scan.md
+++ b/plugins/core/commands/scan.md
@@ -3,7 +3,7 @@
 description: Full documentation scan - update all .workaholic/ documentation (changelog, specs, terms, policies).
 skills:
-  - core:gather-git-context
+  - gather-git-context
   - standards:select-scan-agents
   - standards:write-spec
   - standards:validate-writer-output
@@ -17,12 +17,6 @@
 ## Instructions
 
-### Pre-check: Dependencies
-
-```bash
-bash ${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/check.sh
-```
-
-If `ok` is `false`, display the `message` to the user and stop.
-
 ### Phase 1: Gather Context
```

### `plugins/core/README.md`

```diff
--- a/plugins/core/README.md
+++ b/plugins/core/README.md
@@ -7,11 +7,14 @@
 | Command | Description |
 | ------- | ----------- |
 | `/report` | Context-aware report generation and PR creation |
+| `/ship` | Context-aware: merge PR, deploy, and verify |
+| `/scan` | Full documentation scan (all agents) |
 
 ## Skills
 
 | Skill | Description |
 | ----- | ----------- |
 | branching | Context detection and branch pattern matching for unified commands |
+| ship | Ship workflow: PR merge, cloud.md deploy, and production verify |
 
 ## Installation
```

### `README.md`

> **Note**: Move `/scan` from Work table to Core table.

```diff
--- a/README.md
+++ b/README.md
@@ -24,6 +24,7 @@
 | Command    | What it does                                          |
 | ---------- | ----------------------------------------------------- |
 | `/report`  | Context-aware: generate story or journey report and create PR |
 | `/ship`    | Context-aware: merge PR, deploy, and verify           |
+| `/scan`    | Full documentation scan                               |
 
@@ -38,7 +39,6 @@
 | `/ticket`  | Plan a change with context and steps                  |
 | `/drive`   | Implement queued tickets one by one                   |
-| `/scan`    | Full documentation scan                               |
 | `/trip`    | Launch Agent Teams session for collaborative design   |
```

## Considerations

- **Reversal of recent move**: Ticket `20260404023155` moved ship from core to work just two days ago. This ticket reverses that decision. The rationale should be clearly documented: core as lifecycle command hub (report/ship/scan) vs work as workflow-specific command hub (ticket/drive/trip). (`plugins/work/commands/ship.md`, `.workaholic/tickets/archive/drive-20260403-230430/20260404023155-move-ship-command-from-core-to-work.md`)
- **Cross-plugin skill dependency for trip-protocol**: After moving ship to core, `ship.md` must reference `work:trip-protocol` as a cross-plugin skill. This works because Claude Code resolves cross-plugin references at load time, but it means the ship command in core has a soft dependency on the work plugin. If work is not installed, ship still functions but without trip-specific features. This mirrors how `report.md` in core already references `work:trip-protocol` and `work:write-trip-report`. (`plugins/core/commands/report.md` lines 5-6, `plugins/core/commands/ship.md`)
- **Scan depends on standards agents**: The scan command invokes 15 standards agents. Core has no declared dependency on standards. Since these are subagent invocations (not skill references), they resolve at runtime through the plugin system rather than at load time. This is the same pattern -- soft dependency without declared dependency. Verify that standards agents can be invoked from a core command. (`plugins/core/commands/scan.md`, `plugins/standards/.claude-plugin/plugin.json`)
- **check-deps skill stays in work**: The `check-deps` skill checks for core plugin availability. It is used by trip.md, drive.md, ticket.md, and currently scan.md in work. After moving scan to core, the check-deps reference is removed from scan (scan IS in core now). The check-deps skill itself stays in work since the remaining consumers (trip, drive, ticket) are all work commands. (`plugins/work/skills/check-deps/scripts/check.sh`)
- **No circular dependency**: Core does not declare work as a dependency. The cross-plugin skill reference `work:trip-protocol` is a soft reference that gracefully degrades if work is not installed. The dependency graph remains `work -> core` (one-way). (`plugins/core/.claude-plugin/plugin.json`, `plugins/work/.claude-plugin/plugin.json`)
- **Guide documents use outdated plugin names**: `.workaholic/guides/commands.md` still references "drivin" and "trippin" plugin names. This ticket does not address that -- it only updates command locations. A separate housekeeping ticket could update guide terminology. (`.workaholic/guides/commands.md` lines 2, 71, 87)

## Final Report

### Changes

- Moved `plugins/work/commands/ship.md` to `plugins/core/commands/ship.md` with frontmatter updates: `trip-protocol` → `work:trip-protocol`, `core:branching` → `branching`, all `/../core/skills/branching/` paths → `/skills/branching/`
- Moved `plugins/work/commands/scan.md` to `plugins/core/commands/scan.md` with frontmatter updates: `core:gather-git-context` → `gather-git-context`, removed check-deps pre-check guard
- Moved `plugins/work/skills/ship/` directory (SKILL.md + 6 scripts) to `plugins/core/skills/ship/` with no content changes
- Updated `plugins/core/README.md`: added `/ship`, `/scan` to commands table and `ship` to skills table
- Updated `plugins/work/README.md`: removed `/ship`, `/scan` from commands table and `ship` from skills table
- Updated `CLAUDE.md`: moved ship/scan to core in project structure, added standards soft reference note
- Updated `README.md`: moved `/scan` from Work table to Core table

### Test Plan

- [ ] Verify `/ship` command loads correctly from core plugin
- [ ] Verify `/scan` command loads correctly from core plugin
- [ ] Verify `work:trip-protocol` cross-plugin skill resolves in ship.md
- [ ] Verify `standards:select-scan-agents` cross-plugin skill resolves in scan.md
- [ ] Verify `/report` still works (already in core, no changes)

### Release Prep

No version bump needed — this is a structural refactor within the same marketplace.
