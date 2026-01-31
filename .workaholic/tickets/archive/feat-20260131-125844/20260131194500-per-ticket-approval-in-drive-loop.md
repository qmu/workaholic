---
type: bugfix
effort: 0.25h
commit_hash: 4f70ff3created_at: 2026-01-31T19:45:00+09:00
category: Changedauthor: a@qmu.jp
---

# Add Per-Ticket Approval Confirmation to Drive Loop

## Overview

The `/drive` command currently asks for confirmation once via `drive-navigator` before implementing all tickets. Each individual ticket implementation by `driver` subagent includes `request-approval` skill that uses `AskUserQuestion`, but this prompt is consumed within the subagent's isolated context and never surfaces to the user.

Users expect to approve each ticket's implementation **before** it gets committed, but currently all tickets are implemented and committed in sequence without individual approval prompts.

## Root Cause

The `driver` subagent runs in an isolated context via the Task tool. When the driver calls `AskUserQuestion` through the `request-approval` skill:
1. The question is asked within the subagent's context
2. The subagent waits for/receives an answer (likely auto-proceeding or receiving no input)
3. The parent `/drive` command never sees the approval prompt
4. The ticket gets committed without user review

The Task tool's isolation prevents `AskUserQuestion` from surfacing to the parent conversation.

## Expected Behavior

For each ticket in the queue:
1. Driver implements the ticket changes
2. **User sees an approval dialog** with options: Approve / Approve and stop / Abandon
3. User explicitly selects an option
4. Only then does the driver proceed to commit (or abandon)

## Solution

Move the approval prompt from inside the `driver` subagent to the parent `/drive` command's loop. The driver should:
1. Implement changes
2. Return without committing (status: "pending_approval")
3. Let the parent `/drive` command ask for user approval
4. Based on response, invoke driver again to commit or abandon

### Alternative: Request-then-Return Pattern

1. Driver implements changes, prepares summary
2. Driver returns summary data (no commit yet)
3. `/drive` command asks user for approval using `AskUserQuestion`
4. Based on user response, `/drive` invokes appropriate action (commit or abandon)

## Key Files

- `plugins/core/commands/drive.md` - Main command loop, needs to handle approval
- `plugins/core/agents/driver.md` - Subagent that implements tickets, needs to return before approval
- `plugins/core/skills/drive-workflow/SKILL.md` - Workflow steps, Step 3 (request-approval) needs restructuring
- `plugins/core/skills/request-approval/SKILL.md` - Approval format template (may become command-level guidance)
- `plugins/core/skills/archive-ticket/SKILL.md` - Commit script, will be invoked by `/drive` after approval

## Implementation

1. **Modify `driver` subagent output contract**
   - Add new status: `"pending_approval"`
   - When implementation complete, return without committing:
     ```json
     {
       "status": "pending_approval",
       "summary": {
         "title": "Ticket title",
         "changes": ["Change 1", "Change 2"],
         "ticket_path": "..."
       }
     }
     ```

2. **Update `/drive` command loop**
   - After driver returns `"pending_approval"`:
     - Present approval dialog using `AskUserQuestion` with `request-approval` format
     - On "Approve": invoke archive-ticket script, continue loop
     - On "Approve and stop": invoke archive-ticket script, break loop
     - On "Abandon": invoke handle-abandon workflow, continue loop

3. **Update `drive-workflow` skill**
   - Remove Step 3 (request-approval) - moved to command level
   - Steps become: Read → Implement → Return summary (no commit)

4. **Update `request-approval` skill**
   - Change from "skill invoked by subagent" to "format template for command"
   - Keep the AskUserQuestion format specification

## Related History

- `20260131164315-add-driver-agent.md` - Introduced driver for isolated execution, defined per-ticket loop
- `20260131153736-split-drive-workflow-skill.md` - Split out request-approval skill
- `20260131134135-enforce-selectable-options-in-drive.md` - Mandated selectable options for approval
- `20260128211728-add-fail-option-to-drive-approval.md` - Added structured approval options
