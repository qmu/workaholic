---
date: 2026-01-24
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 0.25h
commit_hash: ba35d60---
category: Removed
# Eliminate Branch Changelogs

## Overview

Remove the `.workaholic/changelogs/` directory and store change metadata directly in ticket frontmatter. This simplifies the workflow by making tickets the single source of truth for both the change intent (Overview) and the change record (frontmatter). Stories and the root CHANGELOG are generated directly from archived tickets, eliminating an intermediate artifact.

## Key Files

- `plugins/core/skills/archive-ticket/scripts/archive.sh` - Remove changelog logic, add frontmatter fields to ticket
- `plugins/core/commands/drive.md` - Update step 2.5 to reflect new archive behavior
- `plugins/core/commands/pull-request.md` - Read tickets directly instead of changelogs
- `plugins/core/commands/ticket.md` - Add commit_hash and category fields (set at archive time)

## Implementation Steps

1. **Update ticket frontmatter schema** in `ticket.md`:

   Add fields populated at archive time:
   ```yaml
   commit_hash: <short hash, set when archived>
   category: Added | Changed | Removed
   ```

2. **Simplify archive.sh**:

   - Remove all changelog file operations
   - Instead, update ticket frontmatter with:
     - `commit_hash`: from `git rev-parse --short HEAD`
     - `category`: derived from commit message verb (Add→Added, Remove→Removed, else→Changed)
   - Keep the ticket archival logic (move to archive/<branch>/)
   - Keep the commit logic

3. **Update pull-request.md step 4** (currently "Consolidate branch CHANGELOG to root"):

   Change to: "Update root CHANGELOG from archived tickets"
   - Read all tickets from `.workaholic/tickets/archive/<branch>/*.md`
   - For each ticket, extract: title, commit_hash, category, Overview first line
   - Generate CHANGELOG entries in format: `- Title ([hash](url)) - [ticket](path)`
   - Write to root `CHANGELOG.md` under branch section

4. **Update pull-request.md step 5** (Generate branch story):

   The "Gather source data" already reads tickets. Simplify by:
   - Removing references to reading `.workaholic/changelogs/<branch>.md`
   - Using ticket frontmatter for commit hashes
   - Using ticket Overview for change descriptions

5. **Delete .workaholic/changelogs/ directory** and its README

6. **Update .workaholic/README.md** to remove changelogs reference

## Considerations

- **Migration**: Existing changelogs are not needed after this change. They can be deleted.
- **Commit hash availability**: The archive script commits first, then reads the hash. This order is already correct.
- **Single source of truth**: Tickets now contain everything needed for both stories and CHANGELOG.
- **Performance**: Faster workflow - no intermediate file writes, reads directly from tickets.

## Final Report

Development completed as planned.
