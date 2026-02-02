---
name: create-branch
description: Create timestamped topic branch.
allowed-tools: Bash
user-invocable: false
---

# Create Branch

Create a new timestamped topic branch.

## Usage

```bash
bash .claude/skills/create-branch/sh/create.sh [prefix]
```

### Arguments

- `prefix` (optional): Branch prefix. Defaults to "drive".
  - **drive** - for TiDD style development
  - **trip** - for more AI oriented development

## Output

JSON with the created branch name:

```json
{
  "branch": "drive-20260202-204753"
}
```

The branch is automatically checked out after creation.
