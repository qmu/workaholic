---
name: configure-statusline
description: Guidelines for configuring Claude Code status line with repository display
user-invocable: false
---

# Configure Status Line

Configure Claude Code to display the repository name in the status line.

## Overview

Claude Code supports a custom status line that can display dynamic information. This skill configures:

1. `~/.claude/settings.json` - Points to a status line script
2. `~/.claude/statusline.sh` - Script that outputs the status line content

## Step 1: Update settings.json

Read the existing `~/.claude/settings.json` file. If it doesn't exist, create it.

### If file exists

Merge the `statusLine` configuration into the existing settings without overwriting other fields:

```json
{
  "existingField": "preserved",
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

### If file doesn't exist

Create a new file with:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

## Step 2: Create statusline.sh

Create `~/.claude/statusline.sh` with the following content:

```bash
#!/bin/bash
# Claude Code status line script
# Displays: [Model] Repository Name

input=$(cat)
PROJECT_DIR=$(echo "$input" | jq -r '.workspace.project_dir')
REPO_NAME=$(basename "$PROJECT_DIR")
MODEL=$(echo "$input" | jq -r '.model.display_name')

echo "[$MODEL] $REPO_NAME"
```

## Step 3: Set permissions

The script must be executable. After creating it, inform the user to run:

```bash
chmod +x ~/.claude/statusline.sh
```

## Input Format

Claude Code passes JSON to the status line command via stdin:

```json
{
  "workspace": {
    "project_dir": "/path/to/repository"
  },
  "model": {
    "display_name": "Claude Sonnet 4"
  }
}
```

## Notes

- The script requires `jq` for JSON parsing
- Status line updates on each prompt
- Keep the script fast (avoid network calls or heavy operations)
- The `~` path expands correctly in the settings.json command field
