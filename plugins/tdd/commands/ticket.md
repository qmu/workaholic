---
name: ticket
description: Explore codebase and write implementation ticket for `$ARGUMENT`
---

# Ticket

Explore the codebase to understand requirements and write an implementation ticket.

## Instructions

1. **Understand the Request**

   - Parse `$ARGUMENT` to understand what the user wants to implement
   - If `$ARGUMENT` is empty, ask the user what they want to ticket
   - If `$ARGUMENT` contains "icebox", store in `work/tickets/icebox/` instead

2. **Explore the Codebase**

   - Use Glob, Grep, and Read tools to find relevant files
   - Understand existing patterns, architecture, and conventions
   - Identify files that will need to be modified or created

3. **Ask Clarifying Questions**

   - Use AskUserQuestion tool if requirements are ambiguous
   - Clarify scope, approach preferences, or technical decisions
   - Don't ask obvious questions - use your judgment for reasonable defaults

4. **Write the Ticket**

   - Create a ticket file in `work/tickets/` (or `work/tickets/icebox/` for icebox) with a descriptive filename
   - Filename format: `YYYYMMDDHHmmss-<short-description>.md`
   - Use current timestamp: `date +%Y%m%d%H%M%S`
   - Example: `20260114153042-add-dark-mode.md`
   - Use the Write tool directly - it creates parent directories automatically, no explicit `mkdir` needed

5. **Ticket File Structure**

   ```markdown
   # <Title>

   ## Overview

   <Brief description of what will be implemented>

   ## Key Files

   - `path/to/file.ts` - <why this file is relevant>

   ## Implementation Steps

   1. <Step 1>
   2. <Step 2>
      ...

   ## Considerations

   - <Any trade-offs, risks, or things to watch out for>
   ```

6. **Present the Ticket**
   - Show the user where the ticket was saved
   - Summarize the key points
   - If icebox: tell user to run `/drive icebox` later to retrieve it
   - If normal: count queued tickets in `work/tickets/` (excluding archive/, icebox/)
   - Tell user to run `/drive` to implement queued tickets
   - **NEVER ask "Would you like me to proceed with implementation?" - that is NOT your job**

## Notes

- Focus on the "why" and "what", not just "how"
- Keep implementation steps actionable and ticketific
- Reference existing code patterns when applicable
