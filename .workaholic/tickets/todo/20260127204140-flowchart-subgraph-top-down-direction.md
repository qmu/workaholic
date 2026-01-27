---
created_at: 2026-01-27T20:41:40+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Use top-to-bottom direction inside flowchart subgraphs

## Overview

The Journey section in stories contains a Mermaid flowchart where subgraphs are arranged left-to-right (LR), but the items inside each subgraph also flow left-to-right. This makes long chains within subgraphs hard to read.

This ticket changes the flowchart so that items **inside** subgraphs flow top-to-bottom (TB), while the subgraphs themselves remain arranged left-to-right. This creates a more readable layout where:
- Subgraphs progress horizontally (timeline of work phases)
- Items within each subgraph progress vertically (evolution within a phase)

## Key Files

- `plugins/core/agents/story-writer.md` - Contains the flowchart template and guidelines

## Related History

Past tickets that touched similar areas:

- `20260127203050-fix-topic-tree-in-journey-section.md` - Moved Topic Tree into Journey section (same file)
- `20260127163720-simplify-topic-tree-as-journey-reference.md` - Changed from mindmap to flowchart (same file)
- `20260127100459-add-topic-tree-to-story.md` - Added the original topic tree section (same file)

## Implementation Steps

1. Update the example flowchart in `plugins/core/agents/story-writer.md`:
   - Keep `flowchart LR` at the top level
   - Add `direction TB` as the first line inside each `subgraph` block
   - Adjust the example to demonstrate vertical flow within subgraphs

2. Update the Flowchart Guidelines section:
   - Change "Use `flowchart LR` (left-to-right) for timeline visualization" to explain the two-direction approach
   - Add guideline: "Use `direction TB` inside each subgraph for vertical item flow"

3. Example of the new format:
   ```mermaid
   flowchart LR
     subgraph Subagents[Subagent Architecture]
       direction TB
       s1[Extract spec-writer] --> s2[Extract story-writer] --> s3[Extract changelog-writer] --> s4[Extract pr-creator]
     end

     subgraph GitSafety[Git Command Safety]
       direction TB
       g1[Add git guidelines] --> g2[Strengthen rules] --> g3[Embed in agents] --> g4[Use deny rule]
     end

     Subagents --> GitSafety
   ```

## Considerations

- This is a template change; existing stories with the old format will continue to render correctly
- The `direction TB` directive must be the first line inside each subgraph
- Items connected with `&` (parallel work) will still display side-by-side within the vertical flow
