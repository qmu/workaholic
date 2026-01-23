# Document the Difference Between Specs and Tickets

## Overview

Add documentation explaining the conceptual difference between `doc/specs/` and `doc/tickets/`. Specs are a snapshot of the current state (comprehensive present situation), while tickets are change requests (past/future work log focused on specific topics).

## Key Files

- `doc/README.md` - Add explanation of specs vs tickets concept
- `plugins/tdd/rules/doc-specs.md` - Reference this concept in the rule (after merge ticket)

## Implementation Steps

1. **Update `doc/README.md`** to add a section explaining the documentation philosophy:

   ```markdown
   ## Documentation Philosophy

   ### Specs (doc/specs/)

   Specifications represent a **snapshot of the current state**. They describe what exists now - the comprehensive present situation of the project. When you read specs, you understand how things work today.

   - Always up-to-date with the current implementation
   - Comprehensive coverage of all features and architecture
   - Written as reference documentation

   ### Tickets (doc/tickets/)

   Tickets represent **change requests** - past and future. They are a working log focused on specific topics. Each ticket captures what needs to change or what has changed.

   - Queued tickets: Future work to be implemented
   - Archived tickets: Historical record of completed changes
   - Focused on the delta, not the whole picture
   ```

2. **Ensure the concept is reflected** in doc-specs rule (when merged):
   - Specs should be updated to reflect the current state after changes
   - Not just append changes, but rewrite to reflect present reality

## Considerations

- This helps contributors understand why both directories exist
- Clarifies that specs are living documents that reflect NOW
- Tickets are temporal - they capture a moment of change
