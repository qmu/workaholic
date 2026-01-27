---
created_at: 2026-01-27T10:05:00+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Add topic tree diagram to story generation

## Overview

Add a Mermaid mindmap diagram to generated stories that visualizes the hierarchy of changes. This "topic tree" shows how tickets and their changes relate to each other, giving reviewers a quick visual overview before reading the detailed narrative.

## Key Files

- `plugins/core/agents/story-writer.md` - Add topic tree section to story content structure

## Implementation Steps

1. Update `plugins/core/agents/story-writer.md` to add a new section "## 0. Topic Tree" at the beginning of story content (before Summary):

   ```markdown
   ## 0. Topic Tree

   ```mermaid
   mindmap
     root((Branch Name))
       Ticket 1 Title
         Change 1
         Change 2
       Ticket 2 Title
         Change 3
   ```
   ```

2. Add instructions for generating the mindmap:
   - Root node: branch name
   - First level: ticket titles (from H1 heading of each archived ticket)
   - Second level: key changes from each ticket (from Implementation Steps or Final Report)
   - Keep labels concise (max 30 chars, truncate with "..." if needed)

## Considerations

- Mermaid mindmap syntax is simple: indentation defines hierarchy
- The tree provides a "table of contents" visual that complements the numbered Summary list
- For branches with many tickets, the tree may become large - consider limiting to top 5-6 tickets
- GitHub renders Mermaid diagrams natively in PR descriptions
