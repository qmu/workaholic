---
created_at: 2026-01-27T18:27:21+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 5m
commit_hash: c63dd53
category: Changed
---

# Improve story Changes section granularity and Journey summary

## Overview

The current story-writer generates a Changes section that groups changes into broad categories (e.g., "4.1. Subagent architecture for documentation generation"). This makes it hard to see individual ticket contributions. The user wants:

1. **Changes section**: One subsection per ticket/commit, not grouped summaries
2. **Journey section**: More summarized narrative (currently too detailed)

The goal is to make Changes comprehensive (every change listed) while Journey stays high-level narrative.

## Key Files

- `plugins/core/agents/story-writer.md` - Main agent defining story structure

## Related History

Past tickets that touched similar areas:

- `20260127163720-simplify-topic-tree-as-journey-reference.md` - Modified story-writer format (same file)
- `20260127100459-add-topic-tree-to-story.md` - Added topic tree section (same file)
- `20260127011734-fix-story-decision-review-format.md` - Modified story-writer format (same file)
- `20260127004417-story-writer-subagent.md` - Created the story-writer agent (same file)

## Implementation Steps

1. Update `plugins/core/agents/story-writer.md` section "## 4. Changes":

   - Change from grouped subsections to one subsection per ticket
   - Each subsection should be: `### 4.N. <Ticket title> ([hash](commit-url))`
   - Content: Brief 1-2 sentence description from ticket Overview
   - Link to ticket file for full details

2. Update section "## 3. Journey":

   - Add guidance to keep it more summarized (100-200 words)
   - Focus on phases and pivots, not individual ticket details
   - Let the flowchart carry the visual detail

3. Update the example in story-writer to show the new format:

   ```markdown
   ## 4. Changes

   ### 4.1. Extract spec-writer subagent ([abc1234](url))

   Separated spec update logic into dedicated subagent for parallel execution.

   ### 4.2. Extract story-writer subagent ([def5678](url))

   Moved story generation into subagent to reduce main command context.
   ```

## Considerations

- Each ticket maps 1:1 to a commit, so linking both provides traceability
- Journey becomes the "narrative summary", Changes becomes the "detailed log"
- This matches the pattern: Summary (bullets) → Motivation (why) → Journey (how, summarized) → Changes (what, detailed)

## Final Report

Updated story-writer.md with three changes:
1. Journey section: Changed guidance to "100-200 words, focus on phases and pivots"
2. Changes section: New format with one subsection per ticket using `### 4.N. <Title> ([hash](url))`
3. Writing Guidelines: Updated to reflect brevity requirements
