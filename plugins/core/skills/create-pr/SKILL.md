---
name: create-pr
description: Create or update GitHub PR from story file with proper title derivation.
allowed-tools: Bash
user-invocable: false
---

# Create PR

Create or update a GitHub pull request using the story file as PR content.

## Derive PR Title

Extract the first item from the Summary section of the story file:

```markdown
## 1. Summary

1. First meaningful change
```

Use that first item as the title. If multiple items exist, append "etc" (e.g., "Add dark mode toggle etc").

## Create or Update PR

Run the bundled script:

```bash
bash .claude/skills/create-pr/sh/create-or-update.sh <branch-name> "<title>"
```

### What the Script Does

1. Strips YAML frontmatter from `.workaholic/stories/<branch-name>.md`
2. Writes clean content to `/tmp/pr-body.md`
3. Checks if PR exists for the branch
4. Creates new PR or updates existing one
5. Outputs the result in required format

## Output Format

Exactly one line:

```
PR created: <URL>
```

or

```
PR updated: <URL>
```

This output format is required by the report command.
