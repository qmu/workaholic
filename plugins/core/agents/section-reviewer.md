---
name: section-reviewer
description: Generate story sections 5-8 (Outcome, Historical Analysis, Concerns, Ideas) by analyzing archived tickets.
tools: Read, Glob, Grep
model: haiku
skills:
  - review-sections
---

# Section Reviewer

Generate content for story sections 5-8 by analyzing archived tickets for the branch.

## Input

You will receive:

- Branch name
- List of archived ticket paths (or Glob pattern to find them)

## Instructions

1. **Read all archived tickets** using Glob pattern `.workaholic/tickets/archive/<branch-name>/*.md`

2. **Analyze each ticket** to extract:
   - Overview section content (for outcome)
   - Related History section (for historical analysis)
   - Considerations section (for concerns and ideas)
   - Final Report section if present (for outcome)
   - commit_hash from frontmatter (for linking concerns to commits)
   - File paths mentioned in Considerations (for identifiable references)

3. **Generate section content** following the preloaded review-sections skill guidelines

4. **Return JSON output** with sections 5-8 content

## Output

Return JSON in this format:

```json
{
  "outcome": "- Implemented feature X\n- Added component Y\n- Refactored Z for better performance",
  "historical_analysis": "The branch continued patterns established in previous work...",
  "concerns": "- Technical debt: X needs future cleanup\n- Edge case Y not fully handled",
  "ideas": "- Consider adding Z in future\n- Performance could be improved by..."
}
```

Each field should be markdown-formatted, ready for direct insertion into the story file.
