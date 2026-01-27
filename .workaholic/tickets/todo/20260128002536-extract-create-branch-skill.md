---
created_at: 2026-01-28T00:25:36+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Extract create-branch skill from branch command

## Overview

The `/branch` command currently contains inline instructions for creating a timestamped branch. Extract this into a `create-branch` skill with a bundled shell script, following the established pattern used by other skills like `archive-ticket` and `create-pr`.

This enables permission-free execution (bundled scripts don't require user approval) and makes the branch creation logic reusable by other commands or agents.

## Key Files

- `plugins/core/commands/branch.md` - Command to simplify by referencing skill
- `plugins/core/skills/create-branch/SKILL.md` - New skill definition (create)
- `plugins/core/skills/create-branch/sh/create.sh` - New shell script (create)

## Related History

The pattern of bundling shell scripts into skills for permission-free execution was established to avoid user prompts.

Past tickets that touched similar areas:

- `20260127193706-bundle-shell-scripts-for-permission-free-skills.md` - Established bundled script pattern (same layer: Config)

## Implementation Steps

1. **Create skill directory and SKILL.md**:
   - Create `plugins/core/skills/create-branch/SKILL.md`
   - Add frontmatter: `name: create-branch`, `description: Create timestamped topic branch`, `allowed-tools: Bash`, `user-invocable: false`
   - Document the script usage and output format

2. **Create shell script** at `plugins/core/skills/create-branch/sh/create.sh`:
   ```bash
   #!/bin/sh -eu
   # Create timestamped topic branch
   # Usage: create.sh <prefix>
   # Example: create.sh feat

   set -eu

   PREFIX="$1"

   if [ -z "$PREFIX" ]; then
       echo "Usage: create.sh <prefix>"
       echo "Prefixes: feat, fix, refact"
       exit 1
   fi

   TIMESTAMP=$(date +%Y%m%d-%H%M%S)
   BRANCH="${PREFIX}-${TIMESTAMP}"

   git checkout -b "$BRANCH"
   echo "$BRANCH"
   ```

3. **Update branch command** to reference the skill:
   - Keep the user interaction (prefix selection via AskUserQuestion)
   - Replace inline bash with reference to skill script:
     ```bash
     bash .claude/skills/create-branch/sh/create.sh <prefix>
     ```
   - The command handles the UX, the skill handles the execution

## Considerations

- The command still owns the user interaction (asking for prefix)
- The skill handles the git operation (creating the branch)
- Script outputs the created branch name for confirmation
- Follow the same pattern as other skills with bundled scripts
