---
created_at: 2026-01-29T09:40:41+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.25h
commit_hash: c2288a1
category: Added
---

# Add statusline-setup Subagent

## Overview

Create a new `statusline-setup` subagent that configures Claude Code's status line to display the repository name. The subagent will create/update `~/.claude/settings.json` and generate a `~/.claude/statusline.sh` script.

## Key Files

- `plugins/core/agents/statusline-setup.md` (new) - Subagent definition
- `plugins/core/skills/configure-statusline/SKILL.md` (new) - Configuration guidelines and script template

## Related History

- `20260127204529-extract-agent-content-to-skills.md` - Thin subagent pattern with skill preloading
- `20260127003251-sync-workaholic-subagent.md` - Subagent creation pattern

## Implementation

1. **Create subagent** at `plugins/core/agents/statusline-setup.md`
   - Frontmatter: name, description, tools (Read, Edit), skills (configure-statusline)
   - Brief instructions for invoking the skill

2. **Create skill** at `plugins/core/skills/configure-statusline/SKILL.md`
   - Settings.json template with `statusLine` configuration
   - Statusline script template that displays repository name
   - Instructions for:
     - Reading existing settings.json or creating new
     - Adding/updating `statusLine` field
     - Creating statusline.sh with proper permissions
     - Script content that extracts repo name from `workspace.project_dir`

3. **Statusline script logic**
   - Read JSON input from stdin (provided by Claude Code)
   - Extract `workspace.project_dir`
   - Display basename as repository name
   - Optional: include model name, git branch

## Settings.json Format

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

## Statusline Script Template

```bash
#!/bin/bash
input=$(cat)
PROJECT_DIR=$(echo "$input" | jq -r '.workspace.project_dir')
REPO_NAME=$(basename "$PROJECT_DIR")
MODEL=$(echo "$input" | jq -r '.model.display_name')
echo "[$MODEL] $REPO_NAME"
```

## Acceptance

- [x] Subagent file exists at `plugins/core/agents/statusline-setup.md`
- [x] Skill file exists at `plugins/core/skills/configure-statusline/SKILL.md`
- [x] Skill contains settings.json template
- [x] Skill contains statusline.sh script template
- [x] Instructions guide merging with existing settings (not overwriting)

## Final Report

### Changes Made

- Created `plugins/core/agents/statusline-setup.md` - Thin subagent with Read/Edit tools and configure-statusline skill
- Created `plugins/core/skills/configure-statusline/SKILL.md` with:
  - Step-by-step instructions for updating settings.json
  - Statusline.sh script template showing model and repo name
  - JSON input format documentation
  - Notes on permissions and performance
