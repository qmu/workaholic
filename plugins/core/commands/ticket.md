---
name: ticket
description: Explore codebase and write implementation ticket for `$ARGUMENT`
skills:
  - ticket-format
---

# Ticket

Explore the codebase to understand requirements and write an implementation ticket.

## Instructions

1. **Understand the Request**

   - Parse `$ARGUMENT` to understand what the user wants to implement
   - If `$ARGUMENT` is empty, ask the user what they want to ticket
   - If `$ARGUMENT` contains "icebox", store in `.workaholic/tickets/icebox/` instead

2. **Explore the Codebase**

   - Use Glob, Grep, and Read tools to find relevant files
   - Understand existing patterns, architecture, and conventions
   - Identify files that will need to be modified or created

3. **Ask Clarifying Questions**

   - Use AskUserQuestion tool if requirements are ambiguous
   - Clarify scope, approach preferences, or technical decisions
   - Don't ask obvious questions - use your judgment for reasonable defaults

4. **Write the Ticket**

   - Create a ticket file in `.workaholic/tickets/` (or `.workaholic/tickets/icebox/` for icebox)
   - Follow the preloaded ticket-format skill for structure and conventions
   - Use the Write tool directly - it creates parent directories automatically

5. **Commit the Ticket**

   **IMPORTANT**: Skip this step if invoked during `/drive`. The drive command's archive script includes uncommitted tickets via `git add -A`, so the ticket will be committed with the implementation.

   - Stage only the newly created ticket file: `git add <ticket-path>`
   - Commit with message: "Add ticket for <short-description>"

6. **Present the Ticket**

   - Show the user where the ticket was created
   - Summarize the key points
   - If during `/drive`: say "Ticket created (will be committed with implementation)"
   - If icebox: tell user to run `/drive icebox` later to retrieve it
   - If normal (standalone): count queued tickets in `.workaholic/tickets/` (excluding archive/, icebox/) and tell user to run `/drive` to implement
   - **NEVER ask "Would you like me to proceed with implementation?" - that is NOT your job**

## Notes

- Focus on the "why" and "what", not just "how"
- Keep implementation steps actionable and specific
- Reference existing code patterns when applicable
