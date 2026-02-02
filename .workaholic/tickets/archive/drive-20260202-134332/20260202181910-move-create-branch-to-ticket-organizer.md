---
created_at: 2026-02-02T18:19:10+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 0.25h
commit_hash: 55a4953
category: Changed
---

# Move create-branch Skill from /ticket Command to ticket-organizer Subagent

## Overview

Move the branch creation responsibility from the `/ticket` command to the `ticket-organizer` subagent. Currently, `/ticket` has `create-branch` in its skills list and handles branch creation in Step 1. This change moves the skill to ticket-organizer, making the command thinner and centralizing the ticket creation workflow in the subagent.

## Key Files

- `plugins/core/commands/ticket.md` - Remove create-branch skill and Step 1 branch logic
- `plugins/core/agents/ticket-organizer.md` - Add create-branch skill and branch creation step
- `plugins/core/skills/create-branch/SKILL.md` - Existing skill (unchanged)

## Related History

Historical tickets show the evolution of branch creation: first as a standalone command, then integrated into `/ticket`, now moving to ticket-organizer for better separation of concerns.

Past tickets that touched similar areas:

- [20260129012614-auto-branch-on-ticket.md](.workaholic/tickets/archive/feat-20260128-220712/20260129012614-auto-branch-on-ticket.md) - Integrated branch creation into /ticket command (being reversed)
- [20260128002536-extract-create-branch-skill.md](.workaholic/tickets/archive/feat-20260128-001720/20260128002536-extract-create-branch-skill.md) - Created the create-branch skill (same skill being moved)
- [20260202135507-parallel-subagent-discovery-in-ticket-organizer.md](.workaholic/tickets/archive/drive-20260202-134332/20260202135507-parallel-subagent-discovery-in-ticket-organizer.md) - Recent ticket-organizer refactoring (same file)

## Implementation Steps

1. **Update ticket-organizer.md frontmatter**:
   - Add `create-branch` to the skills list:
     ```yaml
     skills:
       - create-ticket
       - create-branch
     ```

2. **Add branch creation step to ticket-organizer.md**:
   - Insert new step "0. Check Branch" before "1. Parse Request":
     ```markdown
     ### 0. Check Branch

     Check current branch: `git branch --show-current`

     If on `main` or `master` (not a topic branch):
     1. Create branch: `git checkout -b "drive-$(date +%Y%m%d-%H%M%S)"`
     2. Include branch name in output JSON

     Topic branch pattern: `drive-*`, `trip-*`
     ```

3. **Update ticket-organizer.md output format**:
   - Add optional `branch_created` field to success JSON:
     ```json
     {
       "status": "success",
       "branch_created": "drive-20260202-181910",
       "tickets": [...]
     }
     ```

4. **Update ticket.md frontmatter**:
   - Remove `create-branch` from skills list:
     ```yaml
     ---
     name: ticket
     description: Explore codebase and write implementation ticket for `$ARGUMENT`
     ---
     ```

5. **Update ticket.md Step 1**:
   - Remove the entire "Step 1: Check Branch" section
   - Renumber remaining steps (current Step 2 becomes Step 1, Step 3 becomes Step 2)

6. **Update ticket.md Step 2 (now Step 1)**:
   - Update to handle new `branch_created` field from ticket-organizer response:
     ```markdown
     ### Step 1: Invoke Ticket Organizer
     ...
     - `status: "success"` - If `branch_created` is present, confirm branch creation. Proceed to step 2.
     ```

7. **Update ticket.md Step 3 (now Step 2)**:
   - Update step number in heading from "Step 3" to "Step 2"
   - Keep commit and present logic unchanged

## Considerations

- **Architecture alignment**: This change makes `/ticket` a thinner orchestration layer, delegating more logic to ticket-organizer
- **Branch name in response**: ticket-organizer returns the branch name so `/ticket` can inform the user
- **No user interaction in subagent**: ticket-organizer cannot use AskUserQuestion, so it uses the default "drive" prefix (matching current behavior in ticket.md)
- **Backward compatible**: The change is internal; user experience remains the same (`/ticket` still creates branches when needed)

## Final Report

Implemented as specified. Moved create-branch skill from /ticket command to ticket-organizer subagent. Added step 0 for branch checking, updated output JSON format with optional branch_created field. Removed branch logic from ticket.md and renumbered steps.
