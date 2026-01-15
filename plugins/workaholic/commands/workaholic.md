---
name: workaholic
description: Analyze project and .claude configuration, then guide user through migration planning.
---

# Workaholic

Analyze project and .claude configuration, then guide user through migration planning.

## Important

This command **only updates the repository root**:
- `.claude/` directory (commands, templates, agents, settings)
- `CLAUDE.md` file

It does NOT modify any other project files or directories.

## Phase 1: Discovery

Launch **two sub-agents in parallel** using the Task tool:

1. **discover-claude-dir** - Explores `.claude/` directory configuration
2. **discover-project** - Explores project structure (excluding .claude/, node_modules/, etc.)

## Phase 2: Present Overview

Synthesize results into a concise overview:

```
## Current State

### .claude Configuration
[summary from discover-claude-dir]

### Project Structure
[summary from discover-project]
```

## Phase 3: Propose Configuration Merge

Present the templates that will be merged into the project's `.claude/` directory:

```
## Templates to Merge

The following templates will be added to your `.claude/` directory:

- **commit-advisor/** - Git commit best practices and `/commit` command customization
- **pull-request-advisor/** - PR creation best practices and `/pull-request` command customization
- **sync-claude-config/** - Keep .claude/ configuration up to date with latest Claude Code features
```

Do NOT ask the user to select which templates to install - all templates will be merged by default.

## Phase 4: Ask Migration Plan

Use **AskUserQuestion** to ask what else to update:

```
question: "What else do you want to configure?"
header: "Config"
multiSelect: true
options:
  - label: "CLAUDE.md"
    description: "Create or update project instructions file"
  - label: "Agents"
    description: "Add custom subagents for this project"
  - label: "Commands"
    description: "Add slash commands"
  - label: "Settings"
    description: "Update settings.json"
```

## Phase 5: Execute Plan

### Merge All Templates

Copy all template directories to project's `.claude/skills/`:
- `commit-advisor/` → `.claude/skills/commit-advisor/`
- `pull-request-advisor/` → `.claude/skills/pull-request-advisor/`
- `sync-claude-config/` → `.claude/skills/sync-claude-config/`

Preserve YAML frontmatter and all instructions in each template.

### For Additional Selections (from Phase 4)

1. **CLAUDE.md**: Analyze project and create/update root `CLAUDE.md` with project instructions
2. **Agents**: Ask what agents to create, then create in `.claude/agents/`
3. **Commands**: Ask what commands to create, then create in `.claude/commands/`
4. **Settings**: Fetch latest docs and suggest settings updates

## Example Flow

```
[Phase 1: Discovery agents run in parallel]

## Current State
### .claude Configuration
- No templates configured
- 1 command found
...

### Project Structure
- TypeScript/Node.js project with git
...

## Templates to Merge

The following templates will be added to your `.claude/` directory:

- commit-advisor/ - Git commit best practices
- pull-request-advisor/ - PR creation best practices
- sync-claude-config/ - Keep config up to date

[Phase 4: AskUserQuestion - additional config]

User selects: Settings

[Phase 5: Execute]
- Copy all templates to .claude/skills/
- Update settings.json with latest schema
```
