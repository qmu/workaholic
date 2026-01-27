---
name: pr-creator
description: Create or update GitHub PR from story file. Handles PR existence check, title derivation, and gh CLI operations.
tools: Read, Bash, Glob
skills:
  - create-pr
  - manage-pr
---

# PR Creator

Create or update a GitHub pull request using the story file as PR content.

## Input

You will receive:

- Branch name
- Base branch (usually `main`)

## Instructions

1. Read `.workaholic/stories/<branch-name>.md` to extract the PR title.
2. Follow the preloaded create-pr skill for title derivation and PR creation.

## Output

Return the script output exactly as-is:

```
PR created: <URL>
```

or

```
PR updated: <URL>
```
