---
name: request-approval
description: User approval flow with selectable options for implementation review.
user-invocable: false
---

# Request Approval

User approval flow for implementation review. **STOP** and ask the user before proceeding to commit.

## Approval Prompt Format

```
**Ticket: <Title from H1>**
<Summary from Overview section - first 1-2 sentences>

Implementation complete. Changes made:
- <Change 1>
- <Change 2>

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

- **Approve**: Proceed to write final report, commit, and continue to next ticket
- **Approve and stop**: Proceed to write final report, commit, then stop driving
- **Abandon**: Follow handle-abandon skill

**Do NOT proceed to commit until user explicitly approves.**
