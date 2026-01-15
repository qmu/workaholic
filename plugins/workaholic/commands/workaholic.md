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

## Phase 3: Ask Migration Plan

Use **AskUserQuestion** to ask what the user wants to update:

```
question: "What do you want to update or migrate?"
header: "Migration"
multiSelect: true
options:
  - label: "Agents"
    description: "Add/update custom subagents for this project"
  - label: "Skills"
    description: "Add/update skills with YAML metadata"
  - label: "Commands"
    description: "Add/update slash commands"
  - label: "Settings"
    description: "Update settings.json configuration"
```

## Phase 4: Execute Plan

Based on user selection, for each selected item:

1. **Agents**: Ask what new agents to create or which to update
2. **Skills**: Ask what skills to add or migrate to YAML format
3. **Commands**: Ask what commands to create or update
4. **Settings**: Fetch latest docs and suggest settings updates

For each item, ask clarifying questions before implementation:
- What should it do?
- What tools does it need?
- Any specific behavior?

## Example Flow

```
[Phase 1: Run discover agents in parallel]

## Current State
### .claude Configuration
- 2 agents, 1 skill, 1 command configured
...

### Project Structure
- TypeScript/Node.js project
...

[Phase 3: AskUserQuestion - multiselect]

User selects: Agents, Commands

[Phase 4: Follow-up questions]

"What agents do you want to add or update?"
- Create new agent
- Update discover-claude-dir
- Update discover-project

[Implement based on answers]
```
