---
name: pr-ops
description: Create or update GitHub PR using story file as body.
allowed-tools: Bash
user-invocable: false
---

# PR Operations

Create or update a GitHub pull request.

## When to Use

Use this skill after deriving a PR title to create or update the PR. The script handles all gh CLI operations.

## Instructions

Run the bundled script:

```bash
bash .claude/skills/pr-ops/sh/create-or-update.sh <branch-name> "<title>"
```

### What the Script Does

1. Strips YAML frontmatter from `.workaholic/stories/<branch-name>.md`
2. Writes clean content to `/tmp/pr-body.md`
3. Checks if PR exists for the branch
4. Creates new PR or updates existing one
5. Outputs the result in required format

### Output

Exactly one line:

```
PR created: <URL>
```

or

```
PR updated: <URL>
```

This output format is required by the report command.
