# Add Ticket-Update-First Guidance to TDD Topic

## Overview

Update the workaholic-advisor's TDD topic documentation to emphasize the "update ticket first" pattern when implementation changes are requested during `/drive`. This ensures archived tickets always reflect what was actually implemented, serving as accurate documentation.

## Key Files

- `plugins/workaholic/skills/workaholic-advisor/topics/tdd.md` - TDD workflow topic that needs the guidance added
- `plugins/workaholic/skills/workaholic-advisor/templates/drive-command.md` - Already contains the pattern (lines 109-113)

## Implementation Steps

1. **Add a new section to `topics/tdd.md` explaining the ticket-update-first pattern**
   - Add after the "Workflow" section
   - Title: "## Feedback Loop"
   - Explain that when implementation is not approved:
     1. Update the ticket file first with the new/changed steps
     2. Then implement the changes
     3. Ask for review again
   - Emphasize: "This ensures archived tickets always reflect the final implementation"

2. **Include a visual workflow example showing the feedback loop**
   ```
   User: [Needs changes] - "Add error handling for edge case X"
   Claude: [Updates ticket with new step for error handling]
   Claude: [Implements error handling]
   Claude: [Asks for review again]
   ```

3. **Add a "Why This Matters" explanation**
   - Archived tickets become project documentation
   - Fresh tickets = accurate history of what was built
   - Helps future developers understand the full scope of changes

## Considerations

- The drive-command.md template already has this pattern - this ticket adds visibility in the topic overview
- Keep the addition concise to match the existing tdd.md style
- The topic file is used by workaholic-advisor to explain concepts, so clarity is important
