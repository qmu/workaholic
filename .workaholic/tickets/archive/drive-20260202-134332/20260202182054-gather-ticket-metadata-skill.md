---
created_at: 2026-02-02T18:20:54+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 0.25h
commit_hash: 5b3d1ea
category: Changed
---

# Gather Ticket Metadata Skill

## Overview

Encapsulate ticket metadata gathering (created_at timestamp, author email, filename timestamp) into a new skill with a single shell script. Currently, the create-ticket skill instructs users to run multiple separate bash commands to gather this information, causing multiple permission prompts when ticket-organizer runs. A single bundled shell script that outputs all metadata in one call will eliminate these prompts.

## Key Files

- `plugins/core/skills/gather-ticket-metadata/SKILL.md` - New skill definition (create)
- `plugins/core/skills/gather-ticket-metadata/sh/gather.sh` - Shell script that outputs all metadata (create)
- `plugins/core/skills/create-ticket/SKILL.md` - Update to reference gather-ticket-metadata skill
- `plugins/core/agents/ticket-organizer.md` - Add gather-ticket-metadata to skills list

## Related History

Historical tickets established the pattern of bundling shell scripts into skills to avoid permission prompts and improve UX.

Past tickets that touched similar areas:

- [20260127193706-bundle-shell-scripts-for-permission-free-skills.md](.workaholic/tickets/archive/feat-20260126-214833/20260127193706-bundle-shell-scripts-for-permission-free-skills.md) - Established bundled script pattern for permission-free execution
- [20260128002536-extract-create-branch-skill.md](.workaholic/tickets/archive/feat-20260128-001720/20260128002536-extract-create-branch-skill.md) - Extracted branch creation into skill with shell script
- [20260131192725-improve-create-ticket-frontmatter-clarity.md](.workaholic/tickets/archive/feat-20260131-125844/20260131192725-improve-create-ticket-frontmatter-clarity.md) - Previous improvement to create-ticket frontmatter guidance

## Implementation Steps

1. **Create gather-ticket-metadata skill directory and SKILL.md**:
   - Create `plugins/core/skills/gather-ticket-metadata/SKILL.md`
   - Frontmatter: `name: gather-ticket-metadata`, `description: Gather ticket metadata in one call`, `allowed-tools: Bash`, `user-invocable: false`
   - Document the script output format

2. **Create shell script** at `plugins/core/skills/gather-ticket-metadata/sh/gather.sh`:
   ```bash
   #!/bin/sh -eu
   # Gather ticket metadata for frontmatter in one call
   # Outputs JSON with all needed values

   set -eu

   CREATED_AT=$(date -Iseconds)
   AUTHOR=$(git config user.email)
   FILENAME_TS=$(date +%Y%m%d%H%M%S)

   cat <<EOF
   {
     "created_at": "${CREATED_AT}",
     "author": "${AUTHOR}",
     "filename_timestamp": "${FILENAME_TS}"
   }
   EOF
   ```

3. **Update create-ticket skill** at `plugins/core/skills/create-ticket/SKILL.md`:
   - Replace Step 1 bash commands with reference to gather-ticket-metadata script:
     ```bash
     bash .claude/skills/gather-ticket-metadata/sh/gather.sh
     ```
   - Update documentation to show parsing JSON output instead of individual commands
   - Keep the rest of the skill unchanged

4. **Update ticket-organizer agent** at `plugins/core/agents/ticket-organizer.md`:
   - Add `gather-ticket-metadata` to the skills list in frontmatter (alongside create-ticket)
   - This ensures the skill is preloaded and the script is accessible

## Considerations

- **Single permission prompt**: The key benefit is reducing multiple bash permission prompts to one (or zero if bundled scripts are auto-approved)
- **JSON output format**: Using JSON allows easy parsing and future extensibility
- **Skill composition**: gather-ticket-metadata is used by create-ticket, following the allowed skill-to-skill nesting pattern
- **Backward compatibility**: The create-ticket skill will work the same way, just with a different method for gathering values

## Final Report

Implemented as specified. Created gather-ticket-metadata skill with shell script outputting JSON containing created_at, author, and filename_timestamp. Updated create-ticket skill to reference the new script and added skill composition in frontmatter. Updated ticket-organizer to preload the new skill.
