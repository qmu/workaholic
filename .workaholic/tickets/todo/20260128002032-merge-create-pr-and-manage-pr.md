---
created_at: 2026-01-28T00:20:32+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Merge create-pr and manage-pr skills

## Overview

The `create-pr` and `manage-pr` skills have significant overlap and unclear separation of concerns. The `create-pr` skill handles title derivation and calls the same shell script as `manage-pr`. The `manage-pr` skill is purely a wrapper around the shell script. These should be merged into a single `create-pr` skill that handles both title derivation and PR operations.

## Key Files

- `plugins/core/skills/create-pr/SKILL.md` - Skill to retain and expand
- `plugins/core/skills/manage-pr/SKILL.md` - Skill to merge into create-pr
- `plugins/core/skills/manage-pr/sh/create-or-update.sh` - Shell script to move
- `plugins/core/agents/pr-creator.md` - Agent that references both skills

## Related History

The pr-creator agent and its skills were created recently to extract PR logic from the report command. The shell script approach was adopted to avoid HEREDOC escaping issues.

Past tickets that touched similar areas:

- `20260127015712-robust-pr-creator.md` - Simplified pr-creator to use `--body-file` approach (same files)
- `20260127005601-pr-creator-subagent.md` - Created pr-creator agent and extracted PR logic (same files)

## Implementation Steps

1. **Move shell script to create-pr directory**:
   - Move `plugins/core/skills/manage-pr/sh/create-or-update.sh` to `plugins/core/skills/create-pr/sh/create-or-update.sh`

2. **Merge manage-pr content into create-pr**:
   - Keep the title derivation section from create-pr
   - Update the script path reference to `.claude/skills/create-pr/sh/create-or-update.sh`
   - Add the "What the Script Does" section from manage-pr for clarity
   - Keep the output format documentation

3. **Update pr-creator agent**:
   - Remove `manage-pr` from skills list (only `create-pr` needed)
   - Update any references in instructions if needed

4. **Delete manage-pr skill directory**:
   - Remove `plugins/core/skills/manage-pr/` entirely

## Considerations

- The create-pr skill path in the shell script reference will change from `manage-pr` to `create-pr`
- The pr-creator agent will only preload one skill instead of two, simplifying its configuration
- Verify no other files reference `manage-pr` after deletion
