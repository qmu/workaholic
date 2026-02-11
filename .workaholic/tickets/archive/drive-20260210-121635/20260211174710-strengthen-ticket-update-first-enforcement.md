---
created_at: 2026-02-11T17:47:10+08:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.25h
commit_hash: 694001b
category: Changed
---

# Strengthen Ticket-Update-First Enforcement in Drive Feedback Flow

## Overview

When users provide free-form feedback during `/drive` approval (selecting "Other"), the system should update the ticket file BEFORE re-implementing code. This is documented in `drive.md` and `drive-approval/SKILL.md`, but the LLM frequently skips the ticket update and jumps straight to re-implementation. The root cause is weak enforcement: the rule uses plain text instead of CRITICAL markers, the rule placement in `drive.md` is after all response paths (easy to miss), and there is no verification gate between the ticket update and re-implementation.

## Key Files

- `plugins/core/skills/drive-approval/SKILL.md` - Section 3 "Handle Feedback" contains the ticket-update-first rule (line 60) and the update steps (lines 62-83)
- `plugins/core/commands/drive.md` - Free-form feedback path (lines 61-64) and the Rule blockquote (line 66) placed after all three response paths

## Related History

This area has been iteratively refined: the ticket-update-first pattern was first documented, then a "Needs revision" option was added, then it was removed in favor of free-form "Other" feedback, and the drive command was refactored for brevity. Each iteration attempted to enforce ticket-update-first but the enforcement remained too weak.

Past tickets that touched similar areas:

- [20260205210724-remove-needs-revision-option-enforce-ticket-update.md](.workaholic/tickets/archive/drive-20260205-195920/20260205210724-remove-needs-revision-option-enforce-ticket-update.md) - Removed "Needs revision" option and attempted to enforce ticket-update-first rule (same file: drive-approval, drive.md)
- [20260202140645-add-discussion-section-on-drive-rejection.md](.workaholic/tickets/archive/drive-20260202-134332/20260202140645-add-discussion-section-on-drive-rejection.md) - Added Discussion section and "Needs revision" option (same file: drive-approval)
- [20260202184602-merge-approval-flow-skills.md](.workaholic/tickets/archive/drive-20260202-134332/20260202184602-merge-approval-flow-skills.md) - Merged approval skills into unified drive-approval skill (same file: drive-approval)
- [20260207003033-refactor-drive-command-reduce-redundancy.md](.workaholic/tickets/archive/drive-20260205-195920/20260207003033-refactor-drive-command-reduce-redundancy.md) - Refactored drive.md for brevity; may have weakened the rule placement (same file: drive.md)
- [20260122150455-ticket-update-first-guidance.md](.workaholic/tickets/archive/main/20260122150455-ticket-update-first-guidance.md) - Original ticket-update-first guidance (same concept)

## Implementation Steps

1. **Update `plugins/core/commands/drive.md`** - Move and strengthen the Rule blockquote:

   Move the Rule from line 66 (after all three response paths) to inside the free-form feedback path (between lines 61-64). Upgrade from `> **Rule**:` to `> **CRITICAL**:` and make the wording explicit about not re-implementing until the ticket reflects the feedback. Add a verification step to the numbered list.

2. **Update `plugins/core/skills/drive-approval/SKILL.md` Section 3** - Strengthen enforcement:

   - Change the `**Rule**:` on line 60 to `**CRITICAL:**` with a "Do NOT skip this step. Do NOT write code until steps 1-2 are verified complete." warning
   - Add a new step 3 "Verify ticket update" between the current step 2 (Append Discussion section) and step 3 (Re-implement): instruct the LLM to re-read the ticket file to confirm both Implementation Steps and Discussion section were written successfully
   - Renumber existing step 3 (Re-implement) to step 4 and step 4 (Return to approval) to step 5

## Patches

### `plugins/core/commands/drive.md`

```diff
--- a/plugins/core/commands/drive.md
+++ b/plugins/core/commands/drive.md
@@ -59,9 +59,12 @@
 5. Otherwise: continue to next ticket

 **Free-form feedback** (user selects "Other" and provides text):
-1. Follow **drive-approval** skill (Section 3: Handle Feedback)
-2. Re-implement changes based on updated ticket
-3. Return to Step 2.2

-> **Rule**: The ticket file must always reflect the full implementation plan. Update it BEFORE coding.
+> **CRITICAL**: Update the ticket file FIRST. Do NOT re-implement until the ticket reflects the user's feedback.
+
+1. Follow **drive-approval** skill (Section 3: Handle Feedback) - this updates the ticket
+2. **Verify** the ticket file was updated (re-read it)
+3. Re-implement changes based on the updated ticket
+4. Return to Step 2.2

 **"Abandon"**:
```

### `plugins/core/skills/drive-approval/SKILL.md`

```diff
--- a/plugins/core/skills/drive-approval/SKILL.md
+++ b/plugins/core/skills/drive-approval/SKILL.md
@@ -57,7 +57,7 @@

 When user selects "Other" and provides feedback:

-**Rule**: Update the ticket BEFORE making code changes.
+**CRITICAL: Update the ticket file BEFORE making ANY code changes. Do NOT skip this step. Do NOT write code until steps 1-2 are verified complete.**

 1. **Update Implementation Steps** in the ticket file:
    - Add new steps for requested functionality
@@ -79,5 +79,7 @@

 For subsequent revisions, append as "### Revision 2", etc.

-3. **Re-implement** following the updated ticket
-4. Return to approval flow (Section 1)
+3. **Verify ticket update**: Re-read the ticket file to confirm both Implementation Steps and Discussion section were written successfully. If the update failed, retry before proceeding.
+
+4. **Re-implement** following the updated ticket's Implementation Steps
+5. Return to approval flow (Section 1)
```

> **Note**: These patches are speculative - verify exact line content and context before applying.

## Considerations

- The CRITICAL marker is the strongest enforcement signal available in LLM prompt engineering. Using it here aligns with the pattern already used in `drive.md` line 50 for approval requirements. (`plugins/core/commands/drive.md` line 50)
- Moving the Rule blockquote inside the feedback path ensures it is encountered in-flow rather than as a trailing afterthought. The previous placement after all three response paths meant the LLM may have already selected its execution path before reading the rule. (`plugins/core/commands/drive.md` lines 61-66)
- The verification gate (re-reading the ticket file) adds a concrete checkpoint. Without it, the LLM can acknowledge the rule and still skip the update due to how token generation works -- adding an explicit "re-read to confirm" step forces a tool call between the update and re-implementation. (`plugins/core/skills/drive-approval/SKILL.md` Section 3)
- This is a targeted fix to two specific files. The drive-workflow skill does not need changes because it handles initial implementation, not the feedback loop. (`plugins/core/skills/drive-workflow/SKILL.md`)
- The historical pattern shows this rule has been attempted multiple times (at least 3 prior tickets). If this strengthened enforcement still proves insufficient, a more structural approach (such as a shell script gate that checks ticket modification time) may be needed as a follow-up.

## Final Report

### Changes Made

| File | Action |
| ---- | ------ |
| `plugins/core/commands/drive.md` | Updated -- moved Rule into feedback path, upgraded to CRITICAL, added verification step |
| `plugins/core/skills/drive-approval/SKILL.md` | Updated -- upgraded Rule to CRITICAL with explicit warning, added verification gate (step 3), renumbered to 5 steps |

### Deviations

None -- patches applied as specified.
