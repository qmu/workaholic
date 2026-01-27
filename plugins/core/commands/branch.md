---
name: branch
description: Create a topic branch with timestamp (e.g., feat-20260120-205418)
---

# Branch

Create a new topic branch with a timestamp-based name.

## Instructions

1. Ask the user to select a branch prefix:

   - **feat** - New feature
   - **fix** - Bug fix
   - **refact** - Refactoring

2. Run the bundled script with the selected prefix:
   ```bash
   bash .claude/skills/create-branch/sh/create.sh <prefix>
   ```

3. Confirm the created branch name to the user.

## Example

If user selects "feat" at 2026-01-20 20:54:18:

```
Created branch: feat-20260120-205418
```
