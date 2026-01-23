# Silent Linter Re-read Behavior

## Overview

Remove the automatic format hook that runs after every edit. Currently, the PostToolUse hook runs prettier after each Write/Edit, causing Claude to say "The first edit was applied and a linter formatted it. Let me read the file again and continue with the remaining edits." - this is unnecessary noise for the user.

## Key Files

- `plugins/core/hooks/hooks.json` - Remove this file (the hook configuration)
- `plugins/core/hooks/format.sh` - Remove this file (the format script)
- `plugins/core/commands/pull-request.md` - Add formatting step before PR creation

## Implementation Steps

1. Delete `plugins/core/hooks/hooks.json` - removes the PostToolUse hook trigger
2. Delete `plugins/core/hooks/format.sh` - removes the format script
3. Update `plugins/core/commands/pull-request.md` to run formatter before creating/updating PR

## Considerations

- This is a UX improvement - less noise, same functionality
- Formatting before PR ensures consistent code style in the PR
- Removes per-edit formatting overhead, formats once before PR

## Final Report

Implementation deviated from original plan:

- **Change**: Removed PostToolUse hooks instead of just adding a rule
  **Reason**: The verbose "let me read the file again" messages were caused by the format hook running after every edit. The user clarified that formatting should happen before PR creation, not during edits, so removing the hooks was the correct solution.
