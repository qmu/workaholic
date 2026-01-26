---
date: 2026-01-25
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash: 455ed62
category: Added
---

# Auto-commit ticket file on creation

## Overview

After the `/ticket` command creates a ticket file, it should immediately commit that specific file without including other pending changes in the working directory. This ensures tickets are tracked in git history immediately upon creation, making it easier to see when work was planned and providing a clean separation between ticket creation and implementation work.

## Key Files

- `plugins/core/commands/ticket.md` - Add commit step after writing ticket file

## Implementation Steps

1. **Add step 6 "Commit the Ticket"** after writing the ticket file (current step 4):

   ```markdown
   6. **Commit the Ticket**
      - Stage only the newly created ticket file: `git add <ticket-path>`
      - Commit with message: "Add ticket for <short-description>"
      - Use the ticket's H1 title for the description
      - Example: `git add .work/tickets/20260125-add-auth.md && git commit -m "Add ticket for user authentication"`
   ```

2. **Update step 7 "Present the Ticket"** (previously step 6):

   - Remove the note about tickets being included in next `/drive` commit
   - Update to mention the ticket was committed
   - Change the wording from "ticket was saved" to "ticket was created and committed"

3. **Update the Notes section** if needed to reflect the new behavior

## Considerations

- **Selective staging**: Using `git add <specific-file>` instead of `git add -A` ensures only the ticket file is committed, leaving other work-in-progress changes unstaged
- **Clean history**: Each ticket creation becomes a distinct commit, making it easy to trace when work items were planned
- **Conflict with drive behavior**: The drive command's archive script uses `git add -A`. This is still correct because at drive time, we want to include implementation changes. The ticket commit happens earlier, before implementation begins.
- **Commit message format**: Following existing conventions - no prefix, present-tense verb ("Add ticket for...")

## Final Report

Implemented auto-commit for ticket files on creation:

1. Added step 6 "Commit the Ticket" to `plugins/core/commands/ticket.md`:
   - Stage only the ticket file with `git add <ticket-path>`
   - Commit with message "Add ticket for <description>"
   - Includes example command

2. Updated step 7 "Present the Ticket":
   - Changed wording from "saved" to "created and committed"
   - Removed the note about tickets being included in next `/drive` commit

This ensures tickets are immediately tracked in git history upon creation, providing clean separation between planning and implementation commits.
