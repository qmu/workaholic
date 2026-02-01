---
name: ticket
description: Explore codebase and write implementation ticket for `$ARGUMENT`
skills:
  - create-ticket
  - create-branch
---

# Ticket

Explore the codebase to understand requirements and write implementation ticket(s). May split complex requests into multiple tickets when beneficial.

## Instructions

0. **Check Branch**

   Check current branch: `git branch --show-current`

   If on `main` or `master` (not a topic branch):
   1. Create branch: `git checkout -b "drive-$(date +%Y%m%d-%H%M%S)"`
   2. Confirm: "Created branch: <branch-name>"
   3. Continue to step 1

   Topic branch pattern: `drive-*`, `trip-*`

1. **Understand the Request**

   - Parse `$ARGUMENT` to understand what the user wants to implement
   - If `$ARGUMENT` is empty, ask the user what they want to ticket
   - If `$ARGUMENT` contains "icebox", store in `.workaholic/tickets/icebox/` instead
   - Otherwise, store in `.workaholic/tickets/todo/`

   **Evaluate Complexity**: Determine if the request should be split into multiple tickets:
   - Split when: request contains multiple independent features, touches unrelated layers, or would require multiple commits to implement cleanly
   - Keep single when: tasks are tightly coupled, share implementation context, or are small enough for one commit
   - If splitting: identify 2-4 discrete tickets, each with clear scope and a single purpose
   - Each split ticket must be independently implementable and testable

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

3. **Explore and Write Ticket(s)**

   Follow the preloaded create-ticket skill for exploration, file format, and content guidelines.
   - Use history discovery results for "Related History" section
   - Use source discovery results to seed "Key Files" section (merge with manual exploration)
   - Reference code flow in "Implementation" section when relevant

   **If splitting into multiple tickets**:
   - Create each ticket with a unique timestamp (add 1 second between files to ensure ordering)
   - First ticket should be the foundation that others may depend on
   - Cross-reference related tickets in each ticket's "Considerations" section
   - Each ticket must stand alone with complete context

4. **Ask Clarifying Questions** if requirements are ambiguous.

5. **Commit the Ticket(s)**

   **IMPORTANT**: Skip this step if invoked during `/drive`. The drive command's archive script includes uncommitted tickets via `git add -A`, so the ticket will be committed with the implementation.

   - Stage only the newly created ticket file(s): `git add <ticket-path>` (or multiple paths)
   - Commit message:
     - Single ticket: "Add ticket for <short-description>"
     - Multiple tickets: "Add tickets for <overall-description>"

6. **Present the Ticket(s)**

   - Show the user where the ticket(s) were created
   - Summarize the key points
   - **If multiple tickets**: list each ticket with a one-line summary and explain the implementation order
   - If during `/drive`: say "Ticket(s) created (will be committed with implementation)"
   - If icebox: tell user to run `/drive icebox` later to retrieve it
   - If normal (standalone): count queued tickets and tell user to run `/drive` to implement
   - **NEVER ask "Would you like me to proceed with implementation?" - that is NOT your job**
