---
created_at: 2026-02-12T12:32:09+08:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.1h
commit_hash:
category:
---

# Prevent Double Version Bump When /report Runs Twice in Same Branch

## Overview

The `/report` command unconditionally bumps the version as its first step. When `/report` is called multiple times in the same branch (for example, to update the PR after additional commits), the version gets bumped each time. A branch that should produce one version increment ends up producing two or more. The fix is to make the version bump idempotent: skip the bump if a "Bump version" commit already exists in the current branch since it diverged from main.

## Key Files

- `plugins/core/commands/report.md` - The report command that unconditionally bumps version in step 1 (line 14)
- `.claude-plugin/marketplace.json` - Root marketplace version file that gets incremented
- `plugins/core/.claude-plugin/plugin.json` - Plugin version file that gets incremented in sync
- `plugins/core/skills/manage-branch/sh/check.sh` - Existing skill pattern for shell-based branch inspection

## Related History

The version bump location has oscillated between the GitHub Action and the /story (now /report) command across several iterations, with each move solving one double-bump scenario while leaving others open. This ticket addresses the remaining case: re-running /report within the same branch.

Past tickets that touched similar areas:

- [20260208133008-add-version-bump-to-story-command.md](.workaholic/tickets/archive/drive-20260208-131649/20260208133008-add-version-bump-to-story-command.md) - Added the version bump step to /report (the step that now causes the double bump)
- [20260202134528-remove-version-bump-from-story.md](.workaholic/tickets/archive/drive-20260202-134332/20260202134528-remove-version-bump-from-story.md) - Removed version bumping from GitHub Action to avoid double increments between /story and CI
- [20260202204111-fix-release-action-trigger-on-merge.md](.workaholic/tickets/archive/drive-20260202-203938/20260202204111-fix-release-action-trigger-on-merge.md) - Changed release action to version-comparison approach, decoupling it from commit message matching
- [20260201112308-fix-release-default-to-patch.md](.workaholic/tickets/archive/drive-20260201-112920/20260201112308-fix-release-default-to-patch.md) - Original addition of version bump to /story command with patch default

## Implementation Steps

1. **Create a `check-version-bump.sh` skill script** in `plugins/core/skills/manage-branch/sh/` (or a new `manage-version` skill) that checks whether a "Bump version" commit already exists in the current branch since diverging from main. The script should output JSON: `{"already_bumped": true/false}`.

2. **Update `plugins/core/commands/report.md`** step 1 to run the check script first. If the version has already been bumped in this branch, skip the bump step. Otherwise, proceed with the bump as usual.

## Patches

### `plugins/core/commands/report.md`

```diff
--- a/plugins/core/commands/report.md
+++ b/plugins/core/commands/report.md
@@ -12,5 +12,5 @@ Generate story and create or update a pull request for the current branch.

 ## Instructions

-1. **Bump version** following CLAUDE.md Version Management section (patch increment)
+1. **Bump version** following CLAUDE.md Version Management section (patch increment). **Skip if a "Bump version" commit already exists in the current branch** (check with `bash .claude/skills/manage-branch/sh/check-version-bump.sh`; if `already_bumped` is `true`, skip this step).
 2. **Invoke story-writer** (`subagent_type: "core:story-writer"`, `model: "opus"`)
```

> **Note**: The exact wording in report.md may need adjustment depending on whether the check is extracted to a dedicated skill or kept inline. The patch above shows the conceptual change.

## Considerations

- The check script should use `git log main..HEAD --oneline --grep="Bump version"` to detect existing bump commits, following the shell script principle from CLAUDE.md rather than inline conditionals in the command markdown (`plugins/core/commands/report.md`)
- The `/release` command (`.claude/commands/release.md`) is a separate manual command for major/minor bumps and should remain unaffected by this change
- The GitHub Actions release workflow (`.github/workflows/release.yml`) already handles duplicate releases by comparing the version in `marketplace.json` against the latest GitHub release tag, so it is not affected
- If a developer runs `/report`, then makes more commits, then runs `/report` again, the version will correctly not bump again since the original bump commit is still in the branch history. This is the desired behavior since the version was already incremented once for this PR
- Edge case: if a developer manually reverts a version bump commit and then runs `/report`, the check would correctly find no bump commit and proceed with a fresh bump (`plugins/core/skills/manage-branch/sh/check-version-bump.sh`)

## Final Report

Implementation followed the ticket plan exactly:

1. Created `plugins/core/skills/manage-branch/sh/check-version-bump.sh` — uses `git log main..HEAD --oneline --grep="Bump version"` to detect existing bump commits and outputs JSON `{"already_bumped": true/false}`.
2. Updated `plugins/core/commands/report.md` step 1 to run the check script first and skip the bump when `already_bumped` is `true`.
