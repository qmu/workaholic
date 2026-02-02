---
created_at: 2026-02-02T20:41:11+09:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
effort:
commit_hash:
category:
---

# Fix Release Action Trigger on PR Merge

## Overview

The Release GitHub Action is being skipped when PRs are merged because the trigger condition now only fires on "Bump version to v" commits. This prevents release notes from being updated. The action should be invoked on PR merge to update release notes, while still not bumping the version.

## Key Files

- `.github/workflows/release.yml` - Release workflow with current trigger condition (line 16-18)

## Related History

Previous tickets established the current release workflow architecture:

- [20260202134528-remove-version-bump-from-story.md](.workaholic/tickets/archive/drive-20260202-134332/20260202134528-remove-version-bump-from-story.md) - Removed version bumping from GitHub Action, but made trigger too restrictive
- [20260129123400-auto-release-on-merge.md](.workaholic/tickets/archive/feat-20260131-125844/20260129123400-auto-release-on-merge.md) - Added automatic release trigger on PR merge
- [20260201112308-fix-release-default-to-patch.md](.workaholic/tickets/archive/drive-20260201-112920/20260201112308-fix-release-default-to-patch.md) - Moved version bumping to /story command

## Implementation Steps

1. **Update trigger condition** in `.github/workflows/release.yml`:
   - Current: Only runs on "Bump version to v" commits (too restrictive)
   - New: Run on any merge commit from topic branches (drive-*, trip-*) OR on "Bump version to v" commits

2. **Modify the `if` condition** (lines 16-18):
   ```yaml
   # Before
   if: |
     github.event_name == 'workflow_dispatch' ||
     (github.event_name == 'push' && startsWith(github.event.head_commit.message, 'Bump version to v'))

   # After
   if: |
     github.event_name == 'workflow_dispatch' ||
     (github.event_name == 'push' && (
       startsWith(github.event.head_commit.message, 'Bump version to v') ||
       contains(github.event.head_commit.message, 'Merge pull request')
     ))
   ```

3. **Update release existence check**: The existing check at lines 32-42 already handles skipping if a release for the current version exists, so no changes needed there.

## Considerations

- The workflow should still not bump versions (that happens in /story command)
- Release notes should be updated from commit history since the last tag
- If release already exists for the current version, the workflow will skip creation (existing logic handles this)
- The workflow reads version from marketplace.json, so it will create/update release for whatever version is current
