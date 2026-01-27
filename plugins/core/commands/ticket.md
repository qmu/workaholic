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

3. **Find Related History**

   Search archived tickets in `.workaholic/tickets/archive/` for related past work. Match by:

   - **Key Files overlap** (strongest signal): Tickets that modified the same files
   - **Layer match**: Tickets with the same layer (e.g., Config, UX)
   - **Keyword similarity** (weakest signal): Tickets with similar terms in title/overview

   List the top 3-5 most relevant tickets (most recent first if equal relevance). If no related tickets found, omit the Related History section entirely.

4. **Ask Clarifying Questions**

   - Use AskUserQuestion tool if requirements are ambiguous
   - Clarify scope, approach preferences, or technical decisions
   - Don't ask obvious questions - use your judgment for reasonable defaults

5. **Write the Ticket**

   - Create a ticket file in `.workaholic/tickets/` (or `.workaholic/tickets/icebox/` for icebox)
   - Follow the preloaded ticket-format skill for structure and conventions
   - Include a "Related History" section after "Key Files" if related tickets were found:
     ```markdown
     ## Related History

     Past tickets that touched similar areas:

     - `20260127010716-rename-terminology-to-terms.md` - Renamed terminology directory (same layer: Config)
     - `20260125113858-auto-commit-ticket-on-creation.md` - Modified ticket.md (same file)
     ```
   - Use the Write tool directly - it creates parent directories automatically

6. **Commit the Ticket**

   **IMPORTANT**: Skip this step if invoked during `/drive`. The drive command's archive script includes uncommitted tickets via `git add -A`, so the ticket will be committed with the implementation.

   - Stage only the newly created ticket file: `git add <ticket-path>`
   - Commit with message: "Add ticket for <short-description>"

7. **Present the Ticket**

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
