---
name: manage-branch
description: Check and create timestamped topic branches.
allowed-tools: Bash
user-invocable: false
---

# Manage Branch

Check current branch state and create new topic branches when needed.

## Check Branch

```bash
bash .claude/skills/manage-branch/sh/check.sh
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

## Auto-Approval Configuration

To avoid permission prompts for bundled skill scripts, users can add the following to their `.claude/settings.local.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(bash:*)"
    ]
  }
}
```

This auto-approves all `bash` script invocations. The `.settings.local.json` file is user-local and should not be committed to the repository.
