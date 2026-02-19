---
name: branching
description: Check and create timestamped topic branches.
allowed-tools: Bash
user-invocable: false
---

# Branching

Check current branch state and create new topic branches when needed.

## Check Branch

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/branching/sh/check.sh
```

### Output

JSON with branch state:

```json
{
  "on_main": true,
  "branch": "main"
}
```

- `on_main`: Boolean indicating if on main/master branch
- `branch`: Current branch name

Topic branch patterns: `drive-*`, `trip-*`

## Create Branch

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/branching/sh/create.sh [prefix]
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
