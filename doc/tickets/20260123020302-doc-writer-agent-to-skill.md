# Convert doc-writer Agent to Skill

## Overview

Convert `plugins/tdd/agents/doc-writer.md` from an agent to a skill. Skills are invoked via the Skill tool and provide inline instructions, while agents are spawned as subprocesses via Task tool. Converting to a skill keeps documentation work in the main conversation context.

## Key Files

- `plugins/tdd/agents/doc-writer.md` - Current agent (to be deleted)
- `plugins/tdd/skills/doc-writer/SKILL.md` - New skill (to be created)
- `plugins/core/commands/pull-request.md` - Update to invoke skill instead of agent

## Implementation Steps

1. **Create skill directory**:

   - `mkdir -p plugins/tdd/skills/doc-writer`

2. **Create `plugins/tdd/skills/doc-writer/SKILL.md`**:

   - Use skill frontmatter format (name, description, allowed-tools, user-invocable)
   - Keep the same instructions from the agent
   - Set `user-invocable: false` (only called by other commands)
   - Set `allowed-tools: Read, Glob, Grep, Write, Edit, Bash`

3. **Delete the agent file**:

   - `rm plugins/tdd/agents/doc-writer.md`
   - Remove `plugins/tdd/agents/` directory if empty

4. **Update `plugins/core/commands/pull-request.md`**:

   - Change from Task tool with `subagent_type: doc-writer` to Skill tool
   - Adjust any instructions that reference the agent

5. **Update any other references**:
   - Check `plugins/tdd/commands/drive.md` if it still references doc-writer
   - Update documentation rules if they mention the agent

## Considerations

- Skills run in the main conversation context, agents run as subprocesses
- Skills are better for tasks that need to interact with the current state
- The skill will have access to the full conversation context
- Frontmatter format differs between agents and skills
