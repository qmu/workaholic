---
created_at: 2026-03-30T20:19:37+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 0.25h
commit_hash: 4a7903e
category: Changed
---

# Consolidate Generic-Purpose Skills from Drivin to Core Plugin

## Overview

The drivin plugin contains several skills that are purely generic utilities with no workflow-specific logic: `commit`, `gather-git-context`, `gather-ticket-metadata`, and `branching` (a partial duplicate of core's branching). Move the first three to core so all plugins can depend on them without requiring a drivin dependency. For branching, merge drivin's unique scripts (`check.sh`, `create.sh`, `check-version-bump.sh`) into core's existing branching skill and remove the drivin version entirely. This eliminates the cross-plugin dependency that standards currently has on drivin solely for `gather-git-context`, and makes commit/metadata utilities available to any plugin through core.

## Key Files

- `plugins/drivin/skills/commit/SKILL.md` - Commit skill definition (132 lines), moves to `plugins/core/skills/commit/`
- `plugins/drivin/skills/commit/sh/commit.sh` - Commit shell script (108 lines), moves to `plugins/core/skills/commit/sh/`
- `plugins/drivin/skills/gather-git-context/SKILL.md` - Git context skill (39 lines), moves to `plugins/core/skills/gather-git-context/`
- `plugins/drivin/skills/gather-git-context/sh/gather.sh` - Git context shell script (38 lines), moves to `plugins/core/skills/gather-git-context/sh/`
- `plugins/drivin/skills/gather-ticket-metadata/SKILL.md` - Ticket metadata skill (35 lines), moves to `plugins/core/skills/gather-ticket-metadata/`
- `plugins/drivin/skills/gather-ticket-metadata/sh/gather.sh` - Ticket metadata shell script (19 lines), moves to `plugins/core/skills/gather-ticket-metadata/sh/`
- `plugins/drivin/skills/branching/SKILL.md` - Drivin branching skill (55 lines), to be removed after merging unique scripts into core
- `plugins/drivin/skills/branching/sh/check.sh` - Branch state check (25 lines), moves to `plugins/core/skills/branching/sh/`
- `plugins/drivin/skills/branching/sh/create.sh` - Branch creation (20 lines), moves to `plugins/core/skills/branching/sh/`
- `plugins/drivin/skills/branching/sh/check-version-bump.sh` - Version bump check (23 lines), moves to `plugins/core/skills/branching/sh/`
- `plugins/drivin/skills/archive-ticket/SKILL.md` - References `commit` skill in frontmatter (line 5) and via `${CLAUDE_PLUGIN_ROOT}` path (line 31)
- `plugins/drivin/skills/drive-approval/SKILL.md` - References `commit` skill via `${CLAUDE_PLUGIN_ROOT}` path (line 134)
- `plugins/drivin/skills/create-ticket/SKILL.md` - References `gather-ticket-metadata` in frontmatter (line 5) and via path (line 18)
- `plugins/drivin/agents/story-writer.md` - References `gather-git-context` in frontmatter (line 6)
- `plugins/drivin/agents/ticket-organizer.md` - References `branching` and `gather-ticket-metadata` in frontmatter (lines 8-10)
- `plugins/drivin/commands/scan.md` - References `gather-git-context` in frontmatter (line 5)
- `plugins/standards/agents/performance-analyst.md` - References `drivin:gather-git-context` in frontmatter (line 5)
- `plugins/core/commands/report.md` - References `${CLAUDE_PLUGIN_ROOT}/../drivin/skills/branching/sh/check-version-bump.sh` (line 44)
- `plugins/core/skills/branching/SKILL.md` - Core branching skill documentation, needs sections added for new scripts
- `CLAUDE.md` - Common Operations table references `gather-git-context` and `gather-ticket-metadata` (lines 88-89); Project Structure lists core/drivin skills (lines 26-38)

## Related History

This continues the pattern established by the previous drive session of consolidating shared utilities into core. System-safety, ship scripts, and worktree lifecycle scripts were already moved from drivin/trippin to core. The three generic skills (commit, gather-git-context, gather-ticket-metadata) and the duplicate branching skill are the remaining candidates.

- [20260329213023-move-system-safety-to-core.md](.workaholic/tickets/archive/drive-20260329-173608/20260329213023-move-system-safety-to-core.md) - Moved system-safety from drivin to core following the same pattern (same layer: Config, same type: refactoring)
- [20260329213021-move-ship-scripts-from-trippin-to-core.md](.workaholic/tickets/archive/drive-20260329-173608/20260329213021-move-ship-scripts-from-trippin-to-core.md) - Moved ship scripts from trippin to core; established the cross-plugin consolidation workflow
- [20260329213025-declare-plugin-dependencies.md](.workaholic/tickets/archive/drive-20260329-173608/20260329213025-declare-plugin-dependencies.md) - Declared plugin dependencies and audited cross-plugin references; identified `drivin:gather-git-context` as the sole reason standards depends on drivin
- [20260328152057-create-standards-plugin.md](.workaholic/tickets/archive/drive-20260326-183949/20260328152057-create-standards-plugin.md) - Created standards plugin; noted that performance-analyst needed `drivin:gather-git-context` as a cross-plugin dependency
- [20260204180858-create-commit-skill.md](.workaholic/tickets/archive/drive-20260204-160722/20260204180858-create-commit-skill.md) - Original creation of the commit skill (same files being moved)
- [20260202182054-gather-ticket-metadata-skill.md](.workaholic/tickets/archive/drive-20260202-134332/20260202182054-gather-ticket-metadata-skill.md) - Original creation of the gather-ticket-metadata skill (same files being moved)

## Implementation Steps

1. **Move `plugins/drivin/skills/commit/` to `plugins/core/skills/commit/`**:
   - Copy `SKILL.md` and `sh/commit.sh` verbatim (no internal path changes needed since `${CLAUDE_PLUGIN_ROOT}` references are relative to the owning plugin)

2. **Move `plugins/drivin/skills/gather-git-context/` to `plugins/core/skills/gather-git-context/`**:
   - Copy `SKILL.md` and `sh/gather.sh` verbatim

3. **Move `plugins/drivin/skills/gather-ticket-metadata/` to `plugins/core/skills/gather-ticket-metadata/`**:
   - Copy `SKILL.md` and `sh/gather.sh` verbatim

4. **Merge drivin branching scripts into core branching**:
   - Copy `plugins/drivin/skills/branching/sh/check.sh` to `plugins/core/skills/branching/sh/check.sh`
   - Copy `plugins/drivin/skills/branching/sh/create.sh` to `plugins/core/skills/branching/sh/create.sh`
   - Copy `plugins/drivin/skills/branching/sh/check-version-bump.sh` to `plugins/core/skills/branching/sh/check-version-bump.sh`
   - Update `plugins/core/skills/branching/SKILL.md` to document the three new scripts (Check Branch, Create Branch, Check Version Bump sections)

5. **Remove drivin skill directories**:
   - Delete `plugins/drivin/skills/commit/` entirely
   - Delete `plugins/drivin/skills/gather-git-context/` entirely
   - Delete `plugins/drivin/skills/gather-ticket-metadata/` entirely
   - Delete `plugins/drivin/skills/branching/` entirely

6. **Update drivin skill/agent/command frontmatter references**:
   - `plugins/drivin/skills/archive-ticket/SKILL.md`: Change frontmatter `- commit` to `- core:commit`
   - `plugins/drivin/agents/story-writer.md`: Change frontmatter `- gather-git-context` to `- core:gather-git-context`
   - `plugins/drivin/agents/ticket-organizer.md`: Change frontmatter `- branching` to `- core:branching`, change `- gather-ticket-metadata` to `- core:gather-ticket-metadata`
   - `plugins/drivin/skills/create-ticket/SKILL.md`: Change frontmatter `- gather-ticket-metadata` to `- core:gather-ticket-metadata`
   - `plugins/drivin/commands/scan.md`: Change frontmatter `- gather-git-context` to `- core:gather-git-context`

7. **Update drivin `${CLAUDE_PLUGIN_ROOT}` path references**:
   - `plugins/drivin/skills/drive-approval/SKILL.md` line 134: Change `${CLAUDE_PLUGIN_ROOT}/skills/commit/sh/commit.sh` to `${CLAUDE_PLUGIN_ROOT}/../core/skills/commit/sh/commit.sh`
   - `plugins/drivin/skills/create-ticket/SKILL.md` line 18: Change `${CLAUDE_PLUGIN_ROOT}/skills/gather-ticket-metadata/sh/gather.sh` to `${CLAUDE_PLUGIN_ROOT}/../core/skills/gather-ticket-metadata/sh/gather.sh`
   - `plugins/drivin/skills/archive-ticket/SKILL.md` line 31: The archive.sh script itself calls commit.sh internally -- verify and update the archive.sh script's internal reference if it calls commit.sh by path

8. **Update standards plugin references**:
   - `plugins/standards/agents/performance-analyst.md` line 5: Change `- drivin:gather-git-context` to `- core:gather-git-context`

9. **Update core report.md reference**:
   - `plugins/core/commands/report.md` line 44: Change `${CLAUDE_PLUGIN_ROOT}/../drivin/skills/branching/sh/check-version-bump.sh` to `${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/check-version-bump.sh` (now local to core)

10. **Update `CLAUDE.md`**:
    - Project Structure section: Update `core/skills/` comment to include the new skills
    - Update `drivin/skills/` comment to reflect removed skills
    - Common Operations table already uses `${CLAUDE_PLUGIN_ROOT}` which will auto-resolve, but verify the descriptions are still accurate

11. **Verify archive-ticket/sh/archive.sh internals**: Read the archive script to check if it references commit.sh by path. If so, update to use `${CLAUDE_PLUGIN_ROOT}/../core/skills/commit/sh/commit.sh` or adjust the invocation pattern.

## Considerations

- The `${CLAUDE_PLUGIN_ROOT}` path in SKILL.md files is relative to the owning plugin, so `${CLAUDE_PLUGIN_ROOT}/skills/commit/sh/commit.sh` in core's copy will resolve correctly without changes to the SKILL.md content itself. Only files that reference these skills from *outside* the owning plugin need path updates. (`plugins/drivin/skills/commit/SKILL.md`, `plugins/core/skills/commit/SKILL.md`)
- The `archive-ticket/sh/archive.sh` script likely calls `commit.sh` directly by constructing a path. This is a shell script calling another shell script, so `${CLAUDE_PLUGIN_ROOT}` is not available at runtime -- it may use a relative path or the caller passes the path. Read the script carefully to determine the correct update strategy. (`plugins/drivin/skills/archive-ticket/sh/archive.sh`)
- The drivin branching skill's `check.sh` and `create.sh` scripts have simpler implementations than what core might eventually need (e.g., no worktree awareness). They are safe to add to core as-is since they serve a different purpose (basic branch check/create) than core's existing scripts (context detection, worktree management). (`plugins/core/skills/branching/sh/check.sh`, `plugins/core/skills/branching/sh/create.sh`)
- The `check-version-bump.sh` script hardcodes `main` as the base branch (line 8: `git log main..HEAD`). This works for the current workflow but may need to be parameterized if the default branch varies. Keep as-is for this ticket since it matches existing behavior. (`plugins/drivin/skills/branching/sh/check-version-bump.sh` line 8)
- After this migration, the standards plugin will no longer have any cross-plugin dependency on drivin. The only external skill reference (`drivin:gather-git-context`) becomes `core:gather-git-context`, and standards already has no declared dependencies. This is a clean improvement. (`plugins/standards/agents/performance-analyst.md`)
- The `.workaholic/policies/recovery.md` and `.workaholic/policies/delivery.md` files reference `plugins/drivin/skills/commit/sh/commit.sh` by path in their documentation. These are generated documentation files and will be updated on the next `/scan` run. No manual update needed in this ticket. (`.workaholic/policies/recovery.md`, `.workaholic/policies/delivery.md`)

## Final Report

Moved 3 skills (commit, gather-git-context, gather-ticket-metadata) from drivin to core and merged 3 branching scripts (check.sh, create.sh, check-version-bump.sh) into core's existing branching skill. Removed all 4 drivin skill directories. Updated 6 frontmatter skill references across drivin and standards plugins to use `core:` prefix. Updated 3 `${CLAUDE_PLUGIN_ROOT}` path references and 1 relative shell script path in archive.sh. Documented the 3 new scripts in core branching SKILL.md. Updated CLAUDE.md project structure to reflect core's expanded skill set. The standards plugin no longer has any cross-plugin dependency on drivin. Generated documentation in `.workaholic/` still references old paths and will auto-update on next `/scan`.
