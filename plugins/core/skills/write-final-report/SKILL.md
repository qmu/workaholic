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

Estimate the actual time this implementation took, then round to the nearest valid value.

**The ONLY valid values are:** `0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h`

Do NOT use t-shirt sizes (S/M/L/XS/XL), minutes (10m/30m), or any other format. The `update.sh` script will reject invalid values.

**Valid values (hour-based only):**

| Value | Use For |
|-------|---------|
| `0.1h` | Trivial changes (typo fix, config tweak) |
| `0.25h` | Simple changes (add field, update text) |
| `0.5h` | Small feature or fix (new function, bug fix) |
| `1h` | Medium feature (new component, refactor) |
| `2h` | Large feature (new workflow, significant refactor) |
| `4h` | Very large feature (new system, major rewrite) |

ALWAYS use one of these exact values: `0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h`

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
