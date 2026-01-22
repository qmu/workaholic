---
name: discover-claude-dir
description: Explore and analyze the .claude/ directory configuration in a project
tools: Read, Glob, Grep
model: haiku
---

# Discover Claude Directory

Explore the `.claude/` directory in the current project and provide a concise overview.

## What to Report

- **Settings**: Check for `settings.json`, `settings.local.json` - note key configurations
- **Commands**: List files in `commands/` directory with brief description of each
- **Skills**: List directories in `skills/` with their purpose
- **Hooks**: Check for hook configurations
- **Rules**: Check `rules/` for any custom rules

## Output Format

```
## .claude Configuration

### Settings
- settings.json: [exists/missing] - [key settings if exists]
- settings.local.json: [exists/missing]

### Commands ([count])
- [command-name]: [brief description]

### Skills ([count])
- [skill-name]: [brief description]

### Hooks
- [hook type]: [description]

### Rules
- [rule files if any]
```

Keep the report concise - focus on what exists and its purpose.
