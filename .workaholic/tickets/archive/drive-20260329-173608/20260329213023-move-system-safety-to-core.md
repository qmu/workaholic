---
created_at: 2026-03-29T21:30:23+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 0.1h
commit_hash: 4cb1503
category: Changed
---

# Move System-Safety Skill from Drivin to Core

## Overview

The `system-safety` skill is a cross-cutting concern used by both drivin (`drive-workflow/SKILL.md`) and trippin (`trip-protocol/SKILL.md` via `${CLAUDE_PLUGIN_ROOT}/../drivin/skills/system-safety/sh/detect.sh`). Move it to core so both plugins reference it through their shared dependency on core rather than through direct sibling references.

## Key Files

- `plugins/drivin/skills/system-safety/SKILL.md` - System safety skill definition (90 lines), moves to `plugins/core/skills/system-safety/SKILL.md`
- `plugins/drivin/skills/system-safety/sh/detect.sh` - Provisioning detection script (103 lines), moves to `plugins/core/skills/system-safety/sh/detect.sh`
- `plugins/drivin/skills/drive-workflow/SKILL.md` - Line 85-89: references system-safety skill; update path reference to core
- `plugins/trippin/skills/trip-protocol/SKILL.md` - Line 130: references `${CLAUDE_PLUGIN_ROOT}/../drivin/skills/system-safety/sh/detect.sh`; update to `${CLAUDE_PLUGIN_ROOT}/../core/skills/system-safety/sh/detect.sh`
- `plugins/drivin/.claude-plugin/plugin.json` - May need skills list update
- `plugins/core/.claude-plugin/plugin.json` - May need skills list update

## Related History

System-safety was created in drivin because the drive workflow was the first consumer. When trippin adopted it, it used a cross-plugin sibling path, creating an undeclared dependency from trippin to drivin.

- [20260311125425-add-system-config-safety-harness.md](.workaholic/tickets/archive/drive-20260311-125319/20260311125425-add-system-config-safety-harness.md) - Created system-safety skill in drivin; noted that trippin Constructor references it via cross-plugin path (same concern: cross-plugin coupling)
- [20260319163918-migrate-hardcoded-plugin-paths-to-variable.md](.workaholic/tickets/archive/trip/trip-20260319-040153/20260319163918-migrate-hardcoded-plugin-paths-to-variable.md) - Migrated hardcoded paths to `${CLAUDE_PLUGIN_ROOT}` notation; identified cross-plugin references as a maintainability concern

## Implementation Steps

1. **Create `plugins/core/skills/system-safety/` directory structure**:
   - Create `plugins/core/skills/system-safety/SKILL.md` - copy verbatim from drivin
   - Create `plugins/core/skills/system-safety/sh/detect.sh` - copy verbatim from drivin

2. **Update `plugins/core/skills/system-safety/SKILL.md`** path references:
   - The SKILL.md references `${CLAUDE_PLUGIN_ROOT}/skills/system-safety/sh/detect.sh` which already matches the target path in core (same relative structure). No changes needed to internal references.

3. **Update `plugins/drivin/skills/drive-workflow/SKILL.md`**:
   - The "System Safety" section references "the preloaded **system-safety** skill"
   - Since drivin will declare a dependency on core (ticket 5), the skill preload should change from `system-safety` (local) to `core:system-safety` (cross-plugin) in the drive command frontmatter
   - Update the drive command frontmatter (`plugins/drivin/commands/drive.md`) to reference `core:system-safety` instead of `system-safety`

4. **Update `plugins/trippin/skills/trip-protocol/SKILL.md`**:
   - Line 130: Replace `${CLAUDE_PLUGIN_ROOT}/../drivin/skills/system-safety/sh/detect.sh` with `${CLAUDE_PLUGIN_ROOT}/../core/skills/system-safety/sh/detect.sh`

5. **Update `plugins/trippin/agents/constructor.md`** (if it preloads system-safety):
   - Change skill preload from `drivin:system-safety` to `core:system-safety`

6. **Remove `plugins/drivin/skills/system-safety/` directory entirely**:
   - Delete `plugins/drivin/skills/system-safety/SKILL.md`
   - Delete `plugins/drivin/skills/system-safety/sh/detect.sh`

## Patches

### `plugins/trippin/skills/trip-protocol/SKILL.md`

```diff
--- a/plugins/trippin/skills/trip-protocol/SKILL.md
+++ b/plugins/trippin/skills/trip-protocol/SKILL.md
@@ -127,7 +127,7 @@
 ## System Safety

-Before implementation, Constructor runs: `bash ${CLAUDE_PLUGIN_ROOT}/../drivin/skills/system-safety/sh/detect.sh`. If `system_changes_authorized` is false, use project-local alternatives only.
+Before implementation, Constructor runs: `bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/system-safety/sh/detect.sh`. If `system_changes_authorized` is false, use project-local alternatives only.
```

## Considerations

- The `detect.sh` script is entirely self-contained (it only uses `git rev-parse`, file existence checks, and `basename`). No internal path changes are needed when moving it. (`plugins/drivin/skills/system-safety/sh/detect.sh`)
- The `drive-workflow/SKILL.md` references system-safety conceptually ("follow the preloaded system-safety skill") rather than by script path. The key change is in the command frontmatter where the skill is preloaded. After moving to core, `plugins/drivin/commands/drive.md` must preload `core:system-safety` instead of `system-safety`. (`plugins/drivin/commands/drive.md`)
- The `constructor.md` agent in trippin also preloads system-safety. Verify the exact preload syntax (`drivin:system-safety` vs `system-safety`) and update to `core:system-safety`. (`plugins/trippin/agents/constructor.md`)
- This ticket is independent of tickets 1 and 2 (no shared file modifications) and can be implemented in parallel. Cross-reference: `20260329213025-declare-plugin-dependencies.md` will formalize the core dependency.
