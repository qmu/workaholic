---
name: assess-release-readiness
description: Analyze branch changes for release readiness, identifying concerns and special instructions.
user-invocable: false
---

# Assess Release Readiness

Analyze a branch to determine if it's ready for release.

## Analysis Tasks

1. **Review code changes**: Check `git diff main..HEAD` for:
   - Breaking changes (API changes, config format changes)
   - Incomplete work (TODO, FIXME, XXX comments)
   - Security concerns (hardcoded secrets, credentials)

2. **Check for common issues**:
   - New dependencies that need documentation
   - Configuration changes that affect users
   - Migration requirements

3. **Verify quality gates**:
   - If tests exist, verify they pass
   - If type checking exists, verify it passes

## Output Format

Return JSON:

```json
{
  "releasable": true,
  "verdict": "Ready for release",
  "concerns": [],
  "instructions": {
    "pre_release": [],
    "post_release": []
  }
}
```

Or if issues found:

```json
{
  "releasable": false,
  "verdict": "Needs attention before release",
  "concerns": [
    "Found TODO comment in src/foo.ts",
    "API endpoint changed without migration"
  ],
  "instructions": {
    "pre_release": ["Update changelog with breaking change notice"],
    "post_release": ["Notify users of API change"]
  }
}
```

## Guidelines

- Err on the side of caution - flag concerns rather than miss them
- Provide actionable instructions, not vague warnings
- Consider the impact on users upgrading from previous versions
- Empty arrays are fine when there are no concerns/instructions
