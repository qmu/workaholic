# Organize Archived Tickets by Branch Directory

## Overview

Update the workaholic plugin to ensure archived tickets are always organized into branch-named subdirectories under `doc/tickets/archive/`, preventing flat accumulation of ticket files directly in the archive folder.

The current implementation already uses `ARCHIVE_DIR="${TICKET_DIR}/archive/${BRANCH}"`, but this ticket adds safeguards to prevent edge cases where tickets might end up directly in `archive/` without a branch subdirectory.

## Key Files

- `plugins/workaholic/skills/workaholic-advisor/templates/archive-ticket-script.sh` - Main archive script that moves tickets
- `plugins/workaholic/skills/workaholic-advisor/topics/archive-ticket.md` - Documentation for archive-ticket skill
- `plugins/workaholic/skills/workaholic-advisor/topics/tdd.md` - TDD workflow documentation showing directory structure

## Implementation Steps

1. **Add branch name validation in archive-ticket-script.sh**
   - After getting `BRANCH=$(git branch --show-current)`, check if branch is empty
   - If empty (detached HEAD or error), exit with error message asking user to checkout a branch first
   - Add validation at line ~25 after `BRANCH` assignment

2. **Update error message to be descriptive**
   - Error should explain: "Cannot archive ticket: not on a named branch. Please checkout a branch first."
   - This prevents accidental archiving to `archive//` (empty branch) or `archive/` directly

3. **Add documentation note about branch requirement**
   - Update `plugins/workaholic/skills/workaholic-advisor/topics/archive-ticket.md` to mention that archiving requires being on a named branch
   - Add a bullet point in the "How It Works" section

## Considerations

- The current script already uses the branch name correctly (`${TICKET_DIR}/archive/${BRANCH}`)
- The safeguard is primarily for edge cases (detached HEAD state, CI environments without proper checkout)
- No changes needed to `/drive` or `/pull-request` commands as they already reference `archive/<branch-name>/`
- The change is backward compatible - existing archives in branch directories remain valid
