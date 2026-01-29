---
created_at: 2026-01-29T04:19:24+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Add Ticket Validation Hook

## Overview

Create a PostToolUse hook that validates ticket file format and location when Claude Code creates or modifies files in `.workaholic/tickets/`. This prevents policy-violating tickets by catching format errors immediately after file operations, blocking invalid tickets and providing actionable feedback to Claude.

## Key Files

- `plugins/core/.claude-plugin/plugin.json` - Add hooks field pointing to hooks.json
- `plugins/core/hooks/hooks.json` - Create hook configuration (new file)
- `plugins/core/hooks/validate-ticket.sh` - Create validation script (new file)
- `plugins/core/skills/create-ticket/SKILL.md` - Reference for format specification
- `plugins/core/rules/workaholic.md` - Reference for directory structure rules

## Related History

Prior work established the ticket format specification and directory structure constraints that this hook will enforce programmatically.

Past tickets that touched similar areas:

- [20260123001814-prettier-hook.md](.workaholic/tickets/archive/feat-20260122-210543/20260123001814-prettier-hook.md) - PostToolUse hook pattern with hooks.json and shell script (same layer: Config)
- [20260128002853-extract-create-ticket-skill.md](.workaholic/tickets/archive/feat-20260128-001720/20260128002853-extract-create-ticket-skill.md) - Consolidated ticket format validation rules into skill (same layer: Config)
- [20260127103311-move-tickets-to-todo.md](.workaholic/tickets/archive/feat-20260126-214833/20260127103311-move-tickets-to-todo.md) - Established todo/icebox/archive directory structure (same layer: Config)

## Implementation Steps

1. Create `plugins/core/hooks/hooks.json` with PostToolUse configuration:

   ```json
   {
     "description": "Ticket format and location validation",
     "hooks": {
       "PostToolUse": [
         {
           "matcher": "Write|Edit",
           "hooks": [
             {
               "type": "command",
               "command": "${CLAUDE_PLUGIN_ROOT}/hooks/validate-ticket.sh",
               "timeout": 10
             }
           ]
         }
       ]
     }
   }
   ```

2. Create `plugins/core/hooks/validate-ticket.sh` script that:

   - Reads JSON from stdin to get `tool_input.file_path`
   - Exits 0 immediately if file is not in `.workaholic/tickets/`
   - Validates location: must be in `todo/`, `icebox/`, or `archive/<branch>/`
   - Validates filename: must match `YYYYMMDDHHmmss-*.md` pattern
   - Validates frontmatter presence and required fields:
     - `created_at`: Must be ISO 8601 format
     - `author`: Must be present (email format)
     - `type`: Must be one of `enhancement`, `bugfix`, `refactoring`, `housekeeping`
     - `layer`: Must be array with valid values (`UX`, `Domain`, `Infrastructure`, `DB`, `Config`)
     - `effort`: Empty or valid format (`0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h`)
     - `commit_hash`: Empty or short git hash format
     - `category`: Empty or one of `Added`, `Changed`, `Removed`
   - On validation failure: exit 2 with descriptive stderr (blocks and informs Claude)
   - On success: exit 0

3. Update `plugins/core/.claude-plugin/plugin.json` to reference hooks:

   ```json
   {
     "name": "core",
     "description": "Core development workflow...",
     "version": "1.0.22",
     "hooks": "hooks/hooks.json"
   }
   ```

## Considerations

- Hook runs on every Write/Edit, so check file path first and exit early for non-ticket files
- Use `jq` for JSON parsing (should be available in most environments)
- Error messages should be specific and actionable (e.g., "type field must be one of: enhancement, bugfix, refactoring, housekeeping")
- The `${CLAUDE_PLUGIN_ROOT}` variable provides absolute path to plugin directory
- Script must handle both Write (new file) and Edit (modified file) operations
- Consider edge case: ticket in `fail/` directory (used when implementation is abandoned)
