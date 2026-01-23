# Show Ticket Title and Summary in Drive Approval Prompt

## Overview

When `/drive` asks for approval, the user needs context about which ticket is being reviewed. The approval prompt should display the ticket title and a brief summary of the Overview section, so users can make informed decisions without re-reading the full ticket.

## Key Files

- `plugins/tdd/commands/drive.md` - The drive command that needs to show ticket context in approval prompts

## Implementation Steps

1. Update section 2.4 "Ask User to Review Implementation" to include ticket context:

   - Show the ticket title (H1 heading from ticket file)
   - Show summarized description (first sentence or two from Overview section)
   - Format example:

     ```
     **Ticket: Remove doc/specs/icebox Directory**
     Remove the incorrectly located icebox directory since it should be under doc/tickets/.

     Implementation complete. Changes made:
     - Deleted doc/specs/icebox/.gitkeep

     Do you approve this implementation?
     ```

2. Update the Example Workflow section to reflect the new format:
   - Change the approval prompt example to show ticket title and summary

## Considerations

- Keep the summary brief (1-2 sentences) to avoid cluttering the approval prompt
- The title comes from the `# <Title>` H1 heading in the ticket
- The summary comes from the `## Overview` section's first paragraph
