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

## Phase 4: Analyze Gaps and Propose Updates

Based on the discovery results, analyze what's missing or outdated and propose a comprehensive update plan. Do NOT ask the user what to configure - instead, proactively identify gaps and recommend updates.

### Analysis Checklist

Compare the project's current state against best practices:

1. **CLAUDE.md**: Does it exist? Is it comprehensive? Does it describe the project accurately?
2. **Commands**: Are there missing essential commands like `/commit` or `/pull-request`?
3. **Settings**: Is `settings.json` present? Are there recommended settings missing?
4. **Skills**: Are the standard skills (commit-advisor, pull-request-advisor, sync-claude-config) installed?

### Present Proposal

Output a clear proposal like:

```
## Proposed Updates

Based on my analysis, here's what I recommend updating:

### ✓ Will Add
- [item]: [reason why it's needed]

### ○ Already Configured
- [item]: [current state is good]

### Optional Improvements
- [item]: [suggestion if applicable]

Proceed with these updates? (Y/n)
```

Wait for user confirmation before proceeding to Phase 5.

## Phase 5: Execute Plan

After user confirms the proposal, execute all recommended updates.

### Always Merge Skills

Copy all skill directories to project's `.claude/skills/`:
- `commit-advisor/` → `.claude/skills/commit-advisor/`
- `pull-request-advisor/` → `.claude/skills/pull-request-advisor/`
- `sync-claude-config/` → `.claude/skills/sync-claude-config/`

Preserve YAML frontmatter and all instructions in each skill.

### Execute Based on Proposal

For each item in the "Will Add" section:

1. **CLAUDE.md**: Create/update root `CLAUDE.md` based on project structure analysis
2. **settings.json**: Create `.claude/settings.json` with recommended settings for the project type
3. **Commands**: Create missing essential commands in `.claude/commands/`
4. **Agents**: Create project-specific agents in `.claude/agents/` if needed

## Example Flow

```
[Phase 1: Discovery agents run in parallel]

## Current State
### .claude Configuration
- No skills configured
- 1 command found: /release
- settings.json: missing

### Project Structure
- TypeScript/Node.js project with git
- Has package.json, tsconfig.json
- Uses ESLint and Prettier

[Phase 3: Templates to Merge]

The following templates will be added to your `.claude/` directory:

- commit-advisor/ - Git commit best practices
- pull-request-advisor/ - PR creation best practices
- sync-claude-config/ - Keep config up to date

[Phase 4: Analyze and Propose]

## Proposed Updates

Based on my analysis, here's what I recommend updating:

### ✓ Will Add
- **commit-advisor/**: Not found - enables better commit workflows
- **pull-request-advisor/**: Not found - enables better PR creation
- **sync-claude-config/**: Not found - keeps config up to date
- **settings.json**: Missing - will add recommended settings
- **CLAUDE.md**: Missing - will create project instructions

### ○ Already Configured
- **/release command**: Present and working

Proceed with these updates? (Y/n)

[User confirms]

[Phase 5: Execute]
- Copy all skills to .claude/skills/
- Create settings.json with recommended config
- Generate CLAUDE.md based on project analysis
```
