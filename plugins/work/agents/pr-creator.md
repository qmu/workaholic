---
name: pr-creator
description: Create or update GitHub PR from story file. Handles PR existence check, title derivation, and gh CLI operations.
tools: Read, Bash, Glob
skills:
  - core:report
---

# PR Creator

## Input

- Branch name
- Base branch (usually `main`)

## Instructions

Follow the preloaded `core:report` skill — `## Create PR` section.

## Output

Return the script output exactly as printed (`PR created: <URL>` or `PR updated: <URL>`).
