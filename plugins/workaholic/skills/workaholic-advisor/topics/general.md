# General Rules

Best practices for `.claude/rules/general.md` with project-wide rules.

## Rule File Format

Rules support YAML frontmatter with `paths` for path-specific rules:

```yaml
---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---

# Rule Title

- **Rule name** - Rule description
```

Rules without `paths` frontmatter apply globally to all files.

## When to Propose

- Project has no general rules in `.claude/rules/`
- User wants to enforce commit confirmation

## Rule Content

The general rules file should include:

- **Commit permission** - Never commit without explicit user confirmation

## Template

See `../templates/general-rules.md`
