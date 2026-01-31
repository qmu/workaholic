---
type: bugfix
layer: Config
effort: 0.25h
created_at: 2026-01-31T13:41:35+09:00
author: noreply@anthropic.com
commit_hash: 140520e
category: Changed
---

# Enforce Selectable Options in Drive Approval Prompts

## Overview

During `/drive`, Claude sometimes asks text questions like "approve?" instead of presenting selectable options via `AskUserQuestion`. This forces users to type responses instead of clicking buttons, degrading the user experience.

The drive-workflow skill mentions `AskUserQuestion` but doesn't explicitly require the selectable `options` parameter format. This ambiguity allows Claude to fall back to open-ended text questions.

## Related History

- `20260128211728-add-fail-option-to-drive-approval.md` - Added Fail option to AskUserQuestion
- `20260129164500-simplify-approval-options-when-stopping.md` - Simplified to 3 options
- `20260128213850-rename-fail-to-abandon-with-analysis.md` - Renamed Fail to Abandon

## Key Files

- `plugins/core/skills/drive-workflow/SKILL.md` - Step 3 approval flow
- `plugins/core/commands/drive.md` - Lines 79-82 prioritization confirmation

## Implementation

1. **Update drive-workflow Step 3** to explicitly require `options` parameter:
   - Add explicit instruction: "ALWAYS use AskUserQuestion with selectable options"
   - Show exact tool parameter format with `options` array
   - Emphasize: "NEVER ask open-ended text questions during approval"

2. **Update drive.md confirmation prompts** (lines 79-82 and 148-155):
   - Add same explicit requirement for selectable options
   - Ensure icebox prompts also use selectable format

## Acceptance Criteria

- All approval prompts in drive-workflow use `AskUserQuestion` with `options` parameter
- All confirmation prompts in drive.md use selectable options
- No open-ended text questions during `/drive` session

## Final Report

Development completed as planned.

**Changes Made**:
- Updated `plugins/core/skills/drive-workflow/SKILL.md` Step 3 with explicit JSON format for `AskUserQuestion` with `options`
- Updated `plugins/core/commands/drive.md` icebox fallback, order confirmation, and Critical Rules sections to require selectable options
