# Add Final Report Section to Ticket Before Commit

## Overview

When `/drive` completes a ticket implementation, add a "Final Report" section to the ticket file before archiving. This captures the final decision and any deviations from the original plan. If implementation went as planned, state "Development completed as planned." If the user requested changes during review, document the changes with reasons.

## Key Files

- `plugins/tdd/commands/drive.md` - Add instruction to write final report before commit

## Implementation Steps

1. **Update `plugins/tdd/commands/drive.md`** section 2.4 (after approval, before commit):

   Add new step: "Write Final Report to ticket"

   ````markdown
   #### 2.4.1 Write Final Report

   After user approves, append a "## Final Report" section to the ticket file:

   **If no changes were requested:**

   ```markdown
   ## Final Report

   Development completed as planned.
   ```
   ````

   **If user requested changes:**

   ```markdown
   ## Final Report

   Implementation deviated from original plan:

   - **Change**: <what was changed>
     **Reason**: <why the user requested this change>

   - **Change**: <another change>
     **Reason**: <reason>
   ```

   This creates a historical record of decisions made during implementation.

   ```

   ```

2. **Update the workflow description** to clarify:
   - The ticket file is updated twice: once for plan changes (step 2.4), once for final report
   - Final report is written after approval, before archive-ticket script

## Considerations

- Final report provides context for future reference when reading archived tickets
- Keeps the ticket as a complete record of what was planned vs what was implemented
- Short and simple when no changes; detailed when deviations occurred
