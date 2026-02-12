---
created_at: 2026-02-12T22:20:03+08:00
author: a@qmu.jp
type: bugfix
layer: [UX]
effort: 0.25h
commit_hash: 6cf2504
category: Changed
---

# Show ticket title and summary in drive approval prompt

## Overview

The `/drive` approval prompt does not display the ticket title or summary when asking the user to approve or reject an implementation. The user sees only a list of file changes and a generic "Approve this implementation?" question, with no context about what the ticket originally requested. The drive-approval skill's Format section (lines 16-26) describes showing the title and overview, but the AskUserQuestion JSON (lines 30-43) uses a static `header: "Approval"` and a generic `question` string that carry no ticket context. In practice the agent skips the freeform Format text and jumps directly to the AskUserQuestion, so the user never sees what ticket is being reviewed. The fix is to embed the ticket title and overview directly into the AskUserQuestion `header` and `question` fields, making the context structurally unavoidable.

## Key Files

- `plugins/core/skills/drive-approval/SKILL.md` - Primary target; the Format section (lines 16-26) describes the intended presentation but the AskUserQuestion JSON (lines 30-43) does not carry ticket context in its `header` or `question` fields
- `plugins/core/skills/drive-workflow/SKILL.md` - Returns `title` and `overview` in its JSON output (lines 47-56); these values are available to drive-approval but not used in the AskUserQuestion
- `plugins/core/commands/drive.md` - Orchestrates the flow from drive-workflow to drive-approval; may need adjustment if the handoff between workflow result and approval prompt needs to be made more explicit

## Related History

An earlier ticket (20260123002028) first added the ticket title and overview to the drive approval prompt. That implementation produced the current Format section in drive-approval SKILL.md. However, the AskUserQuestion JSON was not updated to carry the title and overview in its `header` and `question` fields, creating a gap where the agent can bypass the freeform text and present only the generic AskUserQuestion. A later ticket (20260128211728) added the "Fail" option (now "Abandon") to the approval prompt, and another (20260125113309) added "Approve and stop", both modifying the same AskUserQuestion options block without addressing the missing context.

Past tickets that touched similar areas:

- [20260123002028-drive-show-ticket-context.md](.workaholic/tickets/archive/feat-20260122-210543/20260123002028-drive-show-ticket-context.md) - Added ticket title and overview to drive approval format (same skill, same UX concern)
- [20260128211728-add-fail-option-to-drive-approval.md](.workaholic/tickets/archive/feat-20260128-012023/20260128211728-add-fail-option-to-drive-approval.md) - Added "Fail" option to approval prompt (same AskUserQuestion block)
- [20260125113309-drive-approve-and-stop-option.md](.workaholic/tickets/archive/feat-20260124-200439/20260125113309-drive-approve-and-stop-option.md) - Added "Approve and stop" option (same approval flow)

## Implementation Steps

1. **Update AskUserQuestion `header` field to include ticket title** (`plugins/core/skills/drive-approval/SKILL.md`): Change the static `"header": "Approval"` to a dynamic template that includes the ticket title, e.g., `"header": "Ticket: <title from ticket H1>"`. This ensures the ticket title appears in the AskUserQuestion UI header regardless of whether the agent renders the freeform Format text.

2. **Update AskUserQuestion `question` field to include ticket overview** (`plugins/core/skills/drive-approval/SKILL.md`): Change the generic `"question": "Approve this implementation?"` to include the overview, e.g., `"question": "<overview from ticket Overview section>\n\nApprove this implementation?"`. This places the ticket summary directly in the question the user reads.

3. **Add explicit instruction to always populate header and question from workflow result** (`plugins/core/skills/drive-approval/SKILL.md`): Above the Options subsection, add a note stating that the `header` and `question` fields must be populated with values from the drive-workflow result JSON (`title` and `overview` fields). This makes the data flow explicit and prevents the agent from using the template literally with angle-bracket placeholders.

4. **Verify drive-workflow returns title and overview** (`plugins/core/skills/drive-workflow/SKILL.md`): Confirm the JSON output schema at lines 47-56 includes `title` and `overview`. No change expected here, but verify these fields are not optional or frequently omitted.

## Patches

### `plugins/core/skills/drive-approval/SKILL.md`

```diff
--- a/plugins/core/skills/drive-approval/SKILL.md
+++ b/plugins/core/skills/drive-approval/SKILL.md
@@ -27,10 +27,14 @@

 ### Options

+**IMPORTANT**: The `header` and `question` fields below are templates. Replace `<title from ticket H1>` and `<overview from ticket Overview section>` with actual values from the drive-workflow result JSON (`title` and `overview` fields). Never present these as literal angle-bracket placeholders.
+
 ```json
 {
   "questions": [{
-    "question": "Approve this implementation?",
-    "header": "Approval",
+    "question": "<overview from ticket Overview section>\n\nApprove this implementation?",
+    "header": "Ticket: <title from ticket H1>",
     "options": [
       {"label": "Approve", "description": "Commit and archive this ticket, continue to next"},
       {"label": "Approve and stop", "description": "Commit and archive this ticket, then stop driving"},
```

> **Note**: This patch is speculative - the exact line offsets may differ slightly. Verify before applying.

## Considerations

- The AskUserQuestion `header` field renders as a prominent heading in the Claude Code UX, making it the most visible place to show the ticket title (`plugins/core/skills/drive-approval/SKILL.md` line 34). The `question` field renders as body text below the header, making it suitable for the overview summary.
- The freeform Format section (lines 16-26) should be kept as-is because it also instructs the agent to list specific changes made. The AskUserQuestion improvement is additive -- it ensures the title and overview appear even if the agent skips the freeform text.
- The drive-workflow already returns `title` and `overview` in its JSON output (`plugins/core/skills/drive-workflow/SKILL.md` lines 51-52). The drive command at step 2.2 (`plugins/core/commands/drive.md` line 48) invokes drive-approval after drive-workflow completes, so these values are available in the conversation context. No new data passing mechanism is needed.
- This is the second attempt to fix this UX issue. The first attempt (20260123002028) added the Format section but did not update the AskUserQuestion JSON. This fix addresses the structural gap by embedding context in the AskUserQuestion fields themselves, which the agent cannot skip.

## Final Report

Development completed as planned.
