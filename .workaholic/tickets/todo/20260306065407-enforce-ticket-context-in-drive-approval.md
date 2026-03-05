---
created_at: 2026-03-06T06:54:07+09:00
author: a@qmu.jp
type: bugfix
layer: [UX]
effort:
commit_hash:
category:
---

# Enforce ticket title and summary in drive approval prompt

## Overview

The drive approval prompt sometimes shows no ticket title or explanation when asking users to approve or provide feedback. A previous fix (commit 6cf2504) added template placeholders and an IMPORTANT note to the drive-approval skill, but the problem still occurs intermittently. The root cause is that the guidance is soft: the drive command does not explicitly require passing `title` and `overview` from the drive-workflow result into the approval prompt, and the feedback re-approval loop can lose this context entirely. The fix must make the data flow structurally enforced in both the drive command and the drive-approval skill so the agent cannot skip it.

## Key Files

- `plugins/drivin/skills/drive-approval/SKILL.md` - The approval skill that contains the AskUserQuestion template; needs stronger enforcement language and explicit data source references
- `plugins/drivin/commands/drive.md` - The drive command orchestrator; Step 2.2 must explicitly instruct passing workflow result fields into the approval prompt
- `plugins/drivin/skills/drive-workflow/SKILL.md` - Returns `title` and `overview` in its JSON output; no changes expected but confirms data availability

## Related History

A previous ticket addressed the same UX problem by embedding ticket context into the AskUserQuestion header and question fields. That fix added template placeholders and an IMPORTANT note, but the agent still sometimes skips substitution because the drive command orchestration does not enforce the handoff. An even earlier ticket first introduced the approval format section but did not update the AskUserQuestion JSON at all.

Past tickets that touched similar areas:

- [20260212222003-show-ticket-context-in-drive-approval-prompt.md](.workaholic/tickets/archive/drive-20260212-122906/20260212222003-show-ticket-context-in-drive-approval-prompt.md) - Added template placeholders to AskUserQuestion header/question fields (same skill, same bug)
- [20260123002028-drive-show-ticket-context.md](.workaholic/tickets/archive/feat-20260122-210543/20260123002028-drive-show-ticket-context.md) - First attempt at showing ticket context in approval prompt (same UX concern)
- [20260202184602-merge-approval-flow-skills.md](.workaholic/tickets/archive/drive-20260202-134332/20260202184602-merge-approval-flow-skills.md) - Merged approval flow skills into current structure (same skill file)
- [20260205210724-remove-needs-revision-option-enforce-ticket-update.md](.workaholic/tickets/archive/drive-20260205-195920/20260205210724-remove-needs-revision-option-enforce-ticket-update.md) - Enforced ticket update on feedback (same approval flow)

## Implementation Steps

1. **Add explicit handoff instruction in drive command Step 2.2** (`plugins/drivin/commands/drive.md`): After the line referencing drive-approval skill, add a requirement that the agent must use the `title` and `overview` fields from the drive-workflow result (Step 2.1) when constructing the approval prompt. Make it a CRITICAL rule, not just guidance.

2. **Add validation rule to drive-approval Section 1** (`plugins/drivin/skills/drive-approval/SKILL.md`): Before the Options subsection, add a validation rule stating that presenting the AskUserQuestion with empty or placeholder header/question fields is a failure condition. The agent must re-read the ticket file to obtain title and overview if they are not available from the workflow result.

3. **Add fallback instruction for feedback re-approval** (`plugins/drivin/skills/drive-approval/SKILL.md`): In Section 3, step 5 ("Return to approval flow"), add explicit instruction to re-read the ticket title and overview before presenting the approval prompt again. The feedback loop must not lose context.

4. **Strengthen the IMPORTANT note wording** (`plugins/drivin/skills/drive-approval/SKILL.md`): Change the existing IMPORTANT note from describing what to do to stating what will happen if skipped -- frame it as a CRITICAL rule with a failure consequence, not just a helpful note.

## Patches

### `plugins/drivin/commands/drive.md`

```diff
--- a/plugins/drivin/commands/drive.md
+++ b/plugins/drivin/commands/drive.md
@@ -46,7 +46,9 @@

 #### Step 2.2: Request Approval

-Follow the preloaded **drive-approval** skill (Section 1) to present approval dialog.
+Follow the preloaded **drive-approval** skill (Section 1) to present approval dialog. **CRITICAL**: You MUST use the `title` and `overview` fields from the Step 2.1 workflow result to populate the approval prompt header and question. If these fields are unavailable, re-read the ticket file to obtain them. Never present an approval prompt without the ticket title and summary.

 **CRITICAL**: Use `AskUserQuestion` with selectable `options`. NEVER proceed without explicit user approval.
```

### `plugins/drivin/skills/drive-approval/SKILL.md`

```diff
--- a/plugins/drivin/skills/drive-approval/SKILL.md
+++ b/plugins/drivin/skills/drive-approval/SKILL.md
@@ -27,7 +27,9 @@

 ### Options

-**IMPORTANT**: The `header` and `question` fields below are templates. Replace `<title from ticket H1>` and `<overview from ticket Overview section>` with actual values from the drive-workflow result JSON (`title` and `overview` fields). Never present these as literal angle-bracket placeholders.
+**CRITICAL**: The `header` and `question` fields below are templates that MUST be replaced with actual values before presenting to the user. Use `title` and `overview` from the drive-workflow result JSON. If those values are not available in context, re-read the ticket file to obtain the H1 title and Overview section. Presenting an approval prompt with missing, empty, or literal angle-bracket placeholder values is a failure condition -- the user cannot make an informed decision without knowing what ticket was implemented.

 ```json
 {
```

```diff
--- a/plugins/drivin/skills/drive-approval/SKILL.md
+++ b/plugins/drivin/skills/drive-approval/SKILL.md
@@ -84,6 +84,8 @@

 4. **Re-implement** following the updated ticket's Implementation Steps
-5. Return to approval flow (Section 1)
+5. Return to approval flow (Section 1). **CRITICAL**: Before presenting the approval prompt again, ensure you have the ticket title (H1 heading) and overview available. Re-read the ticket file if needed -- the feedback loop must not lose ticket context.

 ## 4. Handle Abandonment
```

> **Note**: Line offsets in these patches are approximate -- verify against actual file content before applying.

## Considerations

- This is the third attempt to fix the same UX issue. The first attempt (20260123002028) added a Format section. The second attempt (20260212222003) updated AskUserQuestion fields. This ticket strengthens enforcement by adding CRITICAL rules in the drive command and fallback re-read instructions. (`plugins/drivin/skills/drive-approval/SKILL.md`)
- The feedback re-approval loop in Section 3 step 5 is a likely source of context loss because after re-implementation, the original workflow result JSON may no longer be in the agent's immediate context window. The fallback instruction to re-read the ticket file addresses this. (`plugins/drivin/skills/drive-approval/SKILL.md` lines 84-87)
- The drive-workflow already returns `title` and `overview` in its JSON output. No changes to that skill are needed. (`plugins/drivin/skills/drive-workflow/SKILL.md` lines 47-56)
- Using "CRITICAL" and "failure condition" language is consistent with other enforcement patterns in this codebase, such as the ticket-update-first enforcement in drive-approval Section 3. (`plugins/drivin/skills/drive-approval/SKILL.md` line 62)
