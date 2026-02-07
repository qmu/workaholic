---
created_at: 2026-02-07T17:08:06+09:00
author: a@qmu.jp
type: bugfix
layer: [Config, Domain]
effort:
commit_hash:
category:
---

# Fix Root Cause of Invalid Effort Values During Drive Approval

## Overview

Despite a previous fix (ticket 20260203174022-fix-effort-field-format-guidance) that added prominent warnings to the `write-final-report` skill, Claude Code continues to set invalid effort values (t-shirt sizes like `M`, `S`, `XS`) when updating ticket frontmatter after drive approval. This ticket investigates the root causes and implements structural fixes to prevent the issue.

## Key Files

- `plugins/core/skills/write-final-report/SKILL.md` - Primary skill that instructs Claude to set effort value after approval; already has warnings but they are insufficient
- `plugins/core/skills/update-ticket-frontmatter/sh/update.sh` - Shell script that updates frontmatter fields; performs NO validation on the value being set
- `plugins/core/skills/update-ticket-frontmatter/SKILL.md` - Documents valid effort values but is only referenced indirectly
- `plugins/core/hooks/validate-ticket.sh` - Validation hook that rejects invalid effort values, but only triggers on Write/Edit tool operations (lines 155-164)
- `plugins/core/skills/drive-approval/SKILL.md` - Approval flow that triggers the effort update
- `plugins/core/skills/create-ticket/SKILL.md` - Ticket template that describes effort as "Time spent in numeric hours" (line 176)

## Related History

The effort field format has been a recurring source of errors. The initial validation hook was added to enforce formats, and a subsequent fix attempted to improve guidance in write-final-report. Despite these efforts, the problem persists because the root cause (lack of script-level validation and indirect skill references) was not addressed.

Past tickets that touched similar areas:

- [20260203174022-fix-effort-field-format-guidance.md](.workaholic/tickets/archive/drive-20260203-122444/20260203174022-fix-effort-field-format-guidance.md) - Added warning box and valid values table to write-final-report (same skill: write-final-report)
- [20260131162854-extract-update-ticket-frontmatter-skill.md](.workaholic/tickets/archive/feat-20260131-125844/20260131162854-extract-update-ticket-frontmatter-skill.md) - Created the update-ticket-frontmatter skill with effort field handling (same skill: update-ticket-frontmatter)
- [20260129041924-add-ticket-validation-hook.md](.workaholic/tickets/archive/feat-20260129-023941/20260129041924-add-ticket-validation-hook.md) - Added ticket validation hook that enforces field formats (same file: validate-ticket.sh)
- [20260131192725-improve-create-ticket-frontmatter-clarity.md](.workaholic/tickets/archive/feat-20260131-125844/20260131192725-improve-create-ticket-frontmatter-clarity.md) - Improved frontmatter documentation clarity (same layer: Config)

## Implementation Steps

1. **Add validation to `update.sh`** - The shell script `plugins/core/skills/update-ticket-frontmatter/sh/update.sh` currently accepts any value for the effort field without validation. Add validation that rejects values not matching the allowed set (`0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h`), matching the same regex used in `validate-ticket.sh` (line 158). This is the single most impactful fix because it creates a hard gate that prevents invalid values from ever being written, regardless of what Claude decides to pass.

2. **Inline the valid values directly in `write-final-report`** - Currently line 15 says "Follow the preloaded **update-ticket-frontmatter** skill for valid effort values." This indirect reference requires Claude to consult another document. Replace this with the actual valid values enumerated directly in the instruction, so Claude sees them in the same context where it decides what value to use. The table on lines 25-33 already does this partially, but the opening instruction still defers to another skill.

3. **Add explicit "estimate then map" instruction** - The current guidance lists valid values with use-case descriptions but does not tell Claude HOW to estimate. Add a concrete instruction like: "Estimate the actual time this implementation took, then round to the nearest valid value: 0.1h, 0.25h, 0.5h, 1h, 2h, 4h. Do NOT use t-shirt sizes (S/M/L), minutes (10m/30m), or any other format."

4. **Remove ambiguous effort reference from drive-navigator** - Line 59 of `plugins/core/agents/drive-navigator.md` says "`effort`: Lower effort tickets may provide quick wins." Since tickets are created with effort empty, this field is never populated when the navigator reads it. This line serves no purpose and creates a misleading association between effort and the prioritization flow. Either remove it or clarify it only applies to tickets that have been previously implemented and re-queued.

