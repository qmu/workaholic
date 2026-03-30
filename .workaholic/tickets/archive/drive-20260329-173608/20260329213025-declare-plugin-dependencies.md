---
created_at: 2026-03-29T21:30:25+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort: 0.25h
commit_hash: 9f71674
category: Changed
---

# Declare Plugin Dependencies and Clean Up Cross-Plugin References

## Overview

Add explicit dependency declarations to `plugin.json` files: core has no dependencies (it is the base), drivin depends on core, trippin depends on core and drivin. After tickets 1-4 have moved shared functionality to core, audit all remaining `${CLAUDE_PLUGIN_ROOT}/../` references to ensure each cross-plugin reference targets only declared dependencies. Update `CLAUDE.md` to document the dependency relationships and update the Project Structure section.

## Key Files

- `plugins/core/.claude-plugin/plugin.json` - Add `dependencies` field (empty array -- core is the base)
- `plugins/drivin/.claude-plugin/plugin.json` - Add `dependencies: ["core"]`
- `plugins/trippin/.claude-plugin/plugin.json` - Add `dependencies: ["core", "drivin"]`
- `CLAUDE.md` - Update Architecture Policy section with dependency diagram; update Project Structure to reflect new skill locations
- All plugin files with remaining `${CLAUDE_PLUGIN_ROOT}/../` references - audit and verify against declared dependencies

## Related History

The plugin architecture evolved from a single plugin (drivin) to a multi-plugin marketplace without formal dependency declarations. Cross-plugin references were added ad hoc as functionality was shared.

- [20260311212023-unify-ship-command-across-plugins.md](.workaholic/tickets/archive/drive-20260311-125319/20260311212023-unify-ship-command-across-plugins.md) - Created core plugin; established cross-plugin references from core to trippin (now being reversed by tickets 1-2)
- [20260319163918-migrate-hardcoded-plugin-paths-to-variable.md](.workaholic/tickets/archive/trip/trip-20260319-040153/20260319163918-migrate-hardcoded-plugin-paths-to-variable.md) - Identified cross-plugin sibling references as a maintainability concern (same concern: dependency management)
- [20260311125425-add-system-config-safety-harness.md](.workaholic/tickets/archive/drive-20260311-125319/20260311125425-add-system-config-safety-harness.md) - Created system-safety in drivin with trippin referencing it cross-plugin (same concern: undeclared dependency)
- [20260127101756-add-dependency-graph.md](.workaholic/tickets/archive/feat-20260126-214833/20260127101756-add-dependency-graph.md) - Added dependency graph to document command/skill relationships (same layer: dependency documentation)

## Implementation Steps

1. **Add `dependencies` field to `plugins/core/.claude-plugin/plugin.json`**:
   ```json
   {
     "name": "core",
     "description": "Shared commands and skills for cross-workflow operations",
     "version": "1.0.42",
     "dependencies": [],
     "author": { "name": "tamurayoshiya", "email": "a@qmu.jp" }
   }
   ```

2. **Add `dependencies` field to `plugins/drivin/.claude-plugin/plugin.json`**:
   ```json
   {
     "name": "drivin",
     "description": "Core development workflow: branch, commit, pull-request, ticket-driven development",
     "version": "1.0.42",
     "dependencies": ["core"],
     "author": { "name": "tamurayoshiya", "email": "a@qmu.jp" }
   }
   ```

3. **Add `dependencies` field to `plugins/trippin/.claude-plugin/plugin.json`**:
   ```json
   {
     "name": "trippin",
     "description": "AI-oriented exploration and creative development workflow",
     "version": "1.0.42",
     "dependencies": ["core", "drivin"],
     "author": { "name": "tamurayoshiya", "email": "a@qmu.jp" }
   }
   ```

4. **Audit all remaining `${CLAUDE_PLUGIN_ROOT}/../` references**:
   - Run `grep -rn 'CLAUDE_PLUGIN_ROOT}/../' plugins/` to find all cross-plugin references
   - For each reference, verify the target plugin is in the source plugin's `dependencies` list
   - Expected valid references after tickets 1-4:
     - `core -> drivin`: `report.md` references `drivin:story-writer` (subagent) and `drivin:branching/sh/check-version-bump.sh`
     - `core -> trippin`: `report.md` references `trippin:write-trip-report/sh/gather-artifacts.sh` and `ship.md` references `trippin:trip-protocol` (skill preload)
     - `drivin -> core`: `ticket.md` and `drive.md` reference `core:branching/sh/check-worktrees.sh` and `list-all-worktrees.sh`
     - `drivin -> standards`: `scan.md` references `standards:select-scan-agents` and `validate-writer-output`
     - `trippin -> core`: `trip.md` references `core:branching/sh/ensure-worktree.sh` and `list-trip-worktrees.sh`
     - `trippin -> drivin`: None expected after system-safety moves to core
   - Flag any references that violate the dependency graph

