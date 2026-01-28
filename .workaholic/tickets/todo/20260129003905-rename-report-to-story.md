---
created_at: 2026-01-29T00:39:05+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Rename /report to /story (Breaking Change)

## Overview

Rename the `/report` command to `/story`. This is a **breaking change** that affects user-facing documentation and command usage. The new name better reflects the command's primary output: generating a branch story that documents the implementation narrative, decision-making process, and development journey.

## Key Files

- `plugins/core/commands/report.md` - Rename to `story.md` and update frontmatter/headings
- `README.md` - Update command table and workflow examples
- `CLAUDE.md` - Update Commands table and Development Workflow section
- `plugins/core/README.md` - Update command table and workflow references
- `.workaholic/specs/user-guide/commands.md` - Update `/report` section to `/story`
- `plugins/core/skills/create-pr/SKILL.md` - Update comment referencing "report command"
- `plugins/core/skills/write-story/SKILL.md` - Update references to `/report` orchestrator

## Related History

This follows the same pattern as the previous rename from `/pull-request` to `/report`. The command has evolved to emphasize its documentation-generation role over PR creation.

Past tickets that touched similar areas:

- [20260127014257-rename-pull-request-to-report.md](.workaholic/tickets/archive/feat-20260126-214833/20260127014257-rename-pull-request-to-report.md) - Previous rename of this same command (same pattern)
- [20260128211509-use-haiku-for-report-subagents.md](.workaholic/tickets/archive/feat-20260128-012023/20260128211509-use-haiku-for-report-subagents.md) - Modified report.md command (same file)
- [20260128210112-add-discovered-insights-to-final-report.md](.workaholic/tickets/archive/feat-20260128-012023/20260128210112-add-discovered-insights-to-final-report.md) - Enhanced report command functionality

## Implementation Steps

1. Rename command file:
   - `mv plugins/core/commands/report.md plugins/core/commands/story.md`

2. Update `plugins/core/commands/story.md`:
   - Change frontmatter `name: report` to `name: story`
   - Update H1 heading from "# Report" to "# Story"
   - Update description to reflect new command name

3. Update `README.md`:
   - Change `/report` to `/story` in Quick Start table
   - Update typical session example

4. Update `CLAUDE.md`:
   - Change `/report` to `/story` in Commands table
   - Update Development Workflow step 3

5. Update `plugins/core/README.md`:
   - Change `/report` to `/story` in Commands table
   - Update workflow section

6. Update `.workaholic/specs/user-guide/commands.md`:
   - Rename section header from `### /report` to `### /story`
   - Update command description and usage

7. Update `plugins/core/skills/create-pr/SKILL.md`:
   - Change comment from "report command" to "story command"

8. Update `plugins/core/skills/write-story/SKILL.md`:
   - Change references from `/report` to `/story` in orchestrator context

## Considerations

- **Breaking change**: Users familiar with `/report` will need to learn the new `/story` command name
- Subagent names (`story-writer`, `pr-creator`, etc.) remain unchanged - they are internal implementation details
- The `write-story` skill name aligns well with the new `/story` command name
- Historical tickets and stories in archive should NOT be updated - they document past work accurately
