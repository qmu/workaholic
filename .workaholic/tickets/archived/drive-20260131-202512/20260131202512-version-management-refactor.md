---
effort: medium
category: changed
type: enhancement
author: tamurayoshiya@gmail.com
created_at: 2026-01-31T20:25:12+09:00
commit_hash: 90de0c5
---

# Refactor Version Management to Story-Time with PR-Linked Release Notes

## Overview

Move version management from GitHub Actions to `/story` command execution. Create a project-level version-manager agent in `.claude/` that handles version bumping. The core plugin's story command reads the version policy from root CLAUDE.md.

## Motivation

**Current problems:**

1. Version bumping happens in GitHub Actions **after** PR merge, creating a "Release v..." commit that feels disconnected from the development flow
2. Release notes are poorly generated - just commit messages without PR context
3. The PR itself doesn't know the version it will become until after merge

**Desired state:**

1. Version is bumped during `/story` **before** PR creation
2. GitHub Actions only creates a GitHub Release with proper PR-linked release notes
3. Version policy is project-level (in `.claude/` and `CLAUDE.md`), not plugin-level

## Architecture

**Project-level (this repo's `.claude/`):**
- `.claude/agents/version-manager.md` - agent that manages version bumping
- `.claude/skills/manage-version/SKILL.md` - skill with version logic and script
- `CLAUDE.md` - contains version increment policy section

**Plugin-level (`plugins/core/`):**
- `plugins/core/commands/story.md` - checks if root CLAUDE.md has version policy, invokes version-manager if so

This separation allows:
- Version management is project-specific (not all projects need it)
- Plugin remains generic and reusable across projects
- Projects can customize their version policy in CLAUDE.md

## Key Files

- `.claude/agents/version-manager.md` - New project-level subagent
- `.claude/skills/manage-version/SKILL.md` - New project-level skill
- `.claude/skills/manage-version/sh/update.sh` - Shell script for version update
- `CLAUDE.md` - Add "Version Increment Policy" section
- `plugins/core/commands/story.md` - Check for version policy, invoke version-manager
- `.github/workflows/release.yml` - Simplify to only generate release notes

## Implementation

### 1. Add Version Policy to CLAUDE.md

Add section to root `CLAUDE.md`:

```markdown
## Version Increment Policy

During `/story`, automatically increment version before PR creation.

**Default**: patch bump (1.0.25 → 1.0.26)

AI analyzes changes to determine if minor/major is warranted:
- **patch**: Bug fixes, small improvements, internal refactoring
- **minor**: New features, significant enhancements (requires user confirmation)
- **major**: Breaking changes (requires user confirmation)

Invoke version-manager agent during Phase 1 of /story command.
```

### 2. Create Version Management Skill

Create `.claude/skills/manage-version/SKILL.md`:

```markdown
---
name: manage-version
description: Determine version type and update version files.
allowed-tools: Bash
user-invocable: false
---

# Manage Version

Update version in marketplace.json and plugin.json files.

## Version Update Script

Run the bundled script to update version:

```bash
bash .claude/skills/manage-version/sh/update.sh <version-type>
```

Arguments:
- `patch` - Increment patch version (1.0.25 -> 1.0.26)
- `minor` - Increment minor version (1.0.25 -> 1.1.0)
- `major` - Increment major version (1.0.25 -> 2.0.0)

The script:
1. Reads current version from `.claude-plugin/marketplace.json`
2. Calculates new version based on type
3. Updates version in:
   - `.claude-plugin/marketplace.json` (root and plugins array)
   - `plugins/core/.claude-plugin/plugin.json`
4. Outputs: `<old-version> -> <new-version>`
```

### 3. Create Shell Script

Create `.claude/skills/manage-version/sh/update.sh`:

```bash
#!/bin/bash
# Update version based on version type argument

VERSION_TYPE="$1"

if [ -z "$VERSION_TYPE" ]; then
  echo "Usage: $0 <patch|minor|major>" >&2
  exit 1
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
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
  *)
    echo "Invalid version type: $VERSION_TYPE" >&2
    exit 1
    ;;
esac

NEW="${MAJOR}.${MINOR}.${PATCH}"

# Update all version occurrences in marketplace.json
sed -i '' "s/\"version\": \"$CURRENT\"/\"version\": \"$NEW\"/g" "$MARKETPLACE_JSON"

# Update core plugin.json
CORE_PLUGIN="plugins/core/.claude-plugin/plugin.json"
if [ -f "$CORE_PLUGIN" ]; then
  sed -i '' "s/\"version\": \"$CURRENT\"/\"version\": \"$NEW\"/" "$CORE_PLUGIN"
fi

echo "$CURRENT -> $NEW"
```

### 4. Create Version Manager Agent

Create `.claude/agents/version-manager.md`:

```markdown
---
name: version-manager
description: Analyze changes and update version files.
tools: Bash
skills:
  - manage-version
---

# Version Manager Agent

Analyze branch changes and update version files during /story command.

## Process

1. Get changes summary: `git diff main --stat`
2. Review CHANGELOG.md for new entries
3. Determine version type:
   - Default: `patch`
   - If changes include new features: recommend `minor` (ask user)
   - If changes include breaking changes: recommend `major` (ask user)
4. Run version update script
5. Report result

## Output

Return JSON:
- Success: `{"status": "updated", "version": "1.0.25 -> 1.0.26", "type": "patch"}`
- Needs confirmation: `{"status": "confirm", "recommended": "minor", "reason": "New features added"}`
```

### 5. Update Story Command

Modify `plugins/core/commands/story.md`:

- In Phase 1, check if root CLAUDE.md contains "Version Increment Policy"
- If yes, add version-manager to parallel agent invocation
- Handle `confirm` status by asking user with AskUserQuestion

Add to Phase 1 description:

```markdown
**Version management** (optional):
- Check if root `CLAUDE.md` contains "Version Increment Policy" section
- If present, invoke **version-manager** agent in parallel with other Phase 1 agents
- If version-manager returns `{"status": "confirm", ...}`: ask user whether to proceed with recommended version type
```

### 6. Simplify GitHub Actions

Modify `.github/workflows/release.yml`:

**Remove:**
- Version bumping logic (moved to /story)

**Keep:**
- Trigger on tag push (v*)
- Generate release notes from CHANGELOG.md
- Link to the merged PR

## Verification

1. Run `/story` and verify:
   - Version is bumped to patch by default
   - Version files are updated before PR creation

2. Run `/release` and verify:
   - Tag is created with correct version
   - GitHub Release links to merged PR

## Notes

- Version management is now project-level, not plugin-level
- Projects without "Version Increment Policy" in CLAUDE.md skip version bumping
- Default is always patch; minor/major requires user confirmation
