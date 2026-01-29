---
created_at: 2026-01-29T02:34:35+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.25h
commit_hash: f2e4e24
category: Changed
---

# Focus Release Readiness on Practical Concerns

## Overview

The release-readiness skill currently focuses on theoretical concerns like "breaking changes" that don't matter to actual users. For a plugin marketplace where users pull the latest version, command renames aren't real concerns - users just learn the new command. Update the skill to focus on concerns that actually block releases or require real action.

## Key Files

- `plugins/core/skills/assess-release-readiness/SKILL.md` - Update analysis focus

## Related History

The release-readiness feature was added to provide actionable guidance before releases.

Past tickets that touched similar areas:

- [20260127205856-add-release-preparation-to-story.md](.workaholic/tickets/archive/feat-20260126-214833/20260127205856-add-release-preparation-to-story.md) - Added release preparation section to stories

## Implementation Steps

1. Update `plugins/core/skills/assess-release-readiness/SKILL.md`:

   Replace the current "Breaking changes" analysis with practical concerns:

   ```markdown
   ## Analysis Tasks

   1. **Review code changes**: Check `git diff main..HEAD` for:
      - Incomplete work (TODO, FIXME, XXX comments in new code)
      - Security concerns (hardcoded secrets, credentials)
      - Runtime errors or obvious bugs

   2. **Check for blocking issues**:
      - Tests failing (if tests exist)
      - Type errors (if type checking exists)
      - Missing files referenced in code

   3. **Identify actionable items** (not theoretical concerns):
      - Documentation that needs updating
      - Version numbers to bump
      - Files to stage/commit before release

   ## What NOT to Flag

   - "Breaking changes" for command renames - users adapt
   - API changes in a plugin - plugins are configuration, not APIs
   - Internal refactoring - doesn't affect users
   - Theoretical upgrade concerns - users pull fresh versions
   ```

2. Update the Guidelines section:
   ```markdown
   ## Guidelines

   - Focus on issues that actually block releases
   - Provide actionable instructions, not theoretical warnings
   - "Breaking change" is rarely a real concern for plugins
   - Empty concerns array is the happy path, not a failure
   - If it doesn't require action, don't flag it
   ```

## Considerations

- This is a philosophy shift: from cautious flagging to pragmatic assessment
- Workaholic is a plugin marketplace, not a library with semver guarantees
- Users always get the latest version - there's no "upgrade path" concern
- The goal is actionable release prep, not risk documentation

## Final Report

Development completed as planned.
