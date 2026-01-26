---
created_at: 2026-01-27T00:32:51+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Convert sync-workaholic command to subagent

## Overview

The `/sync-workaholic` command should be converted from a command (`plugins/core/commands/sync-workaholic.md`) to a subagent (`plugins/core/agents/sync-workaholic.md`). This allows the sync process to run in its own context window, preserving the main conversation context while performing extensive codebase exploration and documentation updates. The `/sync-workaholic` command will become an alias that invokes the subagent.

## Key Files

- `plugins/core/commands/sync-workaholic.md` - Current command to be removed
- `plugins/core/agents/sync-workaholic.md` - New subagent to create
- `plugins/core/agents/performance-analyst.md` - Reference for agent frontmatter format

## Implementation Steps

1. **Create the subagent file** at `plugins/core/agents/sync-workaholic.md`:
   - Use the agent frontmatter format (`name`, `description`, `tools`, `model`)
   - Copy the instructions content from the current command
   - Set appropriate tools: Read, Write, Edit, Bash, Glob, Grep (needs write access for docs)
   - Set model to `inherit` or omit (use parent's model)

2. **Update the command to be an alias**:
   - Keep `plugins/core/commands/sync-workaholic.md` as a minimal file
   - Change it to simply invoke the subagent via Task tool
   - The command becomes a thin wrapper that delegates to the agent

3. **Agent frontmatter structure**:
   ```yaml
   ---
   name: sync-workaholic
   description: Sync source code changes to .workaholic/ directory (specs and terminology). Use after completing implementation work to update documentation.
   tools: Read, Write, Edit, Bash, Glob, Grep
   ---
   ```

4. **Command alias structure**:
   ```yaml
   ---
   name: sync-workaholic
   description: Sync source code changes to .workaholic/ directory (specs and terminology)
   ---

   # Sync Workaholic

   Invoke the sync-workaholic subagent to update `.workaholic/specs/` and `.workaholic/terminology/`.

   ## Instructions

   Use the Task tool to invoke the `sync-workaholic` subagent with the following prompt:

   "Update .workaholic/specs/ and .workaholic/terminology/ to reflect the current codebase state. Follow the instructions in your system prompt."
   ```

## Considerations

- **Context preservation**: Running as a subagent keeps extensive file reads out of main conversation
- **Tool access**: The agent needs write access (Write, Edit) to update documentation files
- **Model choice**: Using `inherit` ensures consistency with the parent conversation's model
- **Backward compatibility**: The `/sync-workaholic` command still works, just delegates to the agent
- **Proactive use**: Include "Use after completing implementation" in description so Claude knows when to suggest it
