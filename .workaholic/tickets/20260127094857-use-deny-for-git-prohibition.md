---
created_at: 2026-01-27T09:48:57+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Move git -C prohibition from agents to settings.json deny

## Overview

Replace the duplicated "CRITICAL: Git Command Format" sections in each agent file with a single `deny` rule in `.claude/settings.json`. This centralizes command prohibition and is the recommended Claude Code approach.

Additionally, create a skill that documents this pattern for future reference.

## Key Files

- `.claude/settings.json` - Add deny rule for `git -C`
- `plugins/core/agents/changelog-writer.md` - Remove CRITICAL section
- `plugins/core/agents/story-writer.md` - Remove CRITICAL section
- `plugins/core/agents/spec-writer.md` - Remove CRITICAL section
- `plugins/core/agents/terms-writer.md` - Remove CRITICAL section
- `plugins/core/agents/pr-creator.md` - Remove CRITICAL section
- `plugins/core/skills/command-prohibition/SKILL.md` - New skill documenting this pattern (create)

## Implementation Steps

1. Update `.claude/settings.json` to add:
   ```json
   {
     "permissions": {
       "deny": [
         "Bash(git -C:*)"
       ]
     }
   }
   ```
2. Remove the "## CRITICAL: Git Command Format" section from all 5 agent files
3. Create `plugins/core/skills/command-prohibition/SKILL.md` that explains:
   - How to use settings.json deny rules to block commands
   - When to use deny vs embedding in agent instructions
   - Reference to Claude Code docs

## Considerations

- The deny rule uses prefix matching with `:*` to catch all `git -C` variations
- Settings.json deny rules are enforced before any subagent execution
- This approach is more maintainable than duplicating instructions in each agent
- The skill serves as documentation for this pattern
