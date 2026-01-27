---
name: ticket
description: Explore codebase and write implementation ticket for `$ARGUMENT`
skills:
  - create-ticket
---

# Ticket

Explore the codebase to understand requirements and write an implementation ticket.

## Instructions

1. **Understand the Request**

   - Parse `$ARGUMENT` to understand what the user wants to implement
   - If `$ARGUMENT` is empty, ask the user what they want to ticket
   - If `$ARGUMENT` contains "icebox", store in `.workaholic/tickets/icebox/` instead
   - Otherwise, store in `.workaholic/tickets/todo/`

2. **Explore and Write Ticket**

   Follow the preloaded create-ticket skill for exploration, related history, file format, and content guidelines.

3. **Ask Clarifying Questions** if requirements are ambiguous.

4. **Commit the Ticket**

   **IMPORTANT**: Skip this step if invoked during `/drive`. The drive command's archive script includes uncommitted tickets via `git add -A`, so the ticket will be committed with the implementation.

   - Stage only the newly created ticket file: `git add <ticket-path>`
   - Commit with message: "Add ticket for <short-description>"

5. **Present the Ticket**

   - Show the user where the ticket was created
   - Summarize the key points
   - If during `/drive`: say "Ticket created (will be committed with implementation)"
   - If icebox: tell user to run `/drive icebox` later to retrieve it
   - If normal (standalone): count queued tickets and tell user to run `/drive` to implement
   - **NEVER ask "Would you like me to proceed with implementation?" - that is NOT your job**
