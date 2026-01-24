# Fix /pull-request to Always Complete and Display URL

## Overview

The `/pull-request` command often stops mid-execution to ask for confirmation (e.g., "Should I continue with the PR workflow?") instead of running to completion. It also doesn't always display the PR URL at the end. This breaks the expected workflow where the command should execute autonomously and provide the final result.

## Key Files

- `plugins/core/commands/pull-request.md` - The pull-request command definition that needs updating

## Implementation Steps

1. Add a "Critical Behavior" section at the top of the instructions that explicitly states:
   - NEVER stop to ask "Should I continue?" or "Would you like me to proceed?"
   - NEVER ask for confirmation between steps
   - Execute ALL steps in sequence without pausing
   - ALWAYS update or create the PR at the end
   - ALWAYS display the PR URL when finished

2. Update step 5 (Sync documentation) to add: "Do NOT ask for confirmation - continue immediately"

3. Add a "Completion Output (MANDATORY)" section after the "Creating vs Updating" section that specifies:
   - After creating or updating the PR, ALWAYS display: `PR updated: <PR-URL>` or `PR created: <PR-URL>`
   - This URL display is mandatory - the command is not complete without it

## Considerations

- The `/sync-src-doc` sub-command might be the source of the pause - ensure the pull-request command makes it clear that sub-commands should not interrupt the flow
- The instruction style should be imperative and unambiguous to prevent LLM interpretation that leads to asking for confirmation
