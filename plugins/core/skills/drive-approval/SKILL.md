---
name: drive-approval
description: User approval flow for drive implementations including approval, feedback, and abandonment.
user-invocable: false
---

# Drive Approval

User approval flow for `/drive` implementation review.

## 1. Request Approval

Present approval dialog after implementing a ticket.

### Format

```
**Ticket: <title from ticket H1>**
<overview from ticket Overview section>

Implementation complete. Changes made:
- <change 1>
- <change 2>

[AskUserQuestion with selectable options]
```

### Options

```json
{
  "questions": [{
    "question": "Approve this implementation?",
    "header": "Approval",
    "options": [
      {"label": "Approve", "description": "Commit and archive this ticket, continue to next"},
      {"label": "Approve and stop", "description": "Commit and archive this ticket, then stop driving"},
      {"label": "Abandon", "description": "Write failure analysis, discard changes, continue to next"}
    ],
    "multiSelect": false
  }]
}
```

Users can also select "Other" to provide free-form feedback.

## 2. Handle Approval

When user selects "Approve" or "Approve and stop":

1. Update ticket with effort and Final Report (use **write-final-report** skill)
2. Archive and commit (use **archive-ticket** skill)
3. For "Approve": continue to next ticket
4. For "Approve and stop": end drive session

## 3. Handle Feedback

When user selects "Other" and provides feedback:

**Rule**: Update the ticket BEFORE making code changes.

1. **Update Implementation Steps** in the ticket file:
   - Add new steps for requested functionality
   - Modify existing steps that need adjustment

2. **Append Discussion section** (before Final Report if exists):

```markdown
## Discussion

### Revision 1 - <YYYY-MM-DDTHH:MM:SS+TZ>

**User feedback**: <verbatim feedback>

**Ticket updates**: <list of Implementation Steps added/modified>

**Direction change**: <interpretation of how to change approach>
```

For subsequent revisions, append as "### Revision 2", etc.

3. **Re-implement** following the updated ticket
4. Return to approval flow (Section 1)

## 4. Handle Abandonment

When user selects "Abandon":

### Discard Changes

Check for other contributors' work before discarding:

```bash
git status --porcelain
```

Discard only your implementation changes:

```bash
git restore <file1> <file2> ...
```

### Record Failure

Append to ticket:

```markdown
## Failure Analysis

### What Was Attempted
- <implementation approach>

### Why It Failed
- <reason abandoned>

### Insights for Future Attempts
- <learnings>
```

### Archive

```bash
mkdir -p .workaholic/tickets/abandoned
mv <ticket-path> .workaholic/tickets/abandoned/
```

Commit using **commit** skill:

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/commit/sh/commit.sh \
  "Abandon: <ticket-title>" \
  "Implementation proved unworkable" \
  "None" \
  "Ticket moved to abandoned with failure analysis" \
  .workaholic/tickets/
```

Continue to next ticket automatically.
