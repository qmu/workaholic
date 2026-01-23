# Remove Agents from Core Plugin

## Overview

Remove the `plugins/core/agents/` directory and its contents (`discover-project.md`, `discover-claude-dir.md`). These agents are not actively used and can be removed to simplify the core plugin structure. Update all documentation that references these agents.

## Key Files

- `plugins/core/agents/discover-project.md` - To be deleted
- `plugins/core/agents/discover-claude-dir.md` - To be deleted
- `plugins/core/agents/` - Directory to be removed
- `plugins/core/README.md` - Update to remove agents section
- `CLAUDE.md` - Update project structure
- `README.md` - Update if it references agents
- `doc/specs/developer-guide/architecture.md` - Update architecture docs

## Implementation Steps

1. **Delete agent files**:

   - `rm plugins/core/agents/discover-project.md`
   - `rm plugins/core/agents/discover-claude-dir.md`

2. **Remove agents directory**:

   - `rmdir plugins/core/agents`

3. **Update `plugins/core/README.md`**:

   - Remove Agents section/table

4. **Update `CLAUDE.md`**:

   - Remove `agents/` line from core plugin structure

5. **Update `README.md`**:

   - Remove reference to agents in core plugin features

6. **Update `doc/specs/developer-guide/architecture.md`**:
   - Remove agents from architecture documentation

## Considerations

- These agents were for codebase exploration but are not part of the active workflow
- Removing unused components simplifies the plugin structure
- Core plugin will only have commands, rules, and hooks after this change
