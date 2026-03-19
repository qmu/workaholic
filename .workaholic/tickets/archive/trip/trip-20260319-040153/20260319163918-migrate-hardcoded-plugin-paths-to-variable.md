---
created_at: 2026-03-19T16:39:18+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 1h
commit_hash: b9a7a49
category: Changed
---

# Migrate Hardcoded Plugin Paths to Variable Notation

## Overview

All 92 occurrences of `~/.claude/plugins/marketplaces/workaholic/plugins/...` across 49 plugin files should be migrated to use a variable-based notation for portability. The current hardcoded absolute path `~/.claude/plugins/marketplaces/workaholic/` is an implementation detail of the marketplace installation layout. If Claude Code changes installation paths, renames the marketplace, or supports alternative plugin locations, every reference breaks. Additionally, the CLAUDE.md "Skill Script Path Rule" currently prescribes this hardcoded pattern as the canonical approach, so it must be updated to prescribe the new notation.

**Key constraint**: `${CLAUDE_PLUGIN_ROOT}` is only available to hook scripts (Claude Code sets it before invoking hooks). It is NOT available in the general shell environment where skill scripts are executed by the LLM agent. A different mechanism is needed for skill/command/agent markdown files, which contain bash code blocks that the LLM copies and executes.

## Key Files

- `CLAUDE.md` - Lines 100-111: Skill Script Path Rule section that prescribes the hardcoded path pattern
- `plugins/drivin/hooks/hooks.json` - Already uses `${CLAUDE_PLUGIN_ROOT}` correctly (line 10)
- `plugins/core/commands/ship.md` - 9 hardcoded paths (highest count)
- `plugins/trippin/skills/trip-protocol/SKILL.md` - 7 hardcoded paths
- `plugins/trippin/commands/trip.md` - 6 hardcoded paths
- `plugins/core/commands/report.md` - 4 hardcoded paths
- `plugins/drivin/skills/commit/SKILL.md` - 4 hardcoded paths
- `plugins/trippin/skills/ship/SKILL.md` - 4 hardcoded paths
- `plugins/drivin/commands/drive.md` - 3 hardcoded paths
- `plugins/drivin/commands/scan.md` - 3 hardcoded paths
- 39 additional files with 1-2 occurrences each

## Related History

The hardcoded path convention was established when the plugin architecture was first created. Early tickets identified the fragility but chose the hardcoded absolute path as the pragmatic solution because relative paths caused exit code 127 failures and `CLAUDE_PLUGIN_ROOT` was only available for hooks.

Past tickets that touched similar areas:

- [20260129101447-fix-archive-script-path-reference.md](.workaholic/tickets/archive/main/20260129101447-fix-archive-script-path-reference.md) - Noted `${CLAUDE_PLUGIN_ROOT}` as future consideration; identified that it only works for hooks (same concern: path portability)
- [20260129094618-fix-create-branch-path-reference.md](.workaholic/tickets/archive/feat-20260129-023941/20260129094618-fix-create-branch-path-reference.md) - Fixed path reference by inlining script; noted `CLAUDE_PLUGIN_ROOT` does not apply to skills/commands (same layer: Config)
- [20260129041924-add-ticket-validation-hook.md](.workaholic/tickets/archive/feat-20260129-023941/20260129041924-add-ticket-validation-hook.md) - Established `${CLAUDE_PLUGIN_ROOT}` usage for hooks (same layer: Config)
- [20260302215035-rename-core-to-drivin.md](.workaholic/tickets/archive/drive-20260302-213941/20260302215035-rename-core-to-drivin.md) - Renamed plugin directories; all 83+ hardcoded paths would have needed updating if the marketplace path had changed (same concern: path fragility)

## Implementation Steps

1. **Investigate Claude Code's variable expansion for skill scripts**:
   - Determine if Claude Code expands `${CLAUDE_PLUGIN_ROOT}` in markdown code blocks at plugin load time (not just hooks)
   - Check Claude Code documentation or changelog for any plugin-path variable support
   - If `${CLAUDE_PLUGIN_ROOT}` is NOT expanded in markdown files, consider alternative approaches:
     - **Option A**: A new convention where skill scripts derive their own root path via `SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"` and navigate relative to it (already used by `archive.sh` and `create-or-update.sh`)
     - **Option B**: A plugin-level config that defines a path variable resolved at install time
     - **Option C**: Accept the hardcoded path for markdown references (LLM reads them as instructions, not executables) and only fix `.sh` files to use self-relative paths

