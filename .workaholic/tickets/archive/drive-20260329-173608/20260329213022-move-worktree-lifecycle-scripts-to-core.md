---
created_at: 2026-03-29T21:30:22+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 0.25h
commit_hash: a72cf4e
category: Changed
---

# Move Worktree Lifecycle Scripts to Core Branching Skill

## Overview

Move trip-specific worktree lifecycle scripts (`ensure-worktree.sh`, `cleanup-worktree.sh`, `list-trip-worktrees.sh`) from `plugins/trippin/skills/trip-protocol/sh/` to `plugins/core/skills/branching/sh/`. Core already owns several worktree management scripts (`check-worktrees.sh`, `list-all-worktrees.sh`, `adopt-worktree.sh`, `eject-worktree.sh`). Adding these three completes the worktree lifecycle in core: create (ensure), list with PR status (list-trip), and remove (cleanup). All cross-plugin references in core and trippin commands are then updated to use core-local paths.

## Key Files

- `plugins/trippin/skills/trip-protocol/sh/ensure-worktree.sh` - Create isolated worktree (39 lines), moves to `plugins/core/skills/branching/sh/ensure-worktree.sh`
- `plugins/trippin/skills/trip-protocol/sh/cleanup-worktree.sh` - Remove worktree and branch after PR merge (40 lines), moves to `plugins/core/skills/branching/sh/cleanup-worktree.sh`
- `plugins/trippin/skills/trip-protocol/sh/list-trip-worktrees.sh` - List trip worktrees with PR status (47 lines), moves to `plugins/core/skills/branching/sh/list-trip-worktrees.sh`
- `plugins/core/skills/branching/SKILL.md` - Core branching skill documentation; add sections for the three new scripts
- `plugins/core/commands/ship.md` - Lines 56, 66, 72: references `${CLAUDE_PLUGIN_ROOT}/../trippin/skills/trip-protocol/sh/cleanup-worktree.sh` and `list-trip-worktrees.sh`
- `plugins/core/commands/report.md` - Line 78: references `${CLAUDE_PLUGIN_ROOT}/../trippin/skills/trip-protocol/sh/list-trip-worktrees.sh`
- `plugins/trippin/commands/trip.md` - Lines 18, 34: references `${CLAUDE_PLUGIN_ROOT}/skills/trip-protocol/sh/list-trip-worktrees.sh` and `ensure-worktree.sh`
- `plugins/trippin/skills/trip-protocol/SKILL.md` - Script table references all three scripts; update to core paths
- `plugins/core/skills/branching/sh/detect-context.sh` - Lines 43-44: uses relative path `../../trip-protocol/sh/list-trip-worktrees.sh`; update to local `./list-trip-worktrees.sh`

## Related History

Worktree management has been split between core (detection, guard, adopt/eject) and trippin (create, cleanup, list). This split emerged organically as the trip workflow was built first, then core was extracted later for shared commands.

- [20260316143858-trip-drive-cross-command-compatibility.md](.workaholic/tickets/archive/drive-20260312-102414/20260316143858-trip-drive-cross-command-compatibility.md) - Added trip_drive hybrid context to detect-context.sh; established the pattern of core branching skill referencing trippin scripts
- [20260311212023-unify-ship-command-across-plugins.md](.workaholic/tickets/archive/drive-20260311-125319/20260311212023-unify-ship-command-across-plugins.md) - Created unified /ship in core with cross-plugin references to trippin worktree scripts
- [20260311212022-unify-report-command-across-plugins.md](.workaholic/tickets/archive/drive-20260311-125319/20260311212022-unify-report-command-across-plugins.md) - Created unified /report in core with cross-plugin reference to list-trip-worktrees.sh
- [20260316143754-add-worktree-detection-guard.md](.workaholic/tickets/archive/drive-20260312-102414/20260316143754-add-worktree-detection-guard.md) - Added worktree detection guard to drive and ticket commands (same layer: worktree awareness in core)

## Implementation Steps

1. **Move the three scripts** from `plugins/trippin/skills/trip-protocol/sh/` to `plugins/core/skills/branching/sh/`:
   - `ensure-worktree.sh` - copy verbatim (self-contained, no internal references)
   - `cleanup-worktree.sh` - copy verbatim (self-contained)
   - `list-trip-worktrees.sh` - copy verbatim (self-contained)

2. **Update `plugins/core/skills/branching/SKILL.md`** to document the three new scripts:
   - Add "Ensure Worktree" section documenting `ensure-worktree.sh <trip-name>` usage and output format
   - Add "Cleanup Worktree" section documenting `cleanup-worktree.sh <trip-name>` usage and output format
   - Add "List Trip Worktrees" section documenting `list-trip-worktrees.sh` usage and output format (including PR status fields)

