---
created_at: 2026-02-02T20:47:53+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Add Shell Script to create-branch Skill

## Overview

The `create-branch` skill currently contains inline bash instructions in SKILL.md. Following the architecture principle of "thin commands, comprehensive skills" and the pattern established by other skills (e.g., `gather-ticket-metadata/sh/gather.sh`), this should be implemented as a bundled shell script. This enables permission-free execution and makes the logic more testable and consistent with other skills.

## Key Files

- `plugins/core/skills/create-branch/SKILL.md` - Update to reference the shell script
- `plugins/core/skills/create-branch/sh/create.sh` - New shell script (create)
- `plugins/core/agents/ticket-organizer.md` - Update to use the shell script (lines 29-31)

## Related History

Historical tickets show the evolution of branch creation: first extracted as a skill, then moved to ticket-organizer. The pattern of bundling shell scripts for permission-free execution was established and used by other skills.

Past tickets that touched similar areas:

- [20260202181910-move-create-branch-to-ticket-organizer.md](.workaholic/tickets/archive/drive-20260202-134332/20260202181910-move-create-branch-to-ticket-organizer.md) - Moved branch creation to ticket-organizer (same skill)
- [20260128002536-extract-create-branch-skill.md](.workaholic/tickets/archive/feat-20260128-001720/20260128002536-extract-create-branch-skill.md) - Created create-branch skill (same skill, proposed shell script but not implemented)
- [20260202182054-gather-ticket-metadata-skill.md](.workaholic/tickets/archive/drive-20260202-134332/20260202182054-gather-ticket-metadata-skill.md) - Created gather-ticket-metadata skill with shell script pattern to follow
- [20260127193706-bundle-shell-scripts-for-permission-free-skills.md](.workaholic/tickets/archive/feat-20260126-214833/20260127193706-bundle-shell-scripts-for-permission-free-skills.md) - Established bundled script pattern

## Implementation Steps

1. **Create shell script** at `plugins/core/skills/create-branch/sh/create.sh`:
   ```bash
   #!/bin/sh -eu
   # Create timestamped topic branch
   # Usage: create.sh [prefix]
   # Default prefix: drive
   # Output: JSON with branch name

   set -eu

   PREFIX="${1:-drive}"
   TIMESTAMP=$(date +%Y%m%d-%H%M%S)
   BRANCH="${PREFIX}-${TIMESTAMP}"

   git checkout -b "$BRANCH"

   cat <<EOF
   {
     "branch": "${BRANCH}"
   }
   EOF
   ```

2. **Update SKILL.md** to document the shell script:
   ```markdown
   ## Usage

   ```bash
   bash .claude/skills/create-branch/sh/create.sh [prefix]
   ```

   ### Arguments

   - `prefix` (optional): Branch prefix. Defaults to "drive".
     - "drive" - for TiDD style development
     - "trip" - for more AI oriented development

   ## Output

   JSON with the created branch name:

   ```json
   {
     "branch": "drive-20260202-204753"
   }
   ```
   ```

3. **Update ticket-organizer.md** step 0 to use the shell script:
   - Replace inline git command with script invocation
   - Parse JSON output to extract branch name
   ```markdown
   ### 0. Check Branch

   Check current branch: `git branch --show-current`

   If on `main` or `master` (not a topic branch):
   1. Create branch using skill script:
      ```bash
      bash .claude/skills/create-branch/sh/create.sh drive
      ```
   2. Parse JSON output to get branch name
   3. Store branch name for output JSON

   Topic branch pattern: `drive-*`, `trip-*`
   ```

## Considerations

- **JSON output format**: The shell script outputs JSON to match the pattern of `gather-ticket-metadata/sh/gather.sh`, making it easier to parse and consistent across skills
- **Default prefix**: The script defaults to "drive" prefix since ticket-organizer always uses "drive" for ticket creation branches
- **Permission-free execution**: Bundled scripts in `.claude/skills/` run without user approval prompts
- **Backward compatible**: ticket-organizer still performs the same branch creation, just using the shell script instead of inline bash
