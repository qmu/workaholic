---
created_at: 2026-01-27T20:25:25+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.1h
commit_hash: 9eb29c8
category: Added
---

# Add summary paragraph to Related History section

## Overview

Enhance the Related History section in tickets to include a brief summary paragraph before the bullet list of related tickets. This summary provides a narrative overview of the historical context, helping implementers quickly understand the evolution of the area they're working on without having to read each linked ticket.

## Key Files

- `plugins/core/commands/ticket.md` - Update Related History section format to include summary paragraph

## Related History

Past tickets that touched similar areas:

The Related History feature was recently added to provide context about past work. This enhancement builds directly on that foundation by adding a synthesis layer.

- `20260127101903-add-related-history-to-tickets.md` - Added the Related History section (same file, direct predecessor)

## Implementation Steps

1. Update `plugins/core/commands/ticket.md` step 5 (Write the Ticket) to show the new format:

   ```markdown
   ## Related History

   <1-2 sentence summary synthesizing what the historical tickets reveal about this area>

   Past tickets that touched similar areas:

   - `<ticket-file>` - <brief description> (<match reason>)
   ```

2. Update step 3 (Find Related History) to add guidance for generating the summary:
   - After finding related tickets, synthesize a brief summary (1-2 sentences)
   - Focus on patterns: what aspects of this area have been modified before, what challenges were encountered, what direction the changes have taken
   - Keep it actionable: help the implementer understand what to watch out for

## Considerations

- The summary should be concise (1-2 sentences max) to maintain scannability
- If only 1 related ticket is found, the summary can be very brief or omitted
- The summary should add value beyond just listing tickets - it should synthesize insights
- Avoid generic summaries; each should provide specific context relevant to the current ticket

## Final Report

Development completed as planned.
