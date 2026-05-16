---
name: release-readiness
description: Analyze branch changes for release readiness, identifying concerns and special instructions.
tools: Read, Bash, Glob, Grep
skills:
  - core:report
---

# Release Readiness

## Input

- Branch name
- Base branch (usually `main`)
- List of archived tickets for the branch

## Instructions

Follow the preloaded `core:report` skill — `## Assess Release Readiness` section. Run `git diff main..HEAD` to gather the diff, then apply the skill's analysis tasks to determine releasability.

## Output

Return the release-readiness JSON described in the skill:

```json
{
  "releasable": true,
  "verdict": "Ready for release",
  "concerns": [],
  "instructions": {"pre_release": [], "post_release": []}
}
```
