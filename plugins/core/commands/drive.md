---
name: drive
description: Implement tickets from .workaholic/tickets/ one by one, commit each, and archive.
skills:
  - drive-workflow
  - request-approval
  - write-final-report
  - handle-abandon
  - archive-ticket
---

# Drive

> When user input contains `/drive` - whether "run /drive", "do /drive", "start /drive", or similar - they likely want this command.

Implement tickets from `.workaholic/tickets/todo/` using intelligent prioritization, committing and archiving each one before moving to the next.

## Instructions

### Phase 1: Navigate Tickets

Invoke the drive-navigator subagent via Task tool:

```
Task tool with subagent_type: "core:drive-navigator"
prompt: "Navigate tickets. mode: <normal|icebox>"
```

Pass mode based on `$ARGUMENT`:
- If `$ARGUMENT` contains "icebox": mode = "icebox"
- Otherwise: mode = "normal"

Handle the response:
- `status: "empty"` - Inform user: "No tickets in queue or icebox."
- `status: "stopped"` - End the drive session
- `status: "icebox"` - Re-invoke with mode = "icebox"
- `status: "ready"` - Proceed to Phase 2 with the ordered ticket list

### Phase 2: Implement Tickets

For each ticket in the ordered list:

#### Step 2.1: Implement Ticket

Follow the preloaded **drive-workflow** skill directly in this command:

1. **Read the ticket file** to understand requirements
2. **Identify key files** mentioned in the ticket
3. **Implement changes** following the ticket's implementation steps
4. **Run type checks** per CLAUDE.md to verify changes
5. Fix any type errors or test failures before proceeding

Implementation context is preserved in the main conversation, providing full visibility of changes made.

#### Step 2.2: Request User Approval

After implementation is complete, present approval dialog to user.

Follow the preloaded **request-approval** skill format:

```
**Ticket: <title from ticket H1>**
<overview from ticket Overview section>

Implementation complete. Changes made:
- <change 1>
- <change 2>

[AskUserQuestion with selectable options]
```

**CRITICAL**: Use `AskUserQuestion` with selectable `options`. NEVER proceed without explicit user approval.

#### Step 2.3: Handle User Response

Based on user's selection:

**"Approve"**:
1. Follow **write-final-report** skill to update ticket effort and append Final Report section
2. **Verify update succeeded**: If Edit tool fails, halt and report the error to user. DO NOT proceed to archive.
3. Archive and commit using the preloaded **archive-ticket** skill:
   ```bash
   bash plugins/core/skills/archive-ticket/sh/archive.sh \
     "<ticket-path>" "<title>" <repo-url> "<motivation>" "<ux-change>" "<arch-change>"
   ```
4. Continue to next ticket

**"Approve and stop"**:
1. Follow **write-final-report** skill to update ticket effort and append Final Report section
2. **Verify update succeeded**: If Edit tool fails, halt and report the error to user. DO NOT proceed to archive.
3. Archive and commit using the preloaded **archive-ticket** skill:
   ```bash
   bash plugins/core/skills/archive-ticket/sh/archive.sh \
     "<ticket-path>" "<title>" <repo-url> "<motivation>" "<ux-change>" "<arch-change>"
   ```
4. Stop driving, report remaining tickets

**"Abandon"**:
1. Follow **handle-abandon** skill (discard changes, write failure analysis)
2. Continue to next ticket

### Phase 3: Completion

After all tickets are implemented:
- Summarize what was done
- List all commits created
- Inform user that all tickets have been processed

## Critical Rules

**NEVER autonomously move tickets to icebox.** Moving tickets is a developer decision, not an AI decision.

If a ticket cannot be implemented (out of scope, too complex, blocked, or any other reason):

1. **Stop and ask the developer** using `AskUserQuestion` with selectable `options`
2. Explain why implementation cannot proceed
3. Use selectable options (NEVER open-ended text questions):
   - "Move to icebox" - Move ticket to `.workaholic/tickets/icebox/` and continue to next
   - "Skip for now" - Leave ticket in queue, move to next ticket
   - "Abort drive" - Stop the drive session entirely

**Never commit ticket moves without explicit developer approval.**
