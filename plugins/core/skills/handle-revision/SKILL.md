---
name: handle-revision
description: Handle revision request by recording discussion and re-implementing.
user-invocable: false
---

# Handle Revision

When user selects "Needs revision", record their feedback in the ticket before revising.

## 1. Prompt for Feedback

Ask user with open-ended text input: "What changes would you like?"

Use AskUserQuestion - user will select "Other" and provide free-form feedback.

## 2. Append Discussion Section

Add to the ticket file (before ## Final Report if exists, otherwise at end):

```markdown
## Discussion

### Revision 1 - <YYYY-MM-DDTHH:MM:SS+TZ>

**User feedback**: <verbatim user feedback>

**Direction change**: <Claude's interpretation of how to change approach>

**Action taken**: <brief description of revision made>
```

For subsequent revisions, append as "### Revision 2", "### Revision 3", etc.

## 3. Re-implement

Apply the revised approach following the user's feedback.

After re-implementation, return to approval flow (Step 2.2 in drive.md).
