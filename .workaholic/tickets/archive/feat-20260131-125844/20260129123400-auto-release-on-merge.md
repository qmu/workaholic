---
created_at: 2026-01-29T12:34:00+09:00
author: noreply@anthropic.com
type: enhancement
layer: [Infrastructure]
effort: 0.5h
commit_hash: ad07ecd
category: Added
---

# Add Automatic Release Trigger on Story Branch Merge

## Problem

Currently, releases are only triggered manually via `workflow_dispatch`. After a story branch (e.g., `feat-*`, `fix-*`, `refact-*`) is merged into main via PR, the maintainer must manually trigger the release workflow. This adds friction and delays between merge and release.

## Solution

Add a `push` trigger to the existing release workflow that fires when story branches are merged into main. The trigger should:

1. Detect when a PR merge commit lands on main
2. Automatically determine version type based on branch prefix:
   - `feat-*` → minor bump
   - `fix-*` → patch bump
   - `refact-*` → patch bump
3. Run the same release process (version bump, release notes, GitHub Release)

## Key Files

- `.github/workflows/release.yml` - Existing release workflow to modify

## Requirements

### Trigger Configuration

Add `push` trigger to release.yml that fires only on main branch:
```yaml
on:
  push:
    branches:
      - main
  workflow_dispatch:
    # ... existing manual trigger
```

### Version Type Detection

Add a new step before "Calculate new version" that determines version_type from the merge commit or branch name:

```yaml
- name: Detect version type from merge
  id: detect
  if: github.event_name == 'push'
  run: |
    # Get the merge commit message to extract branch name
    commit_msg=$(git log -1 --pretty=%s)

    # Check if this is a merge commit from a story branch
    if echo "$commit_msg" | grep -qE "Merge pull request.*from.*/feat-"; then
      echo "version_type=minor" >> $GITHUB_OUTPUT
    elif echo "$commit_msg" | grep -qE "Merge pull request.*from.*/(fix|refact)-"; then
      echo "version_type=patch" >> $GITHUB_OUTPUT
    else
      echo "skip=true" >> $GITHUB_OUTPUT
    fi
```

### Skip Non-Story Merges

The workflow should skip release creation for:
- Direct pushes to main (not PR merges)
- Merges from non-story branches
- Release commits (to avoid infinite loop)

Add condition to the release job:
```yaml
jobs:
  release:
    runs-on: ubuntu-latest
    if: |
      github.event_name == 'workflow_dispatch' ||
      (github.event_name == 'push' && !startsWith(github.event.head_commit.message, 'Release v'))
```

### Update Version Calculation Step

Modify the "Calculate new version" step to use detected version_type for push events:
```yaml
- name: Calculate new version
  id: version
  run: |
    # Use detected version_type for push events, input for workflow_dispatch
    if [ "${{ github.event_name }}" = "push" ]; then
      version_type="${{ steps.detect.outputs.version_type }}"
    else
      version_type="${{ inputs.version_type }}"
    fi
    # ... rest of calculation
```

## Implementation Notes

- Keep `workflow_dispatch` trigger for manual releases (major bumps, hotfixes)
- Feature branches (`feat-*`) get minor bumps since they add functionality
- Fix and refactor branches get patch bumps since they don't add features
- Skip release if the push is not a story branch merge (direct pushes, maintenance)
- Avoid release loop by checking commit message doesn't start with "Release v"

## Related History

- `.workaholic/tickets/archive/feat-20260129-023941/20260129140000-add-release-github-action.md` - Original GitHub Action for automated release (current implementation)
- `.workaholic/tickets/archive/feat-20260126-214833/20260127205856-add-release-preparation-to-story.md` - Release readiness analysis in story command

## Final Report

Development completed as planned.

**Changes Made**:
- Added push trigger for main branch to `.github/workflows/release.yml`
- Added version type detection from merge commit message (feat-* → minor, fix-*/refact-* → patch)
- Added skip logic for non-story branch merges and release commits (infinite loop prevention)
- Updated version calculation to use detected type for push events
- Added conditional execution to all release steps
