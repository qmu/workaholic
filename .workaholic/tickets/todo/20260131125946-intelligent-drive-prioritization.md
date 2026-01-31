---
created_at: 2026-01-31T12:59:46+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Intelligent Ticket Prioritization for /drive

## Overview

Redesign `/drive` to prioritize tickets intelligently instead of processing them top-to-bottom alphabetically. Claude Code will analyze ticket metadata (type, layer, effort estimates) and context to determine optimal execution order. When no tickets remain in `todo/`, automatically offer to work on `icebox/` tickets.

## Key Files

- `plugins/core/commands/drive.md` - Main drive command to modify with prioritization logic
- `plugins/core/skills/drive-workflow/SKILL.md` - Workflow skill (minimal changes expected)
- `plugins/core/skills/create-ticket/SKILL.md` - Reference for available metadata fields (type, layer, effort)
- `.workaholic/tickets/README.md` - Directory structure documentation

## Related History

Historical tickets show progressive enhancement of the /drive command with approval options and failure handling, plus established patterns for parallel execution and icebox integration.

Past tickets that touched similar areas:

- [20260127100902-extract-drive-ticket-skills.md](.workaholic/tickets/archive/feat-20260126-214833/20260127100902-extract-drive-ticket-skills.md) - Refactored /drive into thin orchestrator (same file: drive.md)
- [20260128211728-add-fail-option-to-drive-approval.md](.workaholic/tickets/archive/feat-20260128-012023/20260128211728-add-fail-option-to-drive-approval.md) - Added intelligent ticket disposition options (same command)
- [20260127211737-invoke-release-readiness-in-parallel.md](.workaholic/tickets/archive/feat-20260128-001720/20260127211737-invoke-release-readiness-in-parallel.md) - Demonstrates parallel context-grouping pattern
- [20260125114643-require-approval-for-icebox-moves.md](.workaholic/tickets/archive/feat-20260124-200439/20260125114643-require-approval-for-icebox-moves.md) - Established icebox approval policy

## Implementation Steps

1. **Update drive.md with prioritization logic**

   Replace the simple alphabetical listing with intelligent analysis:

   ```markdown
   ### 1. List and Analyze Tickets

   List all tickets in `.workaholic/tickets/todo/`:
   ```bash
   ls -1 .workaholic/tickets/todo/*.md 2>/dev/null
   ```

   For each ticket, extract YAML frontmatter to get:
   - `type`: bugfix > enhancement > refactoring > housekeeping (severity ranking)
   - `layer`: Group related layers for context efficiency
   - `effort`: Lower effort tickets can be batched for quick wins

   ### 2. Determine Priority Order

   Claude Code should consider:
   - **Severity**: Bugfixes take precedence over enhancements
   - **Context grouping**: Process tickets affecting same layer/files together to minimize context switching
   - **Quick wins**: Lower-effort tickets may be prioritized for momentum
   - **Dependencies**: If ticket A modifies files that ticket B reads, process A first

   Present the proposed order to the user before starting.
   ```

2. **Add icebox fallback behavior**

   When `todo/` is empty:

   ```markdown
   ### Empty Todo Queue

   If no tickets found in `todo/`:
   1. Check if `.workaholic/tickets/icebox/` has tickets
   2. If icebox has tickets, ask user: "No queued tickets. Would you like to work on icebox tickets?"
   3. If user agrees, enter icebox mode automatically
   4. If icebox is also empty, inform user: "No tickets in queue or icebox."
   ```

3. **Update the ticket listing display**

   Show tickets grouped by priority tier:

   ```markdown
   Found 4 tickets to implement:

   **High Priority (bugfix)**
   1. 20260131-fix-login-error.md

   **Normal Priority (enhancement)**
   2. 20260131-add-dark-mode.md [layer: UX]
   3. 20260131-add-api-endpoint.md [layer: Infrastructure]

   **Low Priority (housekeeping)**
   4. 20260131-cleanup-unused-imports.md

   Proposed order considers severity and context grouping.
   Proceed with this order?
   ```

4. **Allow user to override order**

   After presenting the proposed order, ask user to confirm or reorder:

   ```markdown
   Options:
   - "Proceed" - Execute in proposed order
   - "Reorder" - Let user specify a different order
   - "Pick one" - Let user select a specific ticket to start with
   ```

## Considerations

- **Backward compatibility**: Users who prefer chronological order can still achieve it by using timestamp-prefixed filenames and selecting "Reorder"
- **Metadata availability**: Some tickets may lack complete metadata (e.g., `effort` is filled post-implementation). Prioritization should handle missing fields gracefully
- **Prompt length**: The prioritization logic adds instructions to drive.md. Keep it concise to avoid excessive prompt bloat
- **User trust**: Present the reasoning for prioritization order so users understand and can override if needed
- **Icebox transition**: The fallback to icebox should be optional, not automatic, respecting the existing "icebox requires explicit intent" philosophy