3. **Update `plugins/core/commands/ship.md`**:
   - Line 56: Replace `${CLAUDE_PLUGIN_ROOT}/../trippin/skills/trip-protocol/sh/cleanup-worktree.sh` with `${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/cleanup-worktree.sh`
   - Line 66: Same replacement for trip-drive hybrid context
   - Line 72: Replace `${CLAUDE_PLUGIN_ROOT}/../trippin/skills/trip-protocol/sh/list-trip-worktrees.sh` with `${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/list-trip-worktrees.sh`

4. **Update `plugins/core/commands/report.md`**:
   - Line 78: Replace `${CLAUDE_PLUGIN_ROOT}/../trippin/skills/trip-protocol/sh/list-trip-worktrees.sh` with `${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/list-trip-worktrees.sh`

5. **Update `plugins/core/skills/branching/sh/detect-context.sh`**:
   - Lines 43-44: Replace the relative path `${script_dir}/../../trip-protocol/sh/list-trip-worktrees.sh` with `${script_dir}/list-trip-worktrees.sh` (now in the same directory)

6. **Update `plugins/trippin/commands/trip.md`**:
   - Line 18: Replace `${CLAUDE_PLUGIN_ROOT}/skills/trip-protocol/sh/list-trip-worktrees.sh` with `${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/sh/list-trip-worktrees.sh`
   - Line 34: Replace `${CLAUDE_PLUGIN_ROOT}/skills/trip-protocol/sh/ensure-worktree.sh` with `${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/sh/ensure-worktree.sh`

7. **Update `plugins/trippin/skills/trip-protocol/SKILL.md`**:
   - Update the Shell Scripts table: change `ensure-worktree.sh`, `cleanup-worktree.sh`, and `list-trip-worktrees.sh` entries to note they are now in core branching skill
   - Update "Script base path" note to indicate some scripts have moved to core

8. **Remove the three scripts** from `plugins/trippin/skills/trip-protocol/sh/` (the originals, after migration is verified)

## Patches

### `plugins/core/skills/branching/sh/detect-context.sh`

```diff
--- a/plugins/core/skills/branching/sh/detect-context.sh
+++ b/plugins/core/skills/branching/sh/detect-context.sh
@@ -40,7 +40,7 @@

 # Other branch: check for trip worktrees
 script_dir="$(cd "$(dirname "$0")" && pwd)"
-list_script="${script_dir}/../../trip-protocol/sh/list-trip-worktrees.sh"
+list_script="${script_dir}/list-trip-worktrees.sh"

 if [ -f "$list_script" ]; then
   worktree_output=$(bash "$list_script" 2>/dev/null || echo '{"count": 0}')
```

## Considerations

- The `detect-context.sh` script currently uses a fragile relative path (`../../trip-protocol/sh/list-trip-worktrees.sh`) that assumes trippin's directory structure relative to core's branching skill. After moving the script to the same directory, this becomes a simple same-directory reference. (`plugins/core/skills/branching/sh/detect-context.sh` lines 42-44)
- The trippin `/trip` command references `ensure-worktree.sh` and `list-trip-worktrees.sh` directly. After the move, these become cross-plugin references to core (`${CLAUDE_PLUGIN_ROOT}/../core/`). This is acceptable because trippin will declare a dependency on core in ticket 5. (`plugins/trippin/commands/trip.md`)
- The `cleanup-worktree.sh` and `ensure-worktree.sh` scripts hardcode the `trip/` branch prefix and `.worktrees/` path convention. These are trip-specific assumptions baked into the scripts. If core were to support non-trip worktrees in the future, these scripts would need parameterization. For now, the trip-specific naming is acceptable since worktrees are currently only used by trips. (`plugins/core/skills/branching/sh/ensure-worktree.sh`, `plugins/core/skills/branching/sh/cleanup-worktree.sh`)
- The `list-trip-worktrees.sh` script queries the GitHub API for PR status, making it slower than `check-worktrees.sh`. The branching SKILL.md should clearly differentiate the two: `check-worktrees.sh` for fast guards, `list-trip-worktrees.sh` for detailed listings. (`plugins/core/skills/branching/SKILL.md`)
- Depends on ticket 1 (`20260329213021-move-ship-scripts-from-trippin-to-core.md`) being completed first, as both modify `core/commands/ship.md`. Cross-reference: `20260329213023-move-system-safety-to-core.md`
