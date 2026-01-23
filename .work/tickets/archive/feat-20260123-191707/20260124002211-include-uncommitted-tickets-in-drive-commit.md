# Include Uncommitted Tickets in Drive Commit

## Overview

When user approves an implementation during `/drive`, include any uncommitted ticket files (from recent `/ticket` runs) in the same commit. Currently, ticket files created by `/ticket` remain uncommitted until the user explicitly commits them, which adds unnecessary commit noise. Since `/drive` already commits via `git add -A`, uncommitted tickets are included but this behavior isn't documented. This ticket clarifies and formalizes this behavior.

## Key Files

- `plugins/core/commands/drive.md` - Document that uncommitted tickets are included in drive commits
- `plugins/tdd/commands/ticket.md` - Clarify that tickets don't need immediate commits

## Implementation Steps

1. **Update `plugins/tdd/commands/ticket.md`** - Add a note in the "Present the Ticket" section:
   ```markdown
   - Note: The ticket file doesn't need to be committed separately. It will be included
     in the next `/drive` commit automatically when implementation is approved.
   ```

2. **Update `plugins/core/commands/drive.md`** - Add clarification in section 2.5 (Commit and Archive):
   ```markdown
   **Note**: The archive script uses `git add -A`, which includes:
   - All implementation changes
   - The archived ticket file
   - Any uncommitted ticket files in `.work/tickets/`
   - CHANGELOG updates

   This means newly created tickets are automatically included in drive commits,
   eliminating the need for separate "add tickets" commits.
   ```

3. **Verify archive.sh behavior** - The script already uses `git add -A` (line 86), so no script changes needed. The behavior is already correct; this ticket just documents it.

## Considerations

- **Already implemented**: The `git add -A` in `archive.sh` already includes uncommitted tickets. This ticket is primarily about documentation and user awareness.
- **Atomic commits**: This keeps commits focused on implementation work while still capturing related ticket creation.
- **No separate commit noise**: Users won't see commits like "Add ticket for feature X" cluttering history.
- **Edge case**: If user wants tickets committed separately (e.g., for collaboration before implementation), they can manually `git add` and commit them.

## Final Report

Development completed as planned.
