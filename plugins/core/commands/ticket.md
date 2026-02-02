---
name: ticket
description: Explore codebase and write implementation ticket for `$ARGUMENT`
---

# Ticket

> When user input contains `/ticket` - whether "create /ticket", "write /ticket", "add /ticket for X", or similar - they likely want this command.

Thin alias for ticket-organizer subagent.

## Instructions

### Step 1: Invoke Ticket Organizer

Invoke ticket-organizer subagent via Task tool:

```
Task tool with subagent_type: "core:ticket-organizer"
prompt: "Create ticket for: <$ARGUMENT>. Target: <todo|icebox based on argument>"
```

Handle the response:

- `status: "success"` - If `branch_created` is present, confirm branch creation. Proceed to step 2.
- `status: "duplicate"` - Inform user, show existing ticket path, done
- `status: "needs_decision"` - Present options using `AskUserQuestion`, re-invoke with decision
- `status: "needs_clarification"` - Present questions using `AskUserQuestion`, re-invoke with answers

### Step 2: Commit and Present

**Skip commit if invoked during `/drive`** - archive script handles it.

Otherwise:
- Stage ticket(s): `git add <paths>`
- Commit: "Add ticket for <short-description>"
- Present ticket location and summary
- Tell user to run `/drive` to implement
