---
name: sync-claude-config
description: Keep project's `.claude/` configuration up to date with the latest Claude Code documentation. Use when the user asks to sync, update, or check their Claude configuration, or wants to know what's new in Claude Code config options.
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - WebFetch
  - Bash
---

# Sync Claude Config

Keep project's `.claude/` configuration up to date with the latest Claude Code documentation.

## Instructions

When the user asks to sync or update Claude configuration:

1. **Fetch latest documentation** from these sources:
   - https://code.claude.com/docs/en/settings
   - https://code.claude.com/docs/en/plugins
   - https://code.claude.com/docs/en/plugins-reference
   - https://code.claude.com/docs/en/hooks
   - https://code.claude.com/docs/en/skills

2. **Check current configuration** in the project's `.claude/` directory:
   - `settings.json` - Project settings
   - `commands/` - Custom commands
   - `hooks/` - Hook scripts
   - `settings.local.json` - Local overrides (don't commit)

3. **Compare and update** to match latest schema and best practices:
   - Validate JSON schema compliance
   - Add new supported fields if beneficial
   - Remove deprecated fields
   - Update to latest syntax/format

4. **Report changes**:
   ```
   ## Claude Config Sync Report

   ### Updated
   - [file]: [what changed]

   ### New Features Available
   - [feature]: [description from docs]

   ### Deprecated (removed)
   - [field]: [reason]
   ```

## Reference URLs

Always fetch the latest from:
- Settings: https://code.claude.com/docs/en/settings
- Plugins: https://code.claude.com/docs/en/plugins-reference
- Hooks: https://code.claude.com/docs/en/hooks
- Skills: https://code.claude.com/docs/en/skills
- Commands: https://code.claude.com/docs/en/commands

## Example Usage

User: "sync claude config"
Action: Fetch latest docs, compare with current config, suggest updates

User: "update .claude settings to latest"
Action: Update settings.json to match latest schema

User: "what's new in claude code config?"
Action: Fetch docs and report new features available
