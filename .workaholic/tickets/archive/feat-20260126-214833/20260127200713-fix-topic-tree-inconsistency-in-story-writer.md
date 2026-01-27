---
created_at: 2026-01-27T20:07:13+09:00
author: a@qmu.jp
type: bug
layer: [Config]
effort: 10m
commit_hash: edea513---
category: Changed
# Fix topic tree inconsistency between story-writer template and output

## Overview

The `story-writer.md` template shows the Topic Flowchart as a subsection `#### Topic Flowchart` inside the Journey section (section 3), but the agent actually generates it as `## 0. Topic Tree` at the top of the story.

This inconsistency originated from ticket `20260127163720-simplify-topic-tree-as-journey-reference.md` where the plan was to move the topic tree into Journey, but the Final Report says "Kept Topic Tree as section 0" - deviating from the plan without updating the template in story-writer.md to match.

The template (lines 99-116) says one thing, the actual output does another. Either:
1. Move Topic Tree into Journey as `#### Topic Flowchart` (matching template), or
2. Update template to show `## 0. Topic Tree` (matching actual behavior)

Option 2 is recommended since the current behavior (section 0 at top) provides good visual overview for PR reviewers.

## Key Files

- `plugins/core/agents/story-writer.md` - Template shows `#### Topic Flowchart` in Journey but agent generates `## 0. Topic Tree`

## Related History

Past tickets that touched similar areas:

- `20260127163720-simplify-topic-tree-as-journey-reference.md` - Deviated from plan, kept section 0 (same file)
- `20260127100459-add-topic-tree-to-story.md` - Added original topic tree as section 0 (same file)
- `20260127011734-fix-story-decision-review-format.md` - Modified story-writer format (same file)

## Implementation Steps

1. Update `plugins/core/agents/story-writer.md` section "### 5. Write Story Content":

   - Move the `#### Topic Flowchart` block (lines 99-123) to appear as section 0 before Summary
   - Change from `#### Topic Flowchart` to `## 0. Topic Tree`
   - Add the flowchart at the story start, not inside Journey section
   - Keep the flowchart guidelines where they are (they apply to the section 0 diagram)

2. Update the template structure to show:
   ```markdown
   ## 0. Topic Tree

   ```mermaid
   flowchart LR
     ...
   ```

   ## 1. Summary
   ...

   ## 3. Journey

   [Narrative only, no embedded flowchart]
   ```

3. Verify the Journey section (now containing only narrative) does not duplicate the flowchart

## Considerations

- The current behavior (section 0) is actually preferable for PR readability
- The fix is just aligning documentation with reality
- No changes needed to existing story files - they already have section 0
