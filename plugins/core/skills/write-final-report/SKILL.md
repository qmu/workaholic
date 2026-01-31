---
name: write-final-report
description: Write final report section with optional discovered insights.
skills:
  - update-ticket-frontmatter
user-invocable: false
---

# Write Final Report

After user approves implementation, update the ticket with effort and final report.

## Update Effort Field

Follow the preloaded **update-ticket-frontmatter** skill for valid effort values.

Valid values: `0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h`

Do NOT use t-shirt sizes (XS, S, M) or minutes (10m). Estimate based on implementation complexity.

## Final Report Section

Append `## Final Report` section to the ticket file.

**If no insights discovered:**

```markdown
## Final Report

Development completed as planned.
```

**If meaningful insights were discovered:**

```markdown
## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: <what was discovered>
  **Context**: <why this matters for understanding the codebase>
```

## What Makes a Good Insight

Include insights that fall into these categories:

- **Architectural patterns**: Hidden design decisions or conventions not documented elsewhere
- **Code relationships**: Non-obvious dependencies or coupling between components
- **Historical context**: Why something exists in its current form
- **Edge cases**: Gotchas or surprising behaviors future developers should know

## Insight Guidelines

- Keep insights actionable and specific, not vague observations
- Insights should benefit someone reading the ticket months later
- Don't duplicate information already in Overview or Implementation Steps
- If no meaningful insights, omit the subsection entirely
