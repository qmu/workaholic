---
name: ticket
description: Explore codebase and write implementation ticket for `$ARGUMENT`
skills:
  - create-ticket
  - create-branch
---

# Ticket

Explore the codebase to understand requirements and write an implementation ticket.

## Instructions

0. **Check Branch**

   Check current branch: `git branch --show-current`

   If on `main` or `master` (not a topic branch):
   1. Ask user for branch prefix (feat/fix/refact) via AskUserQuestion
   2. Run: `bash .claude/skills/create-branch/sh/create.sh <prefix>`
   3. Confirm: "Created branch: <branch-name>"
   4. Continue to step 1

   Topic branch pattern: `feat-*`, `fix-*`, `refact-*`

1. **Understand the Request**

   - Parse `$ARGUMENT` to understand what the user wants to implement
   - If `$ARGUMENT` is empty, ask the user what they want to ticket
   - If `$ARGUMENT` contains "icebox", store in `.workaholic/tickets/icebox/` instead
   - Otherwise, store in `.workaholic/tickets/todo/`

2. **Discover Related History**

   Use Task tool to invoke history-discoverer subagent with `model: "haiku"`:
   - Extract 3-5 keywords: file basenames from Key Files + domain terms from request
   - Pass keywords to subagent
   - Receive JSON with summary and related tickets
   - Use results to populate Related History section

   Example prompt: "Find related tickets for keywords: ticket.md drive.md branch archive Config"

3. **Explore and Write Ticket**

   Follow the preloaded create-ticket skill for exploration, file format, and content guidelines.
   Insert the Related History data from step 2.

4. **Ask Clarifying Questions** if requirements are ambiguous.

5. **Commit the Ticket**

   **IMPORTANT**: Skip this step if invoked during `/drive`. The drive command's archive script includes uncommitted tickets via `git add -A`, so the ticket will be committed with the implementation.

   - Stage only the newly created ticket file: `git add <ticket-path>`
   - Commit with message: "Add ticket for <short-description>"

6. **Present the Ticket**

   - Show the user where the ticket was created
   - Summarize the key points
   - If during `/drive`: say "Ticket created (will be committed with implementation)"
   - If icebox: tell user to run `/drive icebox` later to retrieve it
   - If normal (standalone): count queued tickets and tell user to run `/drive` to implement
   - **NEVER ask "Would you like me to proceed with implementation?" - that is NOT your job**
