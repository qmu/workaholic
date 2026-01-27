---
name: drive
description: Implement tickets from .workaholic/tickets/ one by one, commit each, and archive.
skills:
  - drive-workflow
  - archive-ticket
---

# Drive

Implement all tickets stored in `.workaholic/tickets/` from top to bottom, committing and archiving each one before moving to the next.

## Icebox Mode

If `$ARGUMENT` contains "icebox":

1. List tickets in `.workaholic/tickets/icebox/`
2. Ask user which ticket to retrieve
3. Move selected ticket to `.workaholic/tickets/`
4. Implement that ticket using the drive-workflow skill
5. **ALWAYS ask confirmation** before proceeding to next ticket

## Instructions

### 1. List and Sort Tickets

```bash
ls -1 .workaholic/tickets/*.md 2>/dev/null | sort
```

- If no tickets found, inform the user and stop
- Process tickets in alphabetical/chronological order (YYYYMMDD prefix ensures chronological)

### 2. For Each Ticket (Top to Bottom)

Follow the preloaded drive-workflow skill for each ticket:

1. Read and understand the ticket
2. Implement the ticket
3. Ask user to review (mandatory approval step)
4. Update effort and write final report
5. Commit and archive using archive-ticket skill

### 3. Completion

- After all tickets are implemented, summarize what was done
- List all commits created
- Inform user that all tickets have been processed

## Example Workflow

```
Claude: Found 3 tickets to implement:
        1. .workaholic/tickets/20260113-feature-a.md
        2. .workaholic/tickets/20260113-feature-b.md
        3. .workaholic/tickets/20260113-feature-c.md

        Starting with 20260113-feature-a.md...
        [implements feature-a]

        **Ticket: Add User Authentication**
        Implement user authentication with session-based login and logout.

        Implementation complete. Changes made:
        - Modified src/foo.ts (added function X)
        - Updated src/bar.ts (fixed Y)

        Do you approve this implementation?
        [Approve / Approve and stop / Needs changes]

User:   Approve

Claude: [creates commit, archives ticket]

        Starting with 20260113-feature-b.md...
```

## Notes

- Each ticket gets its own commit - do not batch multiple tickets
- If implementation fails, stop and report the error
- **Implementation approval is mandatory** - never skip this step
- **Final report is mandatory** - document what happened
- Between-ticket continuation is automatic - no confirmation needed
- User can stop cleanly by selecting "Approve and stop" at any approval prompt

## Critical Rules

**NEVER autonomously move tickets to icebox.** Moving tickets is a developer decision, not an AI decision.

If a ticket cannot be implemented (out of scope, too complex, blocked, or any other reason):

1. **Stop and ask the developer** using AskUserQuestion
2. Explain why implementation cannot proceed
3. Offer these options:
   - "Move to icebox" - Move ticket to `.workaholic/tickets/icebox/` and continue to next
   - "Skip for now" - Leave ticket in queue, move to next ticket
   - "Abort drive" - Stop the drive session entirely

**Never commit ticket moves without explicit developer approval.**