5. **Address flagged violations** (if any):
   - If core references trippin: this is a reverse dependency. Either move the referenced functionality to core, or accept that core has an optional dependency on trippin for trip-specific features
   - The `core/commands/report.md` and `core/commands/ship.md` preloading `trippin:trip-protocol` is a known pattern -- document it as a soft/optional dependency for trip context routing

6. **Update `CLAUDE.md`**:
   - Add a dependency diagram to the Architecture Policy section:
     ```
     core (base - no dependencies)
       ^          ^
       |          |
     drivin    trippin
       ^          |
       |__________|
     ```
   - Update Project Structure section to reflect new skill locations after tickets 1-3:
     - `core/skills/` now includes `ship/`, `system-safety/`, and expanded `branching/` with worktree lifecycle scripts
     - `drivin/skills/` no longer includes `system-safety/`
     - `trippin/skills/` no longer includes `ship/`; `trip-protocol/sh/` has fewer scripts
   - Document the dependency convention: each plugin's `plugin.json` declares its dependencies; cross-plugin `${CLAUDE_PLUGIN_ROOT}/../<name>/` references must only target declared dependencies

7. **Update `plugins/standards/.claude-plugin/plugin.json`**:
   - Add `dependencies: []` for consistency (standards has no dependencies -- it is referenced by drivin's scan command but does not reference other plugins)

## Patches

### `plugins/core/.claude-plugin/plugin.json`

```diff
--- a/plugins/core/.claude-plugin/plugin.json
+++ b/plugins/core/.claude-plugin/plugin.json
@@ -2,6 +2,7 @@
   "name": "core",
   "description": "Shared commands and skills for cross-workflow operations",
   "version": "1.0.42",
+  "dependencies": [],
   "author": {
     "name": "tamurayoshiya",
     "email": "a@qmu.jp"
```

### `plugins/drivin/.claude-plugin/plugin.json`

```diff
--- a/plugins/drivin/.claude-plugin/plugin.json
+++ b/plugins/drivin/.claude-plugin/plugin.json
@@ -2,6 +2,7 @@
   "name": "drivin",
   "description": "Core development workflow: branch, commit, pull-request, ticket-driven development",
   "version": "1.0.42",
+  "dependencies": ["core"],
   "author": {
     "name": "tamurayoshiya",
     "email": "a@qmu.jp"
```

### `plugins/trippin/.claude-plugin/plugin.json`

```diff
--- a/plugins/trippin/.claude-plugin/plugin.json
+++ b/plugins/trippin/.claude-plugin/plugin.json
@@ -2,6 +2,7 @@
   "name": "trippin",
   "description": "AI-oriented exploration and creative development workflow",
   "version": "1.0.42",
+  "dependencies": ["core", "drivin"],
   "author": {
     "name": "tamurayoshiya",
     "email": "a@qmu.jp"
```

## Considerations

- Core currently references trippin for trip-specific functionality (`report.md` references `trippin:write-trip-report`, `ship.md` preloads `trippin:trip-protocol`). This creates a circular concern: trippin depends on core, but core also references trippin. This is acceptable as a soft/optional dependency pattern -- core's trip-context routing only activates when trippin is installed. Document this as an expected pattern. (`plugins/core/commands/report.md`, `plugins/core/commands/ship.md`)
- Drivin references standards plugin for the `/scan` command (`drivin:scan.md` references `standards:select-scan-agents` and `standards:validate-writer-output`). This is a declared-but-not-formal dependency. Consider whether drivin should declare `dependencies: ["core", "standards"]` or whether the scan command's dependency on standards is optional. (`plugins/drivin/commands/scan.md`)
- The `dependencies` field in `plugin.json` is a documentation convention at this point, not enforced by Claude Code. It serves as a contract for developers to follow when adding cross-plugin references. (`plugins/*/.claude-plugin/plugin.json`)
- This ticket must be implemented last in the series (after tickets 1-4) since it audits the final state of all cross-plugin references. Cross-reference: `20260329213021-move-ship-scripts-from-trippin-to-core.md`, `20260329213022-move-worktree-lifecycle-scripts-to-core.md`, `20260329213023-move-system-safety-to-core.md`, `20260329213024-make-worktree-optional-for-trip.md`
