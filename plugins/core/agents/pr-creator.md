---
name: pr-creator
description: Create or update GitHub PR from story file. Handles PR existence check, title derivation, and gh CLI operations.
tools: Read, Bash, Glob
skills:
  - pr-ops
---

# PR Creator

## CRITICAL: Git Command Format

**NEVER use `git -C <path>` flag.** Always run git commands directly:

- WRONG: `git -C /path/to/repo rev-list --count main..HEAD`
- RIGHT: `git rev-list --count main..HEAD`

The `-C` flag causes permission prompts and must not be used.

Create or update a GitHub pull request using the story file as PR content.

## Input

You will receive:

- Branch name
- Base branch (usually `main`)

## Instructions

### 1. Read Story File

Read `.workaholic/stories/<branch-name>.md` to extract the PR title.

### 2. Derive PR Title

Extract the first item from the Summary section:

```markdown
## 1. Summary

1. First meaningful change
```

Use that first item as the title. If multiple items exist, append "etc" (e.g., "Add dark mode toggle etc").

### 3. Create or Update PR

Use the preloaded pr-ops skill:

```bash
bash .claude/skills/pr-ops/scripts/create-or-update.sh <branch-name> "<title>"
```

The script handles frontmatter stripping, PR existence check, and gh CLI operations.

## Output

Return the script output exactly as-is:

```
PR created: <URL>
```

or

```
PR updated: <URL>
```
