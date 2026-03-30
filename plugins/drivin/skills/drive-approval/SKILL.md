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

**CRITICAL**: The `header` and `question` fields below are templates that MUST be replaced with actual values before presenting to the user. Use `title` and `overview` from the drive-workflow result JSON. If those values are not available in context, re-read the ticket file to obtain the H1 title and Overview section. Presenting an approval prompt with missing, empty, or literal angle-bracket placeholder values is a failure condition -- the user cannot make an informed decision without knowing what ticket was implemented.

```json
{
  "questions": [{
    "question": "<overview from ticket Overview section>\n\nApprove this implementation?",
    "header": "<title from ticket H1>",
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

1. Update ticket with effort (one of: `0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h`) and Final Report (use **write-final-report** skill)
2. Archive and commit (use **archive-ticket** skill)
3. For "Approve": continue to next ticket
4. For "Approve and stop": end drive session

## 3. Handle Feedback

When user selects "Other" and provides feedback:

**CRITICAL: Update the ticket file BEFORE making ANY code changes. Do NOT skip this step. Do NOT write code until steps 1-2 are verified complete.**

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

3. **Verify ticket update**: Re-read the ticket file to confirm both Implementation Steps and Discussion section were written successfully. If the update failed, retry before proceeding.

4. **Re-implement** following the updated ticket's Implementation Steps
5. Return to approval flow (Section 1). **CRITICAL**: Before presenting the approval prompt again, ensure you have the ticket title (H1 heading) and overview available. Re-read the ticket file if needed -- the feedback loop must not lose ticket context.

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
bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/commit/sh/commit.sh \
  "Abandon: <ticket-title>" \
  "Implementation proved unworkable" \
  "None" \
  "None" \
  "Ticket moved to abandoned with failure analysis" \
  .workaholic/tickets/
```

Continue to next ticket automatically.
