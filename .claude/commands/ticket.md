---
name: ticket
description: Explore codebase and write implementation spec for `$ARGUMENT`
---

# Ticket

Explore the codebase to understand requirements and write an implementation spec.

## Instructions

1. **Understand the Request**

   - Parse `$ARGUMENT` to understand what the user wants to implement
   - If `$ARGUMENT` is empty, ask the user what they want to spec
   - **Icebox Support**: If `$ARGUMENT` contains "icebox", the spec will be stored in `doc/specs/icebox/` for later consideration instead of the main queue

2. **Explore the Codebase**

   - Use Glob, Grep, and Read tools to find relevant files
   - Understand existing patterns, architecture, and conventions
   - Identify files that will need to be modified or created

3. **Ask Clarifying Questions**

   - Use AskUserQuestion tool if requirements are ambiguous
   - Clarify scope, approach preferences, or technical decisions
   - Don't ask obvious questions - use your judgment for reasonable defaults

4. **Write the Spec**

   - Create a spec file with a descriptive filename
   - **Location**:
     - Normal: `doc/specs/`
     - Icebox: `doc/specs/icebox/` (when "icebox" is in `$ARGUMENT`)
   - Filename format: `YYYYMMDDHHmmss-<short-description>.md`
   - Use current timestamp: `date +%Y%m%d%H%M%S`
   - Example: `20260114153042-add-dark-mode.md`

5. **Spec File Structure**

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

6. **Present the Spec**
   - Show the user where the spec was saved
   - Summarize the key points
   - **If icebox**: Tell user the spec was added to icebox and can be retrieved later with `/drive icebox`
   - **If normal**: Count and report the number of queued specs in `doc/specs/` (excluding archive/ and icebox/)
   - Tell user to run `/drive` to implement queued specs
   - **NEVER ask "Would you like me to proceed with implementation?" - that is NOT your job**

## Notes

- Focus on the "why" and "what", not just "how"
- Keep implementation steps actionable and specific
- Reference existing code patterns when applicable
