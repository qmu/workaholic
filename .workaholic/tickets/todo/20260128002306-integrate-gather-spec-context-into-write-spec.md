---
created_at: 2026-01-28T00:23:06+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Integrate gather-spec-context into write-spec

## Overview

Merge the `gather-spec-context` skill into `write-spec` to create a self-contained skill that both gathers context and provides writing guidelines. This simplifies the agent's preloaded skills list and makes `write-spec` a complete reference for spec documentation.

Currently, `spec-writer` agent preloads two separate skills:
- `gather-spec-context` - Runs bash script to collect branch/tickets/specs/diff info
- `write-spec` - Provides formatting rules and writing guidelines

After this change, `write-spec` will include the context gathering instructions, and `gather-spec-context` can be removed.

## Key Files

- `plugins/core/skills/write-spec/SKILL.md` - Add context gathering section from gather-spec-context
- `plugins/core/skills/write-spec/sh/gather.sh` - Move bash script here (create)
- `plugins/core/skills/gather-spec-context/` - Remove after migration (entire directory)
- `plugins/core/agents/spec-writer.md` - Update skills list to remove gather-spec-context

## Related History

The `gather-spec-context` skill was created in the same refactoring pass that extracted agent content into skills. The parallel `write-terms` and `gather-terms-context` pair follows the same pattern.

Past tickets that touched similar areas:

- `20260127204529-extract-agent-content-to-skills.md` - Created write-spec and thinned agents (same pattern)
- `20260127021013-extract-spec-skill.md` - Created gather-spec-context as separate skill (key file: this skill)

## Implementation Steps

1. Create `plugins/core/skills/write-spec/sh/` directory

2. Move `plugins/core/skills/gather-spec-context/sh/gather.sh` to `plugins/core/skills/write-spec/sh/gather.sh`

3. Update `plugins/core/skills/write-spec/SKILL.md`:
   - Add `allowed-tools: Bash` to frontmatter
   - Add a "Gather Context" section at the top (before Directory Structure)
   - Include bash script invocation instructions from gather-spec-context
   - Include output section documentation explaining BRANCH, TICKETS, SPECS, DIFF, COMMIT
   - Update script path to `.claude/skills/write-spec/sh/gather.sh`

4. Update `plugins/core/agents/spec-writer.md`:
   - Remove `gather-spec-context` from skills list in frontmatter
   - Update instructions step 1 to reference "the preloaded write-spec skill" instead of "preloaded gather-spec-context skill"

5. Delete `plugins/core/skills/gather-spec-context/` directory entirely

## Considerations

- The parallel `gather-terms-context` and `write-terms` pair should be considered for the same treatment in a follow-up ticket
- The bash script path in skill instructions uses `.claude/skills/` which is the installed location (via marketplace), not `plugins/core/skills/` which is the source location
- Skill frontmatter needs `allowed-tools: Bash` since it contains bash script instructions
