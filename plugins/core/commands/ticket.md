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

   - Create a ticket file in `.workaholic/tickets/` (or `.workaholic/tickets/icebox/` for icebox) with a descriptive filename
   - Filename format: `YYYYMMDDHHmmss-<short-description>.md`
   - Use current timestamp: `date +%Y%m%d%H%M%S`
   - Example: `20260114153042-add-dark-mode.md`
   - Use the Write tool directly - it creates parent directories automatically, no explicit `mkdir` needed

5. **Ticket File Structure**

   ```markdown
   ---
   created_at: YYYY-MM-DDTHH:MM:SS+TZ
   author: <git user.email>
   type: enhancement | bugfix | refactoring | housekeeping
   layer: [<layers affected>]
   effort: <filled after implementation>
   commit_hash: <filled when archived>
   category: <filled when archived>
   ---

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

   **Frontmatter Fields:**

   - `created_at`: Creation timestamp in ISO 8601 format. Use `date -Iseconds`
   - `author`: Git email. Use `git config user.email`
   - `type`: Infer from request context:
     - `enhancement` - New features or capabilities (keywords: add, create, implement, new)
     - `bugfix` - Fixing broken behavior (keywords: fix, bug, broken, error)
     - `refactoring` - Restructuring without changing behavior (keywords: refactor, restructure, reorganize)
     - `housekeeping` - Maintenance, cleanup, documentation (keywords: clean, update, remove, deprecate)
   - `layer`: Architectural layers affected (YAML array, can specify multiple):
     - `UX` - User interface, components, styling
     - `Domain` - Business logic, models, services
     - `Infrastructure` - External integrations, APIs, networking
     - `DB` - Database, storage, migrations
     - `Config` - Configuration, build, tooling
   - `effort`: Time spent on implementation. Leave as placeholder when creating ticket; filled in after implementation (e.g., 0.1h, 0.25h, 0.5h, 1h, 2h)
   - `commit_hash`: Short git commit hash. Set automatically by archive script after commit.
   - `category`: Change category (Added, Changed, or Removed). Set automatically by archive script based on commit message verb.
   - Only ask the user about type if truly ambiguous

6. **Commit the Ticket**

   **IMPORTANT**: Skip this step if invoked during `/drive`. The drive command's archive script includes uncommitted tickets via `git add -A`, so the ticket will be committed with the implementation.

   - Stage only the newly created ticket file: `git add <ticket-path>`
   - Commit with message: "Add ticket for <short-description>"
   - Use the ticket's H1 title for the description
   - Example: `git add .workaholic/tickets/20260125-add-auth.md && git commit -m "Add ticket for user authentication"`

7. **Present the Ticket**

   - Show the user where the ticket was created
   - Summarize the key points
   - If during `/drive`: say "Ticket created (will be committed with implementation)"
   - If icebox: tell user to run `/drive icebox` later to retrieve it
   - If normal (standalone): count queued tickets in `.workaholic/tickets/` (excluding archive/, icebox/) and tell user to run `/drive` to implement
   - **NEVER ask "Would you like me to proceed with implementation?" - that is NOT your job**

## Notes

- Focus on the "why" and "what", not just "how"
- Keep implementation steps actionable and ticketific
- Reference existing code patterns when applicable
