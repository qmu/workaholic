---
created_at: 2026-03-28T15:07:19+09:00
author: a@qmu.jp
type: enhancement
layer: [UX]
effort: 0.1h
commit_hash: 0dfbbcd
category: Changed
---

# Display Story Content After /report Completes

## Overview

After the `/report` command finishes generating a story and creating a PR, display the entire Markdown content of the story file to the developer inline. This allows the developer to read and review the story without opening GitHub. No approval dialog is needed -- just output the content. If the developer is satisfied, they can run `/ship` to merge. If not, they can add tickets to improve it.

## Key Files

- `plugins/core/commands/report.md` - The report command orchestration. Drive Context flow invokes story-writer then displays PR URL. A new step to display story content should be added after receiving the story-writer result.
- `plugins/drivin/agents/story-writer.md` - The story-writer subagent. Its output JSON already includes `story_file` path, which the report command can use to read and display the file.
- `plugins/drivin/skills/write-story/SKILL.md` - Defines the story content structure. No changes needed, but relevant for understanding what will be displayed.

## Related History

The /report command has evolved through multiple naming iterations and workflow refinements, with the story-writer subagent becoming the central hub for story generation and PR creation. The story file serves as the single source of truth for PR content.

Past tickets that touched similar areas:

- [20260203180235-rename-story-to-report.md](.workaholic/tickets/archive/drive-20260203-122444/20260203180235-rename-story-to-report.md) - Renamed /story to /report (same file: report.md)
- [20260210121628-summarize-changes-in-report.md](.workaholic/tickets/archive/drive-20260210-121635/20260210121628-summarize-changes-in-report.md) - Refined story output format (same layer: UX)
- [20260311212022-unify-report-command-across-plugins.md](.workaholic/tickets/archive/drive-20260311-125319/20260311212022-unify-report-command-across-plugins.md) - Unified report command across drive/trip contexts (same file: report.md)
- [20260202200553-reorganize-story-agent-hierarchy.md](.workaholic/tickets/archive/drive-20260202-134332/20260202200553-reorganize-story-agent-hierarchy.md) - Restructured story-writer as central orchestration hub (same file: story-writer.md)

## Implementation Steps

1. In `plugins/core/commands/report.md`, add a new step to the Drive Context flow between invoking story-writer and displaying the PR URL. After receiving the story-writer result JSON, read the story file at the path indicated by the `story_file` field and display its full Markdown content to the developer.

2. Add the same display step to the Trip Context flow after the story file is written and committed, displaying the journey report content inline before showing the PR URL.

## Patches

### `plugins/core/commands/report.md`

```diff
--- a/plugins/core/commands/report.md
+++ b/plugins/core/commands/report.md
@@ -29,7 +29,8 @@

 1. **Bump version** following CLAUDE.md Version Management section (patch increment). **Skip if a "Bump version" commit already exists in the current branch** (check with `bash ${CLAUDE_PLUGIN_ROOT}/../drivin/skills/branching/sh/check-version-bump.sh`; if `already_bumped` is `true`, skip this step).
 2. **Invoke story-writer** (`subagent_type: "drivin:story-writer"`, `model: "opus"`)
-3. **Display PR URL** from story-writer result (mandatory)
+3. **Display story content**: Read the story file from the `story_file` path in the story-writer result and output the entire Markdown content so the developer can review inline
+4. **Display PR URL** from story-writer result (mandatory)
```

> **Note**: This patch is speculative -- verify the exact line numbers before applying.

## Considerations

- The story file can be long (100-300 lines for branches with many tickets). This is intentional -- the developer wants to read and review the full content inline rather than opening GitHub. (`plugins/drivin/skills/write-story/SKILL.md`)
- The story file contains YAML frontmatter (branch, dates, metrics). Including frontmatter in the output is acceptable since it provides useful context about the branch. (`plugins/drivin/skills/write-story/SKILL.md` lines 199-215)
- The Trip Context flow writes the story file directly (not via story-writer subagent), so the display step for trips should read from `.workaholic/stories/<branch-name>.md` directly rather than from a subagent result field. (`plugins/core/commands/report.md` lines 38-48)
- No approval dialog or user interaction is needed -- this is a read-only display step that does not gate the workflow. The developer decides their next action independently.

## Final Report

Development completed as planned.
