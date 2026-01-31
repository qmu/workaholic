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
   1. Create branch: `git checkout -b "drive-$(date +%Y%m%d-%H%M%S)"`
   2. Confirm: "Created branch: <branch-name>"
   3. Continue to step 1

   Topic branch pattern: `drive-*`, `feat-*`, `fix-*`, `refact-*`

1. **Understand the Request**

   - Parse `$ARGUMENT` to understand what the user wants to implement
   - If `$ARGUMENT` is empty, ask the user what they want to ticket
   - If `$ARGUMENT` contains "icebox", store in `.workaholic/tickets/icebox/` instead
   - Otherwise, store in `.workaholic/tickets/todo/`

2. **Parallel Discovery**

   Invoke BOTH subagents concurrently using Task tool with `model: "haiku"`:

   **2-A. History Discovery** (history-discoverer):
   - Extract 3-5 keywords from request
   - Receive JSON: summary, tickets list, match reasons

   **2-B. Source Discovery** (source-discoverer):
   - Pass feature description and keywords
   - Receive JSON: summary, files list, code flow

   Example (single message with two Task tool calls):
   - Task 1: "Find related tickets for keywords: ticket.md drive.md parallel"
   - Task 2: "Find source files for: parallel discovery in ticket command"

   Wait for both to complete, then proceed with both results.

3. **Explore and Write Ticket**

   Follow the preloaded create-ticket skill for exploration, file format, and content guidelines.
   - Use history discovery results for "Related History" section
   - Use source discovery results to seed "Key Files" section (merge with manual exploration)
   - Reference code flow in "Implementation" section when relevant

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
