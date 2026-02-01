# Fix Release to Default to Patch Version Bump

## Overview

The release workflow incorrectly defaults to `minor` for automatic releases, causing v1.0.0 to become v1.1.0 when it should have been v1.0.1. Fix by:
1. Updating GitHub Actions workflow to default to `patch`
2. Moving version bumping into `/story` command where it belongs

## Key Files

- `.github/workflows/release.yml` - Auto-release workflow (lines 43-46 hardcode minor)
- `plugins/core/commands/story.md` - Story command that prepares PR
- `.claude/commands/release.md` - Manual release command (correctly documents patch default)
- `.claude-plugin/marketplace.json` - Marketplace version file
- `plugins/core/.claude-plugin/plugin.json` - Core plugin version file
- `plugins/tdd/.claude-plugin/plugin.json` - TDD plugin version file

## Implementation

### 1. Update GitHub Actions Workflow

In `.github/workflows/release.yml`, change the auto-detection logic (lines 43-46):

```yaml
# Before
if echo "$commit_msg" | grep -qE "Merge pull request.*from.*/(drive|trip)-"; then
  echo "Detected drive/trip branch merge -> minor bump"
  echo "version_type=minor" >> $GITHUB_OUTPUT

# After
if echo "$commit_msg" | grep -qE "Merge pull request.*from.*/(drive|trip)-"; then
  echo "Detected drive/trip branch merge -> patch bump"
  echo "version_type=patch" >> $GITHUB_OUTPUT
```

### 2. Add Version Bump Step to Story Command

In `plugins/core/commands/story.md`, add a version bumping step after documentation generation (before push):

Insert after step 4 (format changed files), before step 5 (push branch):

```markdown
5. **Bump version** (patch by default):
   - Read `.claude-plugin/marketplace.json` and parse current version
   - Increment PATCH by 1 (e.g., 1.0.0 → 1.0.1)
   - Update version in all files per CLAUDE.md Version Management:
     - `.claude-plugin/marketplace.json` (root version field)
     - `.claude-plugin/marketplace.json` (each plugin's version in plugins array)
     - `plugins/core/.claude-plugin/plugin.json`
     - `plugins/tdd/.claude-plugin/plugin.json`
   - Stage and commit: "Bump version to v{new_version}"
```

Renumber subsequent steps (push becomes 6, PR creation becomes 7).

## Considerations

- The original workflow assumed all merges warrant minor bumps - incorrect
- Patch should be default; users explicitly declare minor/major when needed
- Moving version bump to /story allows version to be included in PR diff
- GitHub Actions still handles git tag creation after merge

## Related History

- `20260129140000-add-release-github-action.md` - Original workflow
- `20260129123400-auto-release-on-merge.md` - Auto-detection logic (source of bug)
