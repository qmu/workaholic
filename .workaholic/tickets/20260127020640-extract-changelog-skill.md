---
created_at: 2026-01-27T02:06:40+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Extract changelog skill from changelog-writer agent

## Overview

Extract the changelog generation logic from changelog-writer agent into a dedicated skill with bash script. The agent will then preload this skill via the `skills:` frontmatter field, following Claude Code's subagent skill preloading pattern.

## Key Files

- `plugins/core/agents/changelog-writer.md` - Simplify to preload skill
- `plugins/core/skills/changelog/SKILL.md` - New skill definition (create)
- `plugins/core/skills/changelog/scripts/generate.sh` - Bash script for changelog generation (create)

## Implementation Steps

1. Create `plugins/core/skills/changelog/SKILL.md` with the changelog generation instructions extracted from the agent
2. Create `plugins/core/skills/changelog/scripts/generate.sh` that:
   - Takes branch name and repo URL as arguments
   - Reads archived tickets from `.workaholic/tickets/archive/<branch>/`
   - Extracts commit_hash and category from frontmatter
   - Generates formatted changelog entries
   - Outputs the entries grouped by category (Added, Changed, Removed)
3. Update `plugins/core/agents/changelog-writer.md`:
   - Add `skills: [changelog]` to frontmatter
   - Simplify the body to reference the preloaded skill
   - Keep the "CRITICAL: Git Command Format" section
   - Remove detailed instruction steps (now in skill)

## Considerations

- The skill should be self-contained and reusable
- Bash script handles the mechanical parts (file reading, parsing)
- Agent handles the decision-making (what to update, verification)
- Follow existing archive-ticket skill structure as reference
