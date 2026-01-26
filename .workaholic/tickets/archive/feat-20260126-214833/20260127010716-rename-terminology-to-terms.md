---
created_at: 2026-01-27T01:07:16+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 0.25h
commit_hash: d213ea1
category: Changed
---

# Rename terminology to terms

## Overview

Rename "terminology" to "terms" throughout the codebase for brevity. "Terms" conveys the same meaning with fewer characters, making directory paths and references more concise.

Changes:
- Directory: `.workaholic/terminology/` → `.workaholic/terms/`
- Agent: `terminology-writer` → `terms-writer`
- All text references updated accordingly

## Key Files

- `.workaholic/terminology/` - Directory to rename to `.workaholic/terms/`
- `plugins/core/agents/terminology-writer.md` - Rename to `terms-writer.md`
- `plugins/core/commands/pull-request.md` - References terminology-writer subagent
- `plugins/core/rules/workaholic.md` - References terminology directory
- `.workaholic/specs/developer-guide/architecture.md` - File tree references
- `.workaholic/specs/developer-guide/architecture_ja.md` - File tree references (Japanese)

## Implementation Steps

1. **Rename directory**:
   ```bash
   git mv .workaholic/terminology .workaholic/terms
   ```

2. **Rename agent file**:
   ```bash
   git mv plugins/core/agents/terminology-writer.md plugins/core/agents/terms-writer.md
   ```

3. **Update agent file content** (`plugins/core/agents/terms-writer.md`):
   - Change `name: terminology-writer` → `name: terms-writer`
   - Change `description:` to reference "terms" instead of "terminology"
   - Update all paths from `.workaholic/terminology/` → `.workaholic/terms/`
   - Update heading from "Terminology Writer" → "Terms Writer"

4. **Update pull-request.md**:
   - Change `terminology-writer` → `terms-writer`
   - Change `core:terminology-writer` → `core:terms-writer`
   - Update comment about what it updates

5. **Update workaholic.md rule**:
   - Change `terminology/` → `terms/` in directory structure

6. **Update architecture.md and architecture_ja.md**:
   - Change `terminology/` → `terms/` in file tree
   - Update any prose references

7. **Update workflow.md and workflow_ja.md**:
   - Change "terminology" → "terms" in descriptions

8. **Update .workaholic/README.md and README_ja.md**:
   - Update directory structure references

9. **Update files inside `.workaholic/terms/`** (after rename):
   - Update `README.md` and `README_ja.md` titles/descriptions
   - Update frontmatter `category: developer` paths if any reference the directory name

10. **Update pending tickets** that reference terminology:
    - `.workaholic/tickets/20260127010400-remove-sync-workaholic-command.md` - Update terminology-writer references

## Considerations

- Historical references in `.workaholic/tickets/archive/` and `.workaholic/stories/` should NOT be modified
- CHANGELOG.md entries are historical and should remain unchanged
- The agent subagent_type in Task tool calls needs to change from `core:terminology-writer` to `core:terms-writer`
- Files inside the renamed directory keep their original names (e.g., `core-concepts.md` stays the same)

## Final Report

Development completed as planned.
