---
created_at: 2026-03-11T12:13:00+09:00
author: a@qmu.jp
type: refactoring
layer: [Infrastructure, Config]
effort: 0.25h
commit_hash: 4e2f001
category: Changed
---

# Extract Shared Ship Scripts from Drivin to Shared Plugin Infrastructure

## Overview

The three ship shell scripts (`pre-check.sh`, `merge-pr.sh`, `find-cloud-md.sh`) in `plugins/drivin/skills/ship/sh/` contain zero Drivin-specific logic. They are generic PR management and deployment utilities. However, `plugins/trippin/commands/ship-trip.md` references them via cross-plugin paths (`~/.claude/plugins/marketplaces/workaholic/plugins/drivin/skills/ship/sh/...`), creating an implicit coupling between the two plugins.

Create a `ship` skill within the Trippin plugin that owns its own copies of these scripts, eliminating the cross-plugin dependency. Both plugins will have their own `ship` skill with identical shell scripts.

## Key Files

- `plugins/drivin/skills/ship/sh/pre-check.sh` - Generic PR pre-check (35 lines)
- `plugins/drivin/skills/ship/sh/merge-pr.sh` - Generic PR merge (27 lines)
- `plugins/drivin/skills/ship/sh/find-cloud-md.sh` - Generic cloud.md finder (15 lines)
- `plugins/drivin/skills/ship/SKILL.md` - Ship skill definition
- `plugins/trippin/commands/ship-trip.md` - References Drivin ship scripts on lines 34, 47, 69
- `plugins/drivin/commands/ship-drive.md` - References own ship scripts (no change needed)

## Related History

- [20260311105613-add-ship-drive-command.md](.workaholic/tickets/archive/drive-20260310-220224/20260311105613-add-ship-drive-command.md) - Created the ship skill in Drivin
- [20260311105614-add-ship-trip-command.md](.workaholic/tickets/archive/drive-20260310-220224/20260311105614-add-ship-trip-command.md) - Created ship-trip with cross-plugin references, noting "This follows the existing pattern where Trippin already references Drivin skills for common operations"

## Implementation Steps

1. **Create Trippin ship skill directory** at `plugins/trippin/skills/ship/`:
   - Create `SKILL.md` mirroring Drivin's ship skill structure but with Trippin-local paths
   - Create `sh/` subdirectory for shell scripts

2. **Copy the three shell scripts** to `plugins/trippin/skills/ship/sh/`:
   - `pre-check.sh` - identical copy
   - `merge-pr.sh` - identical copy
   - `find-cloud-md.sh` - identical copy

3. **Update `plugins/trippin/commands/ship-trip.md`**:
   - Change skill preload from `trip-protocol` to `trip-protocol` AND `ship` (Trippin's own)
   - Replace all three Drivin path references with Trippin's own paths:
     - `~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/ship/sh/pre-check.sh`
     - `~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/ship/sh/merge-pr.sh`
     - `~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/ship/sh/find-cloud-md.sh`

4. **Update `plugins/trippin/.claude-plugin/plugin.json`**:
   - Add the new `ship` skill to the skills list if skills are registered there

5. **Update `plugins/trippin/README.md`**:
   - Add `ship` to the Skills section if one exists

## Patches

### `plugins/trippin/commands/ship-trip.md`

```diff
--- a/plugins/trippin/commands/ship-trip.md
+++ b/plugins/trippin/commands/ship-trip.md
@@ -3,6 +3,7 @@
 description: Merge PR, clean up worktree, deploy to production, and verify deployment.
 skills:
   - trip-protocol
+  - ship
 ---

@@ -31,7 +32,7 @@
 Run the pre-check script to verify a PR exists for the trip branch:

 ```bash
-bash ~/.claude/plugins/marketplaces/workaholic/plugins/drivin/skills/ship/sh/pre-check.sh "trip/<trip-name>"
+bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/ship/sh/pre-check.sh "trip/<trip-name>"
 ```

@@ -44,7 +45,7 @@
 Run the merge script:

 ```bash
-bash ~/.claude/plugins/marketplaces/workaholic/plugins/drivin/skills/ship/sh/merge-pr.sh "<pr-number>"
+bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/ship/sh/merge-pr.sh "<pr-number>"
 ```

@@ -66,7 +67,7 @@
 Run the cloud.md finder from the repository root:

 ```bash
-bash ~/.claude/plugins/marketplaces/workaholic/plugins/drivin/skills/ship/sh/find-cloud-md.sh
+bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/ship/sh/find-cloud-md.sh
 ```
```

## Considerations

- The scripts are identical copies, not shared references. This trades minimal duplication (77 total lines across 3 files) for complete plugin independence. Each plugin can evolve its ship scripts independently if needed. (`plugins/trippin/skills/ship/sh/`)
- The Trippin ship SKILL.md should reference Trippin paths, not Drivin paths. Copy the structure but update all path references. (`plugins/trippin/skills/ship/SKILL.md`)
- Do not modify Drivin's ship skill or ship-drive command. They remain unchanged. (`plugins/drivin/skills/ship/`)

## Final Report

### Changes Made

- Created `plugins/trippin/skills/ship/SKILL.md` with Trippin-local path references
- Created `plugins/trippin/skills/ship/sh/pre-check.sh` (identical copy from Drivin)
- Created `plugins/trippin/skills/ship/sh/merge-pr.sh` (identical copy from Drivin)
- Created `plugins/trippin/skills/ship/sh/find-cloud-md.sh` (identical copy from Drivin)
- Updated `plugins/trippin/commands/ship-trip.md` to preload `ship` skill and reference Trippin-local paths
- Updated `plugins/trippin/README.md` to include `ship` in Skills table
- Skipped `plugins/trippin/.claude-plugin/plugin.json` update (skills are auto-discovered, not registered)

### Test Plan

- Verified no remaining references to `drivin` in `ship-trip.md` via grep
- Verified shell scripts are identical copies of Drivin originals
