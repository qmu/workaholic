---
created_at: 2026-02-02T13:45:11+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort: 0.25h
commit_hash: 3afc40f
category: Removed
---

# Remove version bump from GitHub Action

## Overview

The GitHub Actions workflow performs version bumping on PR merge, conflicting with the `/story` command's version bumping. This causes double increments (e.g., v1.0.26 → v1.0.28 instead of v1.0.27).

The solution is to keep version bumping in `/story` (Claude Code) and make the GitHub Action only create releases without version manipulation.

## Key Files

- `.github/workflows/release.yml` - Contains version calculation and bump steps that need removal
- `plugins/core/commands/story.md` - Keeps the version bump step (step 5)

## Related History

- [20260201112308-fix-release-default-to-patch.md](.workaholic/tickets/archive/drive-20260201-112920/20260201112308-fix-release-default-to-patch.md) - Added version bump to /story command
- [20260129123400-auto-release-on-merge.md](.workaholic/tickets/archive/feat-20260131-125844/20260129123400-auto-release-on-merge.md) - Added auto-release on merge

## Implementation Steps

1. **Simplify GitHub Action trigger**: Only run on "Bump version to v" commits (created by /story)
2. **Remove version calculation**: Read version from marketplace.json instead of calculating
3. **Remove version file updates**: /story already updates the version files
4. **Remove commit step**: No version changes to commit
5. **Add release existence check**: Skip if release already exists

## Considerations

- Version bumping now happens in Claude Code via /story, included in PR diff
- GitHub Action only creates the GitHub Release artifact
- workflow_dispatch allows manual release creation if needed

## Final Report

Simplified the GitHub Actions release workflow to remove version bumping. The workflow now only triggers on "Bump version to v" commits (created by /story) and creates a GitHub Release using the version already in marketplace.json. Added a check to skip if release already exists.
