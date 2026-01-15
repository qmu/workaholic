# Workaholic

Analyze project and .claude configuration, then guide user through migration planning.

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

## Phase 3: Propose Skills

Based on discovery, recommend installing these workaholic skills:

### Available Skills to Propose

1. **commit-advisor** - Helps create well-structured git commits
   - Atomic commits, clear messages, staged review
   - Useful for: Any project with git

2. **pull-request-advisor** - Helps create reviewable PRs
   - PR templates, scope review, description generation
   - Useful for: Projects with code review workflow

3. **sync-claude-config** - Keeps .claude/ config up to date
   - Fetches latest docs, validates schema
   - Useful for: Staying current with Claude Code features

Use **AskUserQuestion** to ask which skills to install:

```
question: "Which skills would you like to add to your project's .claude/?"
header: "Skills"
multiSelect: true
options:
  - label: "commit-advisor"
    description: "Best practices for git commits and commit messages"
  - label: "pull-request-advisor"
    description: "Best practices for creating reviewable PRs"
  - label: "sync-claude-config"
    description: "Keep .claude/ configuration up to date"
```

## Phase 4: Ask Migration Plan

Use **AskUserQuestion** to ask what else to update:

```
question: "What else do you want to configure?"
header: "Config"
multiSelect: true
options:
  - label: "Agents"
    description: "Add custom subagents for this project"
  - label: "Commands"
    description: "Add slash commands"
  - label: "Settings"
    description: "Update settings.json"
```

## Phase 5: Execute Plan

### For Selected Skills

Copy skill directories to project's `.claude/skills/`:
- Create `.claude/skills/<skill-name>/SKILL.md`
- Preserve YAML frontmatter and instructions

### For Other Selections

1. **Agents**: Ask what agents to create, then create in `.claude/agents/`
2. **Commands**: Ask what commands to create, then create in `.claude/commands/`
3. **Settings**: Fetch latest docs and suggest settings updates

## Example Flow

```
[Phase 1: Discovery agents run in parallel]

## Current State
### .claude Configuration
- No skills configured
- 1 command found
...

### Project Structure
- TypeScript/Node.js project with git
...

## Recommended Skills

Based on your project:
- commit-advisor (git project detected)
- pull-request-advisor (collaborative project)

[Phase 3: AskUserQuestion - skills selection]

User selects: commit-advisor, pull-request-advisor

[Phase 4: AskUserQuestion - additional config]

User selects: Settings

[Phase 5: Execute]
- Copy commit-advisor to .claude/skills/
- Copy pull-request-advisor to .claude/skills/
- Update settings.json with latest schema
```
