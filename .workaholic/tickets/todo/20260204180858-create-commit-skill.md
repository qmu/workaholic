---
created_at: 2026-02-04T18:08:58+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Create commit skill integrating format-commit-message and Git Safety

## Overview

Create a new `commit` skill that integrates the `format-commit-message` skill with the Git Safety guidelines from drive.md. All commits in the workflow should go through this skill to ensure consistent commit formatting and safe git operations. This centralizes commit logic and enforces the multi-contributor awareness established in the git safeguards ticket.

## Key Files

- `plugins/core/skills/format-commit-message/SKILL.md` - Existing commit message formatting rules to integrate
- `plugins/core/commands/drive.md` - Contains Git Safety section with multi-contributor context
- `plugins/core/skills/archive-ticket/SKILL.md` - Currently handles commits, should delegate to commit skill
- `plugins/core/skills/drive-approval/SKILL.md` - Abandonment commit should use commit skill

## Implementation Steps

1. **Create `plugins/core/skills/commit/SKILL.md`**:
   - Integrate format-commit-message guidelines for message structure
   - Include Git Safety pre-commit checks from drive.md
   - Add multi-contributor awareness checks before committing
   - Provide both bash script wrapper and inline guidance

2. **Create `plugins/core/skills/commit/sh/commit.sh`**:
   - Pre-flight safety checks (verify no unintended files staged)
   - Format commit message with Co-Authored-By
   - Execute commit with proper formatting

3. **Update `archive-ticket` skill**:
   - Delegate commit operations to the new commit skill
   - Keep archive logic, move commit logic to commit skill

4. **Update `drive-approval` skill**:
   - Abandonment commits should use commit skill

5. **Update `drive.md`**:
   - Reference commit skill for all commit operations
   - Remove redundant inline commit guidance

## Considerations

- The commit skill should be reusable across different workflows (drive, archive, abandon)
- Pre-commit checks should verify only intended files are staged
- Multi-contributor awareness means checking for unexpected staged changes
- Keep format-commit-message as a dependency skill for the templates

## Final Report

Development completed as planned. Created commit skill with:

**New files:**
- `plugins/core/skills/commit/SKILL.md` - Skill documentation with multi-contributor awareness guidelines
- `plugins/core/skills/commit/sh/commit.sh` - Bash script with `--skip-staging` flag support

**Updated files:**
- `plugins/core/skills/archive-ticket/sh/archive.sh` - Delegates commit to commit.sh
- `plugins/core/skills/archive-ticket/SKILL.md` - Updated to reference commit skill
- `plugins/core/skills/drive-approval/SKILL.md` - Abandonment commits now use commit skill
- `plugins/core/commands/drive.md` - Added reference to commit skill in Git Safety section
