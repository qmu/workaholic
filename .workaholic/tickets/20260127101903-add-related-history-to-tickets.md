---
created_at: 2026-01-27T10:19:03+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Add related history section to ticket creation

## Overview

When creating a new ticket, search the archived tickets to find past tickets that may be related to the current one. Display these as a "Related History" section in the ticket, providing context about previous work in the same area. This helps implementers understand the evolution of a feature or file and avoid repeating past mistakes.

## Key Files

- `plugins/core/commands/ticket.md` - Add instructions for generating related history section

## Implementation Steps

1. Update `plugins/core/commands/ticket.md` to add a new step between "Explore the Codebase" (step 2) and "Ask Clarifying Questions" (step 3):

   ```markdown
   3. **Find Related History**

      - Search archived tickets in `.workaholic/tickets/archive/` for related past work
      - Match by:
        - **Key Files overlap**: Tickets that modified the same files
        - **Layer match**: Tickets with the same layer (e.g., Config, UX)
        - **Keyword similarity**: Tickets with similar terms in title/overview
      - List the top 3-5 most relevant tickets (most recent first if equal relevance)
   ```

2. Update the ticket file structure (step 5) to include a "Related History" section after "Key Files":

   ```markdown
   ## Related History

   Past tickets that touched similar areas:

   - `20260127010716-rename-terminology-to-terms.md` - Renamed terminology directory (same layer: Config)
   - `20260125113858-auto-commit-ticket-on-creation.md` - Modified ticket.md (same file)
   ```

3. Add notes clarifying the matching criteria:
   - Prioritize file overlap (strongest signal)
   - Then layer match
   - Finally keyword matching (weakest signal)
   - If no related tickets found, omit the section entirely (don't write "None found")

## Considerations

- Keep the list concise (3-5 tickets max) to avoid noise
- Recent tickets are more valuable than old ones - sort by date when relevance is equal
- File path matching should be flexible (e.g., match `ticket.md` to `commands/ticket.md`)
- This adds exploration overhead during ticket creation, but the context value justifies it
- Consider caching or indexing archived tickets if performance becomes an issue (future enhancement)
