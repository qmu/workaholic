---
created_at: 2026-01-27T01:17:34+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category:
---

# Fix Decision Review format in story-writer to match performance-analyst output

## Overview

The story-writer agent produces stories where section 6.2 Decision Review lacks the proper table format. The performance-analyst.md correctly specifies output as a markdown table with 5 dimensions (Consistency, Intuitivity, Describability, Agility, Density), followed by Strengths and Areas for Improvement sections.

Previous stories (e.g., feat-20260126-131531.md, feat-20260124-200439.md) have the correct table format:

```markdown
| Dimension      | Rating   | Notes                                                   |
| -------------- | -------- | ------------------------------------------------------- |
| Consistency    | Strong   | All tickets followed the same pattern...                |
| Intuitivity    | Strong   | Naming choices align with common conventions            |
| Describability | Strong   | Converged on cleaner naming: ...                        |
| Agility        | Strong   | Moved unfinished work to icebox appropriately           |
| Density        | Adequate | Changes span related concerns; could have been...       |
```

The newly generated story (feat-20260126-214833.md) has only prose sections without the table. The story-writer agent instruction simply says "Include the subagent's complete output in section 6.2" without showing the expected table format.

## Key Files

- `plugins/core/agents/story-writer.md` - Story generation instructions need to explicitly show the expected table format in section 6.2
- `plugins/core/agents/performance-analyst.md` - Reference for the correct output format (already correct)

## Implementation Steps

1. Update `plugins/core/agents/story-writer.md` section 5 (Write Story Content) to show the expected table format in section 6.2 Decision Review
2. Include the full expected structure: table with 5 dimensions + Strengths + Areas for Improvement

## Considerations

- The performance-analyst output format is already correctly specified; the issue is that story-writer doesn't reinforce this format expectation
- Showing the expected format in story-writer helps ensure the subagent output is properly incorporated