5. **Add effort value to the approval confirmation message template** - In `plugins/core/skills/drive-approval/SKILL.md`, the "Handle Approval" section (line 51) says "Update ticket with effort and Final Report (use **write-final-report** skill)". Add explicit guidance: "Set effort to one of: 0.1h, 0.25h, 0.5h, 1h, 2h, 4h" directly in this instruction, so the valid values are visible at the point of decision.

## Patches

### `plugins/core/skills/update-ticket-frontmatter/sh/update.sh`

> **Note**: This patch is speculative - verify line numbers before applying.

```diff
--- a/plugins/core/skills/update-ticket-frontmatter/sh/update.sh
+++ b/plugins/core/skills/update-ticket-frontmatter/sh/update.sh
@@ -17,6 +17,15 @@ if [ ! -f "$TICKET" ]; then
     exit 1
 fi

+# Validate effort values
+if [ "$FIELD" = "effort" ]; then
+    case "$VALUE" in
+        0.1h|0.25h|0.5h|1h|2h|4h) ;; # valid
+        *) echo "Error: effort must be one of: 0.1h, 0.25h, 0.5h, 1h, 2h, 4h"
+           echo "Got: $VALUE"
+           exit 1 ;;
+    esac
+fi
+
 if grep -q "^${FIELD}:" "$TICKET"; then
     sed -i.bak "s/^${FIELD}:.*/${FIELD}: ${VALUE}/" "$TICKET"
 else
```

### `plugins/core/skills/write-final-report/SKILL.md`

> **Note**: This patch is speculative - verify exact content before applying.

```diff
--- a/plugins/core/skills/write-final-report/SKILL.md
+++ b/plugins/core/skills/write-final-report/SKILL.md
@@ -12,7 +12,9 @@ After user approves implementation, update the ticket with effort and final repor

 ## Update Effort Field

-Follow the preloaded **update-ticket-frontmatter** skill for valid effort values.
+Estimate actual time spent on this implementation, then set effort to the nearest valid value.
+
+**The ONLY valid values are:** `0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h`

 > **⚠️ COMMON MISTAKE**: DO NOT use t-shirt sizes or minute values!
 >
```

### `plugins/core/skills/drive-approval/SKILL.md`

> **Note**: This patch is speculative - verify exact content before applying.

```diff
--- a/plugins/core/skills/drive-approval/SKILL.md
+++ b/plugins/core/skills/drive-approval/SKILL.md
@@ -48,7 +48,7 @@ Users can also select "Other" to provide free-form feedback.

 When user selects "Approve" or "Approve and stop":

-1. Update ticket with effort and Final Report (use **write-final-report** skill)
+1. Update ticket with effort (one of: `0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h`) and Final Report (use **write-final-report** skill)
 2. Archive and commit (use **archive-ticket** skill)
 3. For "Approve": continue to next ticket
 4. For "Approve and stop": end drive session
```

## Considerations

- The most impactful fix is adding validation to `update.sh` (step 1) because it creates a hard failure when an invalid value is attempted, forcing Claude to retry with a correct value. The documentation improvements (steps 2-5) reduce the likelihood of the first attempt being wrong but cannot guarantee correctness. (`plugins/core/skills/update-ticket-frontmatter/sh/update.sh`)
- Historical tickets in `feat-20260128-001720` branch still have invalid effort values like `effort: XS` and `effort: S`. These were created before the validation hook existed. The hook now prevents new invalid values via Write/Edit, but the `update.sh` bypass remains open. (`.workaholic/tickets/archive/feat-20260128-001720/`)
- The `validate-ticket.sh` hook only runs on Write/Edit tool operations. When `update.sh` modifies the file via `sed`, the hook is not triggered, creating a validation gap. Adding validation to `update.sh` itself closes this gap. (`plugins/core/hooks/validate-ticket.sh`)
- The `drive-navigator.md` references effort for prioritization (line 59), but since tickets in todo always have empty effort fields, this reference is misleading and may prime Claude to think in terms of effort sizing rather than hour-based tracking. (`plugins/core/agents/drive-navigator.md` line 59)
- Claude's tendency to use t-shirt sizes may also be reinforced by the user providing `effort: M` as a parameter to `/ticket`. Consider whether the ticket command should explicitly ignore or strip effort hints from the user's input to avoid priming. (`plugins/core/commands/ticket.md`)
