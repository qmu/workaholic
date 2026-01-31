---
name: drive
description: Implement tickets from .workaholic/tickets/ one by one, commit each, and archive.
skills:
  - drive-workflow
  - archive-ticket
---

# Drive

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

1. Follow the preloaded drive-workflow skill
2. Handle user response:
   - **Approve**: Continue to next ticket automatically
   - **Approve and stop**: Stop driving, report remaining tickets
   - **Abandon**: Follow abandon workflow in skill, continue to next ticket

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
