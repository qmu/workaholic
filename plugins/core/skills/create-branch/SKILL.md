---
name: create-branch
description: Create timestamped topic branch.
allowed-tools: Bash
user-invocable: false
---

# Create Branch

Create a new timestamped topic branch.

## Instructions

Run the bundled script with a branch prefix:

```bash
bash .claude/skills/create-branch/sh/create.sh <prefix>
```

### Valid Prefixes

- **feat** - New feature
- **fix** - Bug fix
- **refact** - Refactoring

### Output

The script outputs the created branch name:

```
feat-20260120-205418
```

The branch is automatically checked out after creation.
