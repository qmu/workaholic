---
name: drive-approval
description: User approval flow for drive implementations including approval, revision, and abandonment.
user-invocable: false
---

# Drive Approval

User approval flow for implementation review during `/drive`. This skill covers the complete approval cycle: requesting approval, handling revision feedback, and handling abandonment.

## 1. Request Approval

After implementing a ticket, present the approval dialog to the user.

**CRITICAL**: This approval MUST happen at the `/drive` command level to ensure proper user interaction.

### When to Use

After implementing a ticket, present approval dialog with:
- `title` - Ticket title from H1
- `overview` - Brief summary from Overview section
- `changes` - List of changes made during implementation
- `ticket_path` - Path to ticket file

### Approval Prompt Format

```
**Ticket: <title>**
<overview>

Implementation complete. Changes made:
- <change 1>
- <change 2>

[AskUserQuestion with selectable options]
```

### AskUserQuestion Format

**CRITICAL: ALWAYS use selectable `options` parameter. NEVER ask open-ended text questions.**

```json
{
  "questions": [{
    "question": "How would you like to proceed with this ticket?",
    "header": "Approval",
    "options": [
      {"label": "Approve", "description": "Commit and archive this ticket, continue to next"},
      {"label": "Approve and stop", "description": "Commit and archive this ticket, then stop driving"},
      {"label": "Needs revision", "description": "Provide feedback, update ticket, revise implementation"},
      {"label": "Abandon", "description": "Write failure analysis, discard changes, continue to next"}
    ],
    "multiSelect": false
  }]
}
```

**Do NOT proceed to commit until user explicitly approves.**

## 2. Handle Approval and Commit

When user selects "Approve" or "Approve and stop":

1. Follow **write-final-report** skill to update ticket effort and append Final Report section
2. **Verify update succeeded**: If Edit tool fails, halt and report the error to user. DO NOT proceed to archive.
3. Archive and commit using the **archive-ticket** skill:
   ```bash
   bash plugins/core/skills/archive-ticket/sh/archive.sh \
     "<ticket-path>" "<title>" <repo-url> "<motivation>" "<ux-change>" "<arch-change>"
   ```
4. For "Approve": Continue to next ticket
5. For "Approve and stop": Stop driving, report remaining tickets

## 3. Handle Revision

When user selects "Needs revision", record their feedback in the ticket before revising.

### Prompt for Feedback

Ask user with open-ended text input: "What changes would you like?"

Use AskUserQuestion - user will select "Other" and provide free-form feedback.

### Append Discussion Section

Add to the ticket file (before ## Final Report if exists, otherwise at end):

```markdown
## Discussion

### Revision 1 - <YYYY-MM-DDTHH:MM:SS+TZ>

**User feedback**: <verbatim user feedback>

**Direction change**: <Claude's interpretation of how to change approach>

**Action taken**: <brief description of revision made>
```

For subsequent revisions, append as "### Revision 2", "### Revision 3", etc.

### Re-implement

Apply the revised approach following the user's feedback.

After re-implementation, return to approval flow (Section 1).

## 4. Handle Abandonment

When user selects "Abandon", do NOT commit implementation changes.

### Discard Implementation Changes

**Pre-flight check**: This repository may have multiple contributors (developers, agents) working concurrently. Before discarding changes, verify no unrelated work will be lost:

```bash
git status --porcelain
```

Review the output and identify:
1. Changes you made during this implementation (safe to discard)
2. Changes that may belong to other contributors (must preserve)

If you cannot distinguish your changes from others', inform the user and ask which files to restore.

**Discard only implementation changes** (preserves ticket files and unrelated work):

```bash
git restore . ':!.workaholic/tickets/'
```

Or for more targeted restoration, restore specific files you modified:

```bash
git restore <file1> <file2> ...
```

Reverts implementation changes while preserving any uncommitted work from other contributors.

### Append Failure Analysis Section

Add to the ticket file:

```markdown
## Failure Analysis

### What Was Attempted
- <Brief description of the implementation approach>

### Why It Failed
- <Reason the implementation didn't work or was abandoned>

### Insights for Future Attempts
- <Learnings that could help if this is reattempted>
```

### Move Ticket to Abandoned Directory

```bash
mkdir -p .workaholic/tickets/abandoned
mv <ticket-path> .workaholic/tickets/abandoned/
```

### Commit the Abandonment

Use the commit skill for consistent commit formatting:

```bash
bash plugins/core/skills/commit/sh/commit.sh \
  "Abandon: <ticket-title>" \
  "Implementation proved unworkable" \
  "None" \
  "Ticket moved to abandoned with failure analysis" \
  .workaholic/tickets/
```

Or if already staged:

```bash
git add .workaholic/tickets/
bash plugins/core/skills/commit/sh/commit.sh --skip-staging \
  "Abandon: <ticket-title>" \
  "Implementation proved unworkable" \
  "None" \
  "Ticket moved to abandoned with failure analysis"
```

This preserves the failure analysis in git history.

### Continue to Next Ticket

Automatically proceed to the next ticket without asking for confirmation.

This allows users to abandon a failed implementation attempt while preserving insights for future reference.
