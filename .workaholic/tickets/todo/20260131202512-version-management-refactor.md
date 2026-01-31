---
effort: medium
category: changed
type: enhancement
author: tamurayoshiya@gmail.com
created_at: 2026-01-31T20:25:12+09:00
---

# Refactor Version Management to Story-Time with PR-Linked Release Notes

## Overview

Move version management from GitHub Actions to `/story` command execution. Add a version-manager subagent running in parallel Phase 1 with a dedicated version management skill. Simplify GitHub Actions to only generate release notes that properly link to the merged pull request.

## Motivation

**Current problems:**

1. Version bumping happens in GitHub Actions **after** PR merge, creating a "Release v..." commit that feels disconnected from the development flow
2. Release notes are poorly generated - just commit messages without PR context
3. The PR itself doesn't know the version it will become until after merge

**Desired state:**

1. Version is bumped during `/story` **before** PR creation, so the PR title/body can include the version
2. GitHub Actions only creates a GitHub Release with proper PR-linked release notes
3. Release notes link to the PR that introduced the changes, not individual commits

## Key Files

- `plugins/core/commands/story.md` - Add version-manager subagent to Phase 1 parallel execution
- `.github/workflows/release.yml` - Simplify to only generate release notes (remove version bumping)
- `plugins/core/skills/manage-version/SKILL.md` - New skill with version management logic
- `plugins/core/agents/version-manager.md` - New subagent using manage-version skill
- `.claude/commands/release.md` - Reference for version management logic (to extract into skill)

## Related History

- `feat-20260129-023941/20260129140000-add-release-github-action.md` - Original GitHub Actions release implementation
- `feat-20260131-125844/20260129123400-auto-release-on-merge.md` - Added automatic release trigger on merge
- `feat-20260126-214833/20260127205856-add-release-preparation-to-story.md` - Added release-readiness to Phase 1

## Implementation

### 1. Create Version Management Skill

Create `plugins/core/skills/manage-version/SKILL.md`:

```markdown
---
name: manage-version
description: Determine version type from branch name and update version files.
allowed-tools: Bash
user-invocable: false
---

# Manage Version

Determine version type from branch prefix and update version in marketplace.json and plugin.json files.

## Version Type Detection

From branch name prefix:
- `feat-*` -> minor bump (1.2.3 -> 1.3.0)
- `fix-*`, `refact-*` -> patch bump (1.2.3 -> 1.2.4)
- `drive-*` -> patch bump (1.2.3 -> 1.2.4)
- Other -> no version bump (skip)

## Version Calculation Script

Run the bundled script to calculate and update version:

```bash
bash .claude/skills/manage-version/sh/update.sh <branch-name>
```

The script:
1. Detects version type from branch prefix
2. Reads current version from `.claude-plugin/marketplace.json`
3. Calculates new version (semantic versioning)
4. Updates version in all required files:
   - `.claude-plugin/marketplace.json` (root version)
   - `.claude-plugin/marketplace.json` (core plugin version in plugins array)
   - `plugins/core/.claude-plugin/plugin.json`
   - `plugins/tdd/.claude-plugin/plugin.json` (if exists)
5. Outputs the new version string

### Output Format

```
<old-version> -> <new-version>
```

Example: `1.0.25 -> 1.1.0`

If no version bump needed, outputs: `skip`
```

### 2. Create Shell Script

Create `plugins/core/skills/manage-version/sh/update.sh`:

