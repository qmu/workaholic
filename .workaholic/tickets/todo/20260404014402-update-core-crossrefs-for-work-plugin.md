---
created_at: 2026-04-04T01:44:02+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Update core plugin cross-references for work plugin

## Context

The core plugin has soft references to both drivin and trippin for context-aware routing in its `/report` and `/ship` commands. With both plugins merged into `work`, all cross-plugin references must update from `drivin`/`trippin` to `work`.

## Plan

### Step 1: Update `core/commands/report.md`

Current references to fix:

1. **Line 2 (frontmatter skills)**: `trip-protocol` and `write-trip-report` -> `work:trip-protocol` and `work:write-trip-report`
2. **Line 45**: `subagent_type: "drivin:story-writer"` -> `subagent_type: "work:story-writer"`
3. **Line 54**: `bash ${CLAUDE_PLUGIN_ROOT}/../trippin/skills/write-trip-report/scripts/gather-artifacts.sh` -> `bash ${CLAUDE_PLUGIN_ROOT}/../work/skills/write-trip-report/scripts/gather-artifacts.sh`
4. **Line 64**: `bash ${CLAUDE_PLUGIN_ROOT}/../drivin/skills/report/scripts/create-or-update.sh` -> `bash ${CLAUDE_PLUGIN_ROOT}/../work/skills/report/scripts/create-or-update.sh`

Also update the context routing text:
- "Route to Drivin workflows" -> "Route to drive workflows"
- "Route to Trippin workflows" -> "Route to trip workflows"
- Update context names if changed by ticket #2 (e.g., drive/trip/trip_drive -> work with mode)

### Step 2: Update `core/commands/ship.md`

Current references to fix:

1. **Line 5 (frontmatter skills)**: `trippin:trip-protocol` -> `work:trip-protocol`

Also update context routing text if context names changed.

### Step 3: Update any other core references

Grep for `drivin` and `trippin` in all core plugin files:
- `core/skills/branching/SKILL.md` - update context routing descriptions
- Any other skill or script files

### Step 4: Verify no broken references

After updates, verify:
- All `${CLAUDE_PLUGIN_ROOT}/../work/` paths point to files that exist in the new work plugin
- All `subagent_type: "work:*"` references match agent files in `work/agents/`
- All skill preload references (`work:skill-name`) match skills in `work/skills/`

## Verification

- `grep -r "drivin" plugins/core/` returns no results
- `grep -r "trippin" plugins/core/` returns no results
- All cross-plugin paths resolve to existing files in `plugins/work/`
