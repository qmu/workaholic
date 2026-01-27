---
created_at: 2026-01-27T16:37:20+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Simplify topic tree and move to Journey section

## Overview

The current topic tree in section "0. Topic Tree" is overly complex (using Mermaid mindmap syntax with multiple levels) and placed as a standalone section. This ticket moves the topic tree into section 3 (Journey) as a supporting visual reference, and simplifies it from a mindmap to a basic Mermaid flowchart.

The goal is to make the topic tree a "helping information material" within the Journey narrative rather than a prominent standalone section. A simple flowchart showing ticket relationships is easier to read and maintain than a multi-level mindmap.

## Key Files

- `plugins/core/agents/story-writer.md` - Main agent that defines story structure and topic tree generation

## Related History

Past tickets that touched similar areas:

- `20260127100459-add-topic-tree-to-story.md` - Added the original topic tree section (same file)
- `20260127011734-fix-story-decision-review-format.md` - Modified story-writer format (same file)
- `20260127004417-story-writer-subagent.md` - Created the story-writer agent (same file)
- `20260124120158-enforce-mermaid-for-diagrams.md` - Established Mermaid diagram policy (same layer)

## Implementation Steps

1. Update `plugins/core/agents/story-writer.md`:

   - Remove section "## 0. Topic Tree" as a standalone section
   - Renumber sections: 1 → 0, 2 → 1, 3 → 2, 4 → 3, 5 → 4, 6 → 5, 7 → 6
   - Add a simple Mermaid flowchart at the end of section 2 (formerly section 3: Journey) as a visual aid

2. Change the diagram from mindmap to a simple flowchart grouped by **concern/purpose/decision process**:

   ```mermaid
   flowchart TD
     subgraph Subagents[Subagent Architecture]
       sync --> story --> changelog --> pr-creator
     end
     subgraph GitSafety[Git Command Safety]
       guidelines --> strengthen --> embed --> deny-rule
     end
     subgraph Skills[Skill Extraction]
       changelog-skill & story-metrics & spec-context & pr-ops
     end
   ```

3. Update diagram guidelines:
   - Use `flowchart TD` (top-down) for clarity
   - **Group by concern/purpose**: Each subgraph represents one goal or decision area
   - Show decision-making flow with arrows (A tried, then B, then C)
   - Parallel work shown with `&` syntax (no arrows between independent items)
   - Maximum 3-5 subgraphs per diagram
   - Labels: max 20 characters, use abbreviated names

4. Remove all the complex mindmap syntax instructions:
   - Delete Chain Detection section
   - Delete Pivot Detection Phrases section
   - Delete Theme Identification section
   - Delete Mindmap Syntax section
   - Delete Depth Guidelines table
   - Replace with simpler flowchart guidelines

## Considerations

- The flowchart is intentionally simpler than the mindmap - it's a quick visual aid, not a comprehensive diagram
- GitHub renders Mermaid flowcharts just like mindmaps
- Existing stories with mindmap syntax will continue to render correctly (no need to update them)
- The placement in Journey section emphasizes it as context for the narrative, not a separate deliverable
