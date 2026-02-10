---
created_at: 2026-02-10T12:16:28+08:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.1h
commit_hash: 0942d51
category:
---

# Summarize Changes in /report Instead of Listing Every File

## Overview

Replace the per-file bullet list format in the story's "Section 4. Changes" with a concise summary per ticket. Currently the write-story skill mandates listing every changed file as individual bullet points, which produces extremely verbose output -- the recent `drive-20260208-131649` story's Section 4 alone spans 140+ lines of file listings across 17 tickets. Each ticket subsection should instead contain a 1-3 sentence summary describing what changed and why.

## Key Files

- `plugins/core/skills/write-story/SKILL.md` - Contains the Section 4 template, format guidelines, and the "MUST list all files changed" directive that needs to be replaced with summary-based guidance
- `plugins/core/agents/story-writer.md` - Orchestrates story generation; Phase 2 reads archived tickets and passes data to write-story skill (no changes expected but relevant for understanding the data flow)

## Related History

The write-story skill has been iteratively refined across multiple branches, evolving from simple ticket listings to the current detailed file-change format.

Past tickets that touched similar areas:

- [20260127021000-extract-story-skill.md](.workaholic/tickets/archive/feat-20260126-214833/20260127021000-extract-story-skill.md) - Extracted story writing into a dedicated skill (same file: write-story/SKILL.md)
- [20260124005056-story-as-pr-description.md](.workaholic/tickets/archive/feat-20260123-191707/20260124005056-story-as-pr-description.md) - Made story content serve as PR description (same section: Changes)
- [20260123161059-branch-story-generation.md](.workaholic/tickets/archive/feat-20260123-032323/20260123161059-branch-story-generation.md) - Original branch story generation feature (same layer: Config)

## Implementation Steps

1. Update the Section 4 template in `plugins/core/skills/write-story/SKILL.md` to replace file-listing bullet points with a summary paragraph format
2. Update the "Changes Guidelines" block to require concise summaries instead of exhaustive file lists
3. Keep the existing per-ticket subsection structure (`### 4-N. <Title> ([hash](url))`) and clickable commit hash requirement unchanged

## Patches

### `plugins/core/skills/write-story/SKILL.md`

```diff
--- a/plugins/core/skills/write-story/SKILL.md
+++ b/plugins/core/skills/write-story/SKILL.md
@@ -76,16 +76,14 @@
 ## 4. Changes

 One subsection per ticket, in chronological order:

 ### 4-1. <Ticket title> ([hash](<repo-url>/commit/<hash>))

-- First file changed with description of modification
-- Second file changed with description of modification
-- ...
+<1-3 sentence summary of what this ticket changed and why. Focus on the intent and scope of the change rather than enumerating individual files.>

 ### 4-2. <Next ticket title> ([hash](<repo-url>/commit/<hash>))

-- First file changed with description of modification
-- Second file changed with description of modification
-- ...
+<1-3 sentence summary of what this ticket changed and why.>

 ### ...
```

```diff
--- a/plugins/core/skills/write-story/SKILL.md
+++ b/plugins/core/skills/write-story/SKILL.md
@@ -94,8 +92,8 @@
 **Changes Guidelines:**
 - One subsection per ticket (not grouped by theme)
 - **CRITICAL**: Commit hash MUST be a clickable GitHub link, not plain text
   - Wrong: `(abc1234)` or `(<hash>)`
   - Correct: `([abc1234](<repo-url>/commit/abc1234))`
 - Format: `### 4-N. <Title> ([hash](<repo-url>/commit/<hash>))`
-- **MUST list all files changed** as bullet points, not paragraph prose
-- Reference ticket Implementation section or Changes section for the complete file list
+- **Summarize the change** in 1-3 sentences per ticket -- describe what was done and why, not individual files
+- Focus on intent, scope, and impact rather than enumerating every modified file
 - Chronological order matches ticket creation time
```

> **Note**: These patches are speculative -- the exact line numbers and context may shift if the file has been modified since reading. Verify the surrounding context before applying.

## Considerations

- The change only affects the write-story skill's guidelines; the story-writer subagent and overview-writer subagent require no modification since Section 4 is generated directly from archived ticket data by the story-writer (`plugins/core/skills/write-story/SKILL.md` lines 76-102)
- Existing stories already written with the file-listing format will not be retroactively changed, creating a style inconsistency in the stories archive (`.workaholic/stories/`)
- The summarized format may reduce traceability for reviewers who want to see exactly which files were touched -- the clickable commit hash provides a fallback for this need (`plugins/core/skills/write-story/SKILL.md` line 96-98)

## Final Report

Applied both patches exactly as specified. Updated the Section 4 template to use 1-3 sentence summaries instead of per-file bullet lists, and updated the Changes Guidelines to match. No other files required changes.
