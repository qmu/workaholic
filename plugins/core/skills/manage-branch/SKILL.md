---
name: manage-branch
description: Check and create timestamped topic branches.
allowed-tools: Bash
user-invocable: false
---

# Manage Branch

Check current branch state and create new topic branches when needed.

## Check Branch

Check if currently on a topic branch:

```bash
current=$(git branch --show-current)
if [ "$current" = "main" ] || [ "$current" = "master" ]; then
  echo "on_main"
else
  echo "on_topic:$current"
fi
```

Topic branch patterns: `drive-*`, `trip-*`

## Create Branch

```bash
bash .claude/skills/manage-branch/sh/create.sh [prefix]
```

### Arguments

- `prefix` (optional): Branch prefix. Defaults to "drive".
  - **drive** - for TiDD style development
  - **trip** - for more AI oriented development

### Output

JSON with the created branch name:

```json
{
  "branch": "drive-20260202-204753"
}
```

The branch is automatically checked out after creation.
