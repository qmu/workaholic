---
created_at: 2026-01-31T20:40:00+09:00
author: tamurayoshiya@gmail.com
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Add Shell Script to Create-Branch Skill

## Overview

Bundle a shell script in the create-branch skill instead of using inline git command. This follows the established pattern used by other skills (archive-ticket, create-pr, write-changelog) for consistent, permission-free execution.

## Motivation

The create-branch skill currently uses an inline git command in the markdown documentation. Other skills with bash operations bundle shell scripts in `sh/` directories, providing:

- Consistent execution pattern across skills
- Permission-free execution (allowed-tools: Bash covers script execution)
- Easier testing and debugging
- Single source of truth for the operation

## Key Files

- `plugins/core/skills/create-branch/SKILL.md` - Update to reference bundled script
- `plugins/core/skills/create-branch/sh/create.sh` - New script file

## Related History

- [20260128002536-extract-create-branch-skill.md](.workaholic/tickets/archive/feat-20260128-001720/20260128002536-extract-create-branch-skill.md) - Originally proposed bundled script
- [20260129094618-fix-create-branch-path-reference.md](.workaholic/tickets/archive/feat-20260129-023941/20260129094618-fix-create-branch-path-reference.md) - Fixed path, inlined command as workaround

## Implementation

### 1. Create Shell Script

Create `plugins/core/skills/create-branch/sh/create.sh`:

```bash
#!/bin/bash
# Create timestamped topic branch
# Usage: create.sh <prefix>
# Example: create.sh drive

PREFIX="${1:-drive}"

# Validate prefix
case "$PREFIX" in
  drive|trip|feat|fix|refact) ;;
  *)
    echo "Error: prefix must be: drive, trip, feat, fix, or refact" >&2
    exit 1
    ;;
esac

# Generate branch name
BRANCH="${PREFIX}-$(date +%Y%m%d-%H%M%S)"

# Create and checkout branch
git checkout -b "$BRANCH"

# Output branch name
echo "$BRANCH"
```

### 2. Update SKILL.md

Replace inline command with script reference:

```markdown
## Instructions

Run the bundled script with a prefix argument:

\`\`\`bash
bash .claude/skills/create-branch/sh/create.sh <prefix>
\`\`\`

### Valid Prefixes

- **drive** - for TiDD style development (default)
- **trip** - for AI-oriented development
- **feat** - for feature branches
- **fix** - for bug fix branches
- **refact** - for refactoring branches

### Example

\`\`\`bash
bash .claude/skills/create-branch/sh/create.sh drive
\`\`\`

### Output

The script outputs the created branch name:

\`\`\`
drive-20260131-204000
\`\`\`
```

## Verification

1. Run the script directly:
   ```bash
   bash plugins/core/skills/create-branch/sh/create.sh drive
   ```

2. Verify branch is created with correct format

3. Test invalid prefix handling:
   ```bash
   bash plugins/core/skills/create-branch/sh/create.sh invalid
   # Should error with valid prefixes listed
   ```

## Notes

- Added feat/fix/refact prefixes to support story branch naming conventions
- Default prefix is "drive" if none specified
