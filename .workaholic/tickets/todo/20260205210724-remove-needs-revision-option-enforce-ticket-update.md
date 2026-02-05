---
created_at: 2026-02-05T21:07:24+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Remove "Needs revision" Option and Enforce Ticket-Update-First Rule

## Overview

Remove the "Needs revision" selectable option from the `/drive` approval flow. When users provide feedback through free-form input, Claude Code must update the ticket's Implementation Steps section FIRST before making any code changes. This enforces the existing "Feedback Loop" pattern documented in README.md but not currently enforced in drive-approval skill.

## Key Files

- `plugins/core/skills/drive-approval/SKILL.md` - Contains AskUserQuestion options (line 50) and Section 3 "Handle Revision" (lines 74-106)
- `plugins/core/commands/drive.md` - References "Needs revision" handling (lines 98-101)
- `plugins/core/README.md` - Documents the "Feedback Loop" pattern (lines 52-67) that should be enforced

## Related History

The revision flow was added to capture user feedback and record it in a Discussion section, but it only documents the conversation without updating the actual implementation plan. The README already describes the correct "ticket-update-first" pattern that this ticket aims to enforce.

Past tickets that touched similar areas:

- [20260202140645-add-discussion-section-on-drive-rejection.md](.workaholic/tickets/archive/drive-20260202-134332/20260202140645-add-discussion-section-on-drive-rejection.md) - Added "Needs revision" option and Discussion section (same file: drive-approval)
- [20260122150455-ticket-update-first-guidance.md](.workaholic/tickets/archive/main/20260122150455-ticket-update-first-guidance.md) - Original ticket-update-first guidance (same concept)

## Implementation Steps

1. **Update `plugins/core/skills/drive-approval/SKILL.md`** to remove "Needs revision" from options:

   Remove line 50 containing the "Needs revision" option from the AskUserQuestion format.

2. **Update Section 3 "Handle Revision" in drive-approval skill** to clarify it handles free-form feedback:

   - Rename section to "Handle Feedback" (user selects "Other" and provides feedback)
   - Add explicit step: "Update ticket Implementation Steps section with new/modified steps based on feedback"
   - Emphasize: This must happen BEFORE any code changes
   - Keep the Discussion section append for traceability

3. **Update `plugins/core/commands/drive.md`** to reflect the new flow:

   - Change "Needs revision" handling (lines 98-101) to handle free-form feedback via "Other" option
   - Add explicit instruction: "FIRST update the ticket file's Implementation Steps, THEN re-implement"
   - Reference the Feedback Loop section in README.md

4. **Enhance the Discussion section format** in drive-approval to include ticket update info:

   ```markdown
   ## Discussion

   ### Revision 1 - <timestamp>

   **User feedback**: <verbatim user feedback>

   **Ticket updates**: <list of Implementation Steps added/modified>

   **Direction change**: <Claude's interpretation of how to change approach>

   **Action taken**: <brief description of revision made>
   ```

## Patches

### `plugins/core/skills/drive-approval/SKILL.md`

```diff
--- a/plugins/core/skills/drive-approval/SKILL.md
+++ b/plugins/core/skills/drive-approval/SKILL.md
@@ -47,7 +47,6 @@ After implementing a ticket, present approval dialog with:
     "options": [
       {"label": "Approve", "description": "Commit and archive this ticket, continue to next"},
       {"label": "Approve and stop", "description": "Commit and archive this ticket, then stop driving"},
-      {"label": "Needs revision", "description": "Provide feedback, update ticket, revise implementation"},
       {"label": "Abandon", "description": "Write failure analysis, discard changes, continue to next"}
     ],
     "multiSelect": false
```

```diff
--- a/plugins/core/skills/drive-approval/SKILL.md
+++ b/plugins/core/skills/drive-approval/SKILL.md
@@ -71,7 +71,7 @@ When user selects "Approve" or "Approve and stop":
 4. For "Approve": Continue to next ticket
 5. For "Approve and stop": Stop driving, report remaining tickets

-## 3. Handle Revision
+## 3. Handle Feedback

-When user selects "Needs revision", record their feedback in the ticket before revising.
+When user provides free-form feedback (via "Other" option), update the ticket before revising.

 ### Prompt for Feedback

@@ -81,15 +81,26 @@ Use AskUserQuestion - user will select "Other" and provide free-form feedback.

-### Append Discussion Section
+### Update Ticket Implementation Steps

-Add to the ticket file (before ## Final Report if exists, otherwise at end):
+**CRITICAL**: Before making ANY code changes:
+
+1. **Read the user's feedback** and identify new requirements or changes
+2. **Update the Implementation Steps section** in the ticket file:
+   - Add new steps for requested functionality
+   - Modify existing steps that need adjustment
+   - Mark completed steps if reverting to earlier state
+3. **Append Discussion section** for traceability (before ## Final Report if exists):

 ```markdown
 ## Discussion

 ### Revision 1 - <YYYY-MM-DDTHH:MM:SS+TZ>

 **User feedback**: <verbatim user feedback>

+**Ticket updates**: <list of Implementation Steps added/modified>
+
 **Direction change**: <Claude's interpretation of how to change approach>

 **Action taken**: <brief description of revision made>
```

### `plugins/core/commands/drive.md`

```diff
--- a/plugins/core/commands/drive.md
+++ b/plugins/core/commands/drive.md
@@ -95,9 +95,14 @@ Based on user's selection:
 4. **Break out of the entire continuous loop** - skip Phase 3 re-check, go directly to Phase 4 completion
 5. Report session summary and any remaining tickets in queue

-**"Needs revision"**:
-1. Follow **drive-approval** skill (Section 3) (prompt for feedback, append Discussion section)
-2. Re-implement changes based on feedback
+**Free-form feedback** (user selects "Other" and provides text):
+1. Follow **drive-approval** skill (Section 3: Handle Feedback)
+2. **FIRST**: Update the ticket's Implementation Steps section with new/modified steps
+3. Append Discussion section to record the feedback exchange
+4. **THEN**: Re-implement changes based on updated ticket
 3. Return to Step 2.2 (request approval again)
+
+> **Rule**: The ticket file must always reflect the full implementation plan. Update it BEFORE coding.
+> See "Feedback Loop" section in plugins/core/README.md.

 **"Abandon"**:
 1. Follow **drive-approval** skill (Section 4) (discard changes, write failure analysis)
```

> **Note**: These patches are speculative - verify current file content and line numbers before applying.

## Considerations

- Removing "Needs revision" as a selectable option simplifies the approval dialog while maintaining the same functionality through "Other" (`plugins/core/skills/drive-approval/SKILL.md`)
- The "ticket-update-first" rule already exists in README.md but was not enforced in the skill - this change makes the skill match the documented pattern (`plugins/core/README.md` lines 52-67)
- The Discussion section now includes "Ticket updates" field to make the ticket modification visible and auditable (`plugins/core/skills/drive-approval/SKILL.md`)
- Users accustomed to clicking "Needs revision" will need to use "Other" and type feedback, which provides more specific guidance anyway
