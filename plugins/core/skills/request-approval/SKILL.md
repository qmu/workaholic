---
name: request-approval
description: User approval flow with selectable options for implementation review.
user-invocable: false
---

# Request Approval

User approval flow for implementation review. Used by `/drive` command after driver subagent returns implementation summary.

**CRITICAL**: This approval MUST happen at the `/drive` command level, NOT inside subagents. Subagents run in isolated contexts where `AskUserQuestion` does not surface to the user.

## When to Use

After receiving `status: "pending_approval"` from driver subagent with:
- `title` - Ticket title
- `overview` - Brief summary
- `changes` - List of changes made
- `ticket_path` - Path to ticket file

## Approval Prompt Format

```
**Ticket: <title>**
<overview>

Implementation complete. Changes made:
- <change 1>
- <change 2>

[AskUserQuestion with selectable options]
```

## AskUserQuestion Format

**CRITICAL: ALWAYS use selectable `options` parameter. NEVER ask open-ended text questions.**

```json
{
  "questions": [{
    "question": "Do you approve this implementation?",
    "header": "Approval",
    "options": [
      {"label": "Approve", "description": "Proceed to commit and continue to next ticket"},
      {"label": "Approve and stop", "description": "Commit this ticket but stop driving"},
      {"label": "Abandon", "description": "Write failure analysis, discard changes, continue to next"}
    ],
    "multiSelect": false
  }]
}
```

## Post-Approval Behavior

- **Approve**: Follow write-final-report skill, then run:
  ```bash
  bash plugins/core/skills/archive-ticket/sh/archive.sh \
    "<ticket-path>" "<title>" <repo-url> "<motivation>" "<ux-change>" "<arch-change>"
  ```
  Continue to next ticket.
- **Approve and stop**: Follow write-final-report skill, then run:
  ```bash
  bash plugins/core/skills/archive-ticket/sh/archive.sh \
    "<ticket-path>" "<title>" <repo-url> "<motivation>" "<ux-change>" "<arch-change>"
  ```
  Stop driving.
- **Abandon**: Follow handle-abandon skill, continue to next

**Do NOT proceed to commit until user explicitly approves.**
