---
name: create-branch
description: Create timestamped topic branch.
allowed-tools: Bash
user-invocable: false
---

# Create Branch

Create a new timestamped topic branch.

## Instructions

Run the bundled script with a prefix argument:

```bash
bash .claude/skills/create-branch/sh/create.sh <prefix>
```

### Valid Prefixes

- **drive** - for TiDD style development (default)
- **trip** - for AI-oriented development
- **feat** - for feature branches
- **fix** - for bug fix branches
- **refact** - for refactoring branches

### Example

```bash
bash .claude/skills/create-branch/sh/create.sh drive
```

### Output

The script outputs the created branch name:

```
drive-20260131-204000
```

The branch is automatically checked out after creation.
