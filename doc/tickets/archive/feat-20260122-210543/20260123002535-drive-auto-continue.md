# Auto-Continue to Next Ticket After Approval

## Overview

Remove the "Continue with next ticket?" confirmation from `/drive`. After a ticket is approved and committed, immediately proceed to the next ticket without asking. The implementation approval (step 2.4) must still be required - only the between-ticket "continue?" prompt is removed.

## Key Files

- `plugins/tdd/commands/drive.md` - The drive command with the continue confirmation to remove

## Implementation Steps

1. Remove section 2.6 "Ask Before Next Ticket" entirely:
   - Delete the section that shows remaining tickets and asks Continue/Stop
   - The loop should automatically proceed to the next ticket after commit

2. Update section 2.5 to note auto-continuation:
   - After commit and archive, proceed directly to next ticket
   - No confirmation needed between tickets

3. Update the Example Workflow to reflect new flow:
   - Remove the "Continue with next ticket? [Continue / Stop]" prompt
   - Show direct transition: commit → next ticket implementation

4. Update the Notes section:
   - Clarify that approval confirmation (step 2.4) is still mandatory
   - Note that only the between-ticket continuation is automatic

## Considerations

- User can still stop by responding "Needs changes" at approval and then asking to stop
- The approval step remains the control point for user intervention
- This speeds up the workflow when processing multiple tickets