```bash
#!/bin/bash
# Update version based on branch prefix

BRANCH_NAME="$1"

if [ -z "$BRANCH_NAME" ]; then
  echo "Usage: $0 <branch-name>" >&2
  exit 1
fi

# Detect version type from branch prefix
if [[ "$BRANCH_NAME" =~ ^feat- ]]; then
  VERSION_TYPE="minor"
elif [[ "$BRANCH_NAME" =~ ^(fix|refact|drive)- ]]; then
  VERSION_TYPE="patch"
else
  echo "skip"
  exit 0
fi

# Read current version
MARKETPLACE_JSON=".claude-plugin/marketplace.json"
CURRENT=$(grep -o '"version": "[^"]*"' "$MARKETPLACE_JSON" | head -1 | cut -d'"' -f4)

# Parse version components
MAJOR=$(echo "$CURRENT" | cut -d. -f1)
MINOR=$(echo "$CURRENT" | cut -d. -f2)
PATCH=$(echo "$CURRENT" | cut -d. -f3)

# Calculate new version
case "$VERSION_TYPE" in
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
esac

NEW="${MAJOR}.${MINOR}.${PATCH}"

# Update marketplace.json root version
sed -i '' "s/\"version\": \"$CURRENT\"/\"version\": \"$NEW\"/" "$MARKETPLACE_JSON"

# Update plugin versions in marketplace.json plugins array
sed -i '' "s/\"version\": \"$CURRENT\"/\"version\": \"$NEW\"/g" "$MARKETPLACE_JSON"

# Update core plugin.json
CORE_PLUGIN="plugins/core/.claude-plugin/plugin.json"
if [ -f "$CORE_PLUGIN" ]; then
  sed -i '' "s/\"version\": \"$CURRENT\"/\"version\": \"$NEW\"/" "$CORE_PLUGIN"
fi

# Update tdd plugin.json if exists
TDD_PLUGIN="plugins/tdd/.claude-plugin/plugin.json"
if [ -f "$TDD_PLUGIN" ]; then
  sed -i '' "s/\"version\": \"$CURRENT\"/\"version\": \"$NEW\"/" "$TDD_PLUGIN"
fi

echo "$CURRENT -> $NEW"
```

### 3. Create Version Manager Subagent

Create `plugins/core/agents/version-manager.md`:

```markdown
---
name: version-manager
description: Update marketplace and plugin versions based on branch type.
skills:
  - manage-version
---

# Version Manager Agent

Update version files based on branch prefix during the /story command.

## Input

- Branch name (to determine version type from prefix)

## Process

1. Run the manage-version skill script with the branch name
2. Report the result (old -> new version, or "skip" if no bump needed)

## Output

Return a concise result:
- Success: "Version updated: 1.0.25 -> 1.1.0"
- Skipped: "Version bump skipped (branch prefix not recognized)"
```

### 4. Update Story Command

Modify `plugins/core/commands/story.md` to add version-manager to Phase 1:

- Change "5 agents" to "6 agents" in Phase 1 description
- Add version-manager to the parallel invocation list
- Commit message for version bump is included in "Update documentation for PR" commit

### 5. Simplify GitHub Actions

Modify `.github/workflows/release.yml`:

**Remove:**
- Version type detection from branch name
- Version calculation and bumping
- Version file updates
- "Release v..." commit

**Keep/Improve:**
- Trigger on tag push (v*) instead of branch merge
- Generate release notes from CHANGELOG.md
- Link to the merged PR in release notes

**New flow:**
1. Triggered when `v*` tag is pushed (from `/release` command)
2. Extract release notes from CHANGELOG.md for the current branch section
3. Find the merged PR for this release using `gh pr list --search`
4. Create GitHub Release with PR-linked release notes

### 6. Update Release Notes Format

Improve release notes generation in release.yml:

```yaml
- name: Extract release notes
  run: |
    # Find the PR that was merged for this release
    TAG_VERSION="${{ github.ref_name }}"
    PR_INFO=$(gh pr list --state merged --search "head:feat- OR head:fix- OR head:refact-" --json number,title,url --jq '.[0]')
    PR_URL=$(echo "$PR_INFO" | jq -r '.url')
    PR_TITLE=$(echo "$PR_INFO" | jq -r '.title')

    # Get changelog section (between first ## and second ##)
    CHANGELOG_SECTION=$(sed -n '/^## /,/^## /p' CHANGELOG.md | sed '1d;$d')

    # Format release notes with PR link
    cat > /tmp/release_notes.txt << EOF
    ## What's Changed

    $CHANGELOG_SECTION

    **Full Changelog**: $PR_URL
    EOF
```

## Verification

1. Run `/story` on a `feat-*` branch and verify:
   - Version is bumped to minor (e.g., 1.0.25 -> 1.1.0)
   - Version files are updated before PR creation
   - PR description includes the new version

2. Run `/release` and verify:
   - Tag is created with correct version
   - GitHub Release is created with PR-linked release notes

3. Merge a PR and verify:
   - No "Release v..." commit is created by GitHub Actions
   - GitHub Release links to the merged PR

## Notes

- The `/release` command remains for manual releases and tag creation
- Version bumping moves from post-merge (CI) to pre-merge (/story)
- This aligns version visibility with the PR lifecycle