2. **If Option A (self-relative paths in shell scripts) is chosen**:
   - For each `.sh` file that is invoked via hardcoded path in markdown: the path in markdown is what the LLM types into bash. The LLM must know the full path. So markdown files inherently need to contain the resolved path OR the LLM needs a way to discover it.
   - This means the issue is primarily about **markdown content** (instructions for the LLM), not about shell script internals.
   - The LLM agent reads the markdown at plugin load time, so if Claude Code could expand `${PLUGIN_PATH}` in markdown content at load time, all 92 occurrences would resolve automatically.

3. **If variable expansion is NOT available, adopt a tiered approach**:
   - **Shell scripts** (`.sh` files): Already invoked with the full path; internally they can use `$0`-relative paths for cross-script calls (some already do via `SCRIPT_DIR`)
   - **Markdown files** (SKILL.md, commands, agents): Keep the full path but extract the marketplace base path as a documented constant. If the base path changes, a single find-and-replace updates all files.
   - **CLAUDE.md**: Update the Skill Script Path Rule to acknowledge this is a known limitation and document the find-and-replace procedure

4. **If variable expansion IS available**:
   - Replace all 92 occurrences across 49 files: `~/.claude/plugins/marketplaces/workaholic/plugins/` becomes `${CLAUDE_PLUGIN_ROOT}/` (for drivin plugin references) or an appropriate per-plugin variable
   - Note: References cross plugin boundaries (e.g., drivin commands referencing trippin scripts). A single `CLAUDE_PLUGIN_ROOT` per plugin would need a way to reference sibling plugins.

5. **Update CLAUDE.md Skill Script Path Rule** (lines 100-111):
   - Replace the current "hardcoded absolute path from home directory" prescription with the chosen approach
   - Update the Common Operations table (lines 70-72) with the new path format
   - Update the examples in the Shell Script Principle section

6. **Perform bulk replacement across all 49 files**:
   - Use a consistent search-and-replace pattern
   - Verify each file after replacement
   - Run any available validation (e.g., the validate-writer-output script) to confirm no broken references

## Considerations

- The 92 hardcoded paths span three plugins (core: 15 occurrences in 3 files, drivin: 52 occurrences in 36 files, trippin: 25 occurrences in 10 files). A cross-plugin migration requires coordination. (`plugins/core/commands/ship.md`, `plugins/drivin/commands/drive.md`, `plugins/trippin/commands/trip.md`)
- References cross plugin boundaries: drivin commands invoke trippin scripts and vice versa. A per-plugin `CLAUDE_PLUGIN_ROOT` variable would only resolve to the current plugin's directory, not sibling plugins. A marketplace-level root variable (e.g., `${MARKETPLACE_ROOT}`) would be needed, or sibling plugin references would need a different pattern. (`plugins/core/commands/ship.md` lines 30-32 reference trippin skills)
- The `archive.sh` and `create-or-update.sh` scripts already use `SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"` for self-relative path resolution internally. This pattern works for shell-to-shell calls but does not solve the markdown-to-shell invocation problem. (`plugins/drivin/skills/archive-ticket/sh/archive.sh` lines 57-58, `plugins/drivin/skills/create-pr/sh/create-or-update.sh` line 24)
- This is a large-scale mechanical change (49 files) that carries risk of typos or missed occurrences. A CI check or pre-commit hook that flags hardcoded marketplace paths could prevent regression.
- This ticket depends on understanding Claude Code's plugin path variable support. If investigation in Step 1 reveals no variable expansion for markdown content, the scope reduces significantly to just documenting the limitation and improving the CLAUDE.md guidance. The actual bulk replacement would then be deferred until Claude Code adds such support.
- This ticket should be implemented after the companion ticket "Fix .workaholic Path Resolution for Worktree Compatibility" since that ticket addresses the more immediately impactful bug (worktree paths) while this one addresses long-term maintainability.
