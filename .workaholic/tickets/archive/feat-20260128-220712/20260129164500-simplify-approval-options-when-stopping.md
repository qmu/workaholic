---
created_at: 2026-01-29T16:45:00+09:00
author: a@qmu.jp
type: improvement
layer: [Config]
effort: 0.1h
commit_hash: 36ef853
category: Removed
---

# Remove "Needs changes" from Approval Options When Stopping Drive

## Overview

The drive workflow's step 3 approval prompt shows 4 options: [Approve / Approve and stop / Needs changes / Abandon]. The "Needs changes" option is unnecessary complexity. When a user wants changes, they should communicate directly rather than selecting an option that triggers a complex multi-iteration loop. Simplify the approval prompt to 3 options.

## Key Files

- `plugins/core/skills/drive-workflow/SKILL.md` - Step 3 approval prompt and "Needs changes" handling logic

## Related History

- Step 3 approval prompt was part of the original drive-workflow skill design
- The "Needs changes" loop adds complexity: update ticket → re-implement → ask again

## Implementation Steps

1. Update `plugins/core/skills/drive-workflow/SKILL.md`:
   - Remove "Needs changes" from the approval options list
   - Change prompt from `[Approve / Approve and stop / Needs changes / Abandon]` to `[Approve / Approve and stop / Abandon]`
   - Remove the "If user requests changes" section (lines 45-51)
   - Update approval prompt format section to reflect 3 options

2. Update `plugins/core/commands/drive.md`:
   - Update example workflow to show only 3 options (line 69)

## Considerations

- Users who want changes can simply type their feedback instead of selecting "Needs changes"
- Simplifies the workflow from 4 options to 3
- Removes the ticket-update-and-re-implement loop complexity
- "Abandon" remains for cases where implementation should be discarded entirely

## Final Report

Development completed as planned. Also removed the "If user requested changes during review" Final Report template since that flow no longer exists.
