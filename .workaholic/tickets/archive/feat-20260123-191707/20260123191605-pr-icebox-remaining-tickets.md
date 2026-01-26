# Warn and Icebox Remaining Tickets on PR Creation

## Overview

When creating a pull request with `/pull-request`, any remaining unfinished tickets in `.workaholic/tickets/` should not be silently ignored. The command should warn the user and automatically move these tickets to the icebox directory, ensuring no work is accidentally lost or forgotten.

This improves workflow hygiene by explicitly handling deferred work rather than leaving tickets in an ambiguous state after a PR is created.

## Key Files

- `plugins/core/commands/pull-request.md` - Main PR command that needs modification
- `.workaholic/tickets/` - Source of queued tickets to check
- `.workaholic/tickets/icebox/` - Destination for deferred tickets

## Implementation Steps

1. Add a new step at the beginning of the pull-request command (before CHANGELOG consolidation) to check for remaining tickets:

   - List files in `.workaholic/tickets/*.md` (excluding README.md)
   - If any tickets exist, proceed to step 2
   - If no tickets, continue with normal PR flow

2. Display a warning to the user listing the remaining tickets:

   - Show the count and filenames of unfinished tickets
   - Inform user these will be moved to icebox

3. Automatically move remaining tickets to icebox:

   - Create `.workaholic/tickets/icebox/` if it doesn't exist
   - Move each ticket file to the icebox directory
   - Stage and commit: "Move remaining tickets to icebox"

4. Continue with the normal PR creation flow

## Considerations

- The warning should be visible but not block the PR creation (automatic icebox, not interactive)
- README.md in `.workaholic/tickets/` should not be treated as a ticket
- If icebox directory doesn't exist, create it
- The commit message should clearly indicate why tickets were moved
- This happens early in the PR flow so the icebox commit appears before CHANGELOG/docs commits

## Final Report

Development completed as planned.
