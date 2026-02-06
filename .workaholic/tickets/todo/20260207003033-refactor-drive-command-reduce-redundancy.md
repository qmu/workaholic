---
created_at: 2026-02-07T00:30:33+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Refactor drive.md to Reduce Redundancy Against Preloaded Skills

## Overview

The `/drive` command file (`plugins/core/commands/drive.md`) has grown to 178 lines, exceeding the architecture policy guideline of ~50-100 lines for commands. Much of the content duplicates or restates knowledge already captured in its preloaded skills (`drive-workflow`, `drive-approval`, `write-final-report`, `archive-ticket`). The command should be reorganized to be a thin orchestration layer that delegates to skills, rather than re-explaining skill content inline.

## Key Files

- `plugins/core/commands/drive.md` - The drive command (178 lines, target ~80-100 lines)
- `plugins/core/skills/drive-workflow/SKILL.md` - Implementation workflow skill (already covers steps 1-4 of implementation)
- `plugins/core/skills/drive-approval/SKILL.md` - Approval flow skill (already covers all approval options and feedback handling)
- `plugins/core/skills/write-final-report/SKILL.md` - Final report skill (already covers effort update and report writing)
- `plugins/core/skills/archive-ticket/SKILL.md` - Archive skill (already covers archive workflow and prerequisites)
- `plugins/core/skills/commit/SKILL.md` - Commit skill (already covers message format and safety)

## Related History

The drive command has undergone multiple rounds of refactoring: skills were extracted from a monolithic workflow, a driver subagent was added then removed, approval skills were split then re-merged, and safety guidelines were added. Each iteration added content to drive.md, creating accumulation of inline details that now overlap with the skills.

Past tickets that touched similar areas:

- [20260131153736-split-drive-workflow-skill.md](.workaholic/tickets/archive/feat-20260131-125844/20260131153736-split-drive-workflow-skill.md) - Extracted approval/report/abandon skills from drive-workflow (same file: drive.md)
- [20260202125850-remove-driver-subagent.md](.workaholic/tickets/archive/drive-20260201-112920/20260202125850-remove-driver-subagent.md) - Inlined implementation steps back into drive.md after removing driver subagent
- [20260202184602-merge-approval-flow-skills.md](.workaholic/tickets/archive/drive-20260202-134332/20260202184602-merge-approval-flow-skills.md) - Merged approval skills into unified drive-approval skill
- [20260204173959-strengthen-git-safeguards-in-drive.md](.workaholic/tickets/archive/drive-20260204-160722/20260204173959-strengthen-git-safeguards-in-drive.md) - Added Git Safety section to drive.md that overlaps with drive-workflow prohibitions
- [20260205210724-remove-needs-revision-option-enforce-ticket-update.md](.workaholic/tickets/archive/drive-20260205-195920/20260205210724-remove-needs-revision-option-enforce-ticket-update.md) - Added detailed feedback handling that restates drive-approval Section 3
- [20260202192408-continuous-drive-loop.md](.workaholic/tickets/archive/drive-20260202-134332/20260202192408-continuous-drive-loop.md) - Added Phase 3/4 re-check loop to drive.md

## Implementation Steps

1. **Audit redundancy** - Identify content in drive.md that restates skill knowledge:
   - Step 2.1 lines 44-52: Restates drive-workflow steps 1-4 verbatim. Replace with "Follow the preloaded **drive-workflow** skill."
   - Step 2.2 lines 56-69: Restates drive-approval Section 1 format. Replace with "Follow the preloaded **drive-approval** skill (Section 1) to present approval dialog."
   - Step 2.3 "Approve" lines 78-85: Restates write-final-report and archive-ticket skill usage. Condense to brief orchestration: "1. Follow **write-final-report** skill. 2. Verify update. 3. Archive using **archive-ticket** skill."
   - Step 2.3 "Approve and stop" lines 87-96: Nearly identical to "Approve" block. Consolidate the two into a shared sequence with a conditional note about stopping.
   - Step 2.3 "Free-form feedback" lines 98-106: Restates drive-approval Section 3. Replace with "Follow **drive-approval** skill (Section 3)."
   - Git Safety section lines 159-178: Overlaps with drive-workflow Prohibited Operations table. Remove from drive.md and let drive-workflow own this knowledge.

2. **Consolidate "Approve" and "Approve and stop"** - These two paths share 90% of their steps (write final report, verify, archive). Write the shared steps once and note the divergence point:
   ```markdown
   **"Approve" or "Approve and stop"**:
   1. Follow **write-final-report** skill to update effort and append Final Report
   2. **Verify update succeeded**: If Edit tool fails, halt and report error. DO NOT archive.
   3. Archive and commit using **archive-ticket** skill
   4. If "Approve and stop": break loop, skip Phase 3, go to Phase 4
   5. Otherwise: continue to next ticket
   ```

3. **Remove Git Safety section** - The drive-workflow skill already contains the comprehensive "Prohibited Operations" table with the multi-contributor rationale. The commit skill covers safe staging. The drive-approval skill covers safe abandonment with targeted restore. Having this duplicated in drive.md creates a maintenance burden when guidelines evolve.

4. **Tighten Phase 1 and Phase 3 language** - These sections are already concise but can reference skills where applicable instead of showing inline bash commands:
   - Phase 3 line 118-119: The inline `ls -1 .workaholic/tickets/todo/*.md 2>/dev/null` is acceptable as a simple one-liner, but add a note that the shell script principle applies if this grows more complex.

5. **Verify cross-references** - After trimming, ensure every skill reference uses the correct section numbers (e.g., "Section 1", "Section 3", "Section 4" in drive-approval).

6. **Validate constraint compliance** - After refactoring, verify:
   - Command is within ~80-100 lines (down from 178)
   - All knowledge lives in skills, command is orchestration only
   - No inline bash commands violate the Shell Script Principle
   - All approval paths still function correctly by tracing through skill references

## Considerations

- The "Critical Rules" section (lines 146-157) about never moving tickets autonomously is command-level orchestration logic, not skill knowledge, so it should remain in drive.md (`plugins/core/commands/drive.md` lines 146-157)
- The Phase 1 navigator invocation (lines 19-36) is pure orchestration and should remain as-is (`plugins/core/commands/drive.md`)
- The "Session-wide tracking" note (lines 139-143) is drive-specific state management, not skill knowledge, so it stays (`plugins/core/commands/drive.md`)
- The `> **Rule**: The ticket file must always reflect...` block (lines 105-106) adds emphasis to a drive-approval skill concept. After removing the redundant inline steps, this rule reminder can be kept as a one-line note referencing the skill, rather than expanding on the steps (`plugins/core/commands/drive.md`)
- The "Approve and stop" path's instruction to "break out of the entire continuous loop" (line 95) is orchestration logic specific to the drive command's Phase 3/4 structure, so it must remain even after consolidation with "Approve" (`plugins/core/commands/drive.md` lines 87-96)
