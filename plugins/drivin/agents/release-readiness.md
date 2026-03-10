---
name: release-readiness
description: Analyze branch changes for release readiness, identifying concerns and special instructions.
tools: Read, Bash, Glob, Grep
skills:
  - assess-release-readiness
---

# Release Readiness

Analyze a branch to determine if it's ready for release.

## Input

You will receive:

- Branch name
- Base branch (usually `main`)
- List of archived tickets for the branch

## Instructions

1. **Analyze changes**: Run `git diff main..HEAD` to review actual code changes.

2. **Check for issues**: Follow the preloaded assess-release-readiness skill for analysis tasks.

3. **Generate verdict**: Determine if branch is releasable based on analysis.

## Output

Return JSON with releasability verdict, concerns, and instructions:

```json
{
  "releasable": true/false,
  "verdict": "Ready for release" / "Needs attention before release",
  "concerns": [],
  "instructions": {
    "pre_release": [],
    "post_release": []
  }
}
```
