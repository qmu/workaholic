---
created_at: 2026-01-27T02:10:13+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Extract spec context skill from spec-writer agent

## Overview

Extract the context gathering logic from spec-writer agent into a dedicated skill with bash script. The agent will preload this skill for gathering branch context and auditing existing specs.

## Key Files

- `plugins/core/agents/spec-writer.md` - Simplify to preload skill
- `plugins/core/skills/spec-context/SKILL.md` - New skill definition (create)
- `plugins/core/skills/spec-context/scripts/gather.sh` - Bash script for context gathering (create)

## Implementation Steps

1. Create `plugins/core/skills/spec-context/SKILL.md` with instructions for using the context script
2. Create `plugins/core/skills/spec-context/scripts/gather.sh` that:
   - Gets current branch name
   - Lists archived tickets for branch
   - Lists existing spec files: `find .workaholic/specs -name "*.md" -type f`
   - Gets diff against main: `git diff main...HEAD --stat`
   - Outputs structured summary
3. Update `plugins/core/agents/spec-writer.md`:
   - Add `skills: [spec-context]` to frontmatter
   - Replace inline bash commands with reference to skill script
   - Keep spec writing guidelines and formatting rules in agent

## Considerations

- Script gathers data, agent makes documentation decisions
- Formatting rules and directory structure stay in agent
- Cross-cutting concern analysis requires LLM, stays in agent
