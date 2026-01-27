---
created_at: 2026-01-28T00:22:11+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Integrate gather-terms-context into write-terms

## Overview

The `gather-terms-context` skill exists solely to provide context-gathering instructions and a shell script for the `terms-writer` agent. Since `write-terms` is preloaded into the same agent and they always work together, merge them into a single skill to reduce fragmentation and simplify the skill structure.

This follows the pattern established in the previous ticket for merging `create-pr` and `manage-pr` - combining utility skills that have a 1:1 relationship with their primary skill.

## Key Files

- `plugins/core/skills/write-terms/SKILL.md` - Skill to expand with context-gathering
- `plugins/core/skills/gather-terms-context/SKILL.md` - Skill to merge and delete
- `plugins/core/skills/gather-terms-context/sh/gather.sh` - Shell script to move
- `plugins/core/agents/terms-writer.md` - Agent that preloads both skills

## Related History

The gather/write skill separation was established during the agent content extraction refactoring. Utility skills with shell scripts were kept separate at that time.

Past tickets that touched similar areas:

- `20260127204529-extract-agent-content-to-skills.md` - Created write-terms and kept gather-terms-context separate (same files)
- `20260127010716-rename-terminology-to-terms.md` - Renamed terminology to terms (same layer: Config)

## Implementation Steps

1. **Move shell script to write-terms directory**:
   - Move `plugins/core/skills/gather-terms-context/sh/gather.sh` to `plugins/core/skills/write-terms/sh/gather.sh`

2. **Merge context-gathering into write-terms**:
   - Add a "Gather Context" section at the beginning of write-terms SKILL.md
   - Include the shell script invocation instructions from gather-terms-context
   - Update the script path reference to `.claude/skills/write-terms/sh/gather.sh`
   - Include the output sections documentation

3. **Update terms-writer agent**:
   - Remove `gather-terms-context` from skills list
   - Update instruction step 1 to reference the merged skill's context-gathering section

4. **Delete gather-terms-context skill directory**:
   - Remove `plugins/core/skills/gather-terms-context/` entirely

## Considerations

- The parallel `gather-spec-context`/`write-spec` pair should be merged in a separate ticket for consistency
- The shell script path changes from `gather-terms-context` to `write-terms`
- The agent still needs `enforce-i18n` as a separate skill since it's shared across multiple agents
