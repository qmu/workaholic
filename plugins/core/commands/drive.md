---
name: drive
description: Implement tickets from .workaholic/tickets/ one by one, commit each, and archive.
skills:
  - drive-workflow
  - archive-ticket
---

# Drive

Implement tickets from `.workaholic/tickets/todo/` using intelligent prioritization, committing and archiving each one before moving to the next.

## Icebox Mode

If `$ARGUMENT` contains "icebox":

1. List tickets in `.workaholic/tickets/icebox/`
2. Ask user which ticket to retrieve
3. Move selected ticket to `.workaholic/tickets/todo/`
4. Implement that ticket using the drive-workflow skill
5. **ALWAYS ask confirmation** before proceeding to next ticket

## Instructions

### 1. List and Analyze Tickets

List all tickets in `.workaholic/tickets/todo/`:

```bash
ls -1 .workaholic/tickets/todo/*.md 2>/dev/null
```

**If no tickets found:**

1. Check if `.workaholic/tickets/icebox/` has tickets
2. If icebox has tickets, ask: "No queued tickets. Would you like to work on icebox tickets?"
3. If user agrees, enter icebox mode automatically
4. If icebox is also empty, inform user: "No tickets in queue or icebox."

**If tickets found:**

For each ticket, extract YAML frontmatter to get:
- `type`: bugfix > enhancement > refactoring > housekeeping (priority ranking)
- `layer`: Group related layers for context efficiency
- `effort`: Lower effort tickets may provide quick wins

### 2. Determine Priority Order

Consider these factors:
- **Severity**: Bugfixes take precedence over enhancements
- **Context grouping**: Process tickets affecting same layer/files together
- **Quick wins**: Lower-effort tickets may be prioritized for momentum
- **Dependencies**: If ticket A modifies files that ticket B reads, process A first

Handle missing metadata gracefully - default to normal priority when fields are absent.

### 3. Present Prioritized List

Show tickets grouped by priority tier:

```
Found 4 tickets to implement:

**High Priority (bugfix)**
1. 20260131-fix-login-error.md

**Normal Priority (enhancement)**
2. 20260131-add-dark-mode.md [layer: UX]
3. 20260131-add-api-endpoint.md [layer: Infrastructure]

**Low Priority (housekeeping)**
4. 20260131-cleanup-unused-imports.md

Proposed order considers severity and context grouping.
```

### 4. Confirm Order with User

Ask user to confirm or adjust:
- **Proceed** - Execute in proposed order
- **Pick one** - Let user select a specific ticket to start with
- **Original order** - Use chronological/alphabetical order instead

### 5. For Each Ticket (In Priority Order)

Follow the preloaded drive-workflow skill for each ticket:

1. Read and understand the ticket
2. Implement the ticket
3. Ask user to review (mandatory approval step)
4. Update effort and write final report
5. Commit and archive using archive-ticket skill

### 6. Completion

- After all tickets are implemented, summarize what was done
- List all commits created
- Inform user that all tickets have been processed

## Example Workflow

```
Claude: Found 3 tickets to implement:

        **High Priority (bugfix)**
        1. 20260113-fix-auth-error.md [layer: Infrastructure]

        **Normal Priority (enhancement)**
        2. 20260113-add-dark-mode.md [layer: UX]
        3. 20260113-feature-c.md [layer: Config]

        Proposed order considers severity and context grouping.
        [Proceed / Pick one / Original order]

User:   Proceed

Claude: Starting with 20260113-fix-auth-error.md...
        [implements bugfix]

        Implementation complete. Changes made:
        - Modified src/auth.ts (fixed token validation)

        Do you approve this implementation?
        [Approve / Approve and stop / Abandon]

User:   Approve

Claude: [creates commit, archives ticket]

        Starting with 20260113-add-dark-mode.md...
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
