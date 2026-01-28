---
title: Add "Fail" option to /drive approval prompt
category: Added
created_at: 2026-01-28T21:17:28+09:00
effort: 0.25h
commit_hash: dc3ef61
---

# Add "Fail" option to /drive approval prompt

## Context

The `/drive` command currently offers three approval options after implementation:

- **Approve** - commit and continue to next ticket
- **Approve and stop** - commit this ticket but stop driving
- **Needs changes** - user provides feedback to fix

There is no option to mark a ticket as failed and move on. If implementation is fundamentally flawed or the ticket itself was misguided, users must either keep requesting changes (wasting time) or manually manage the ticket.

## Related History

- `20260125113309-drive-approve-and-stop-option.md` - Added "Approve and stop" option
- `20260125114643-require-approval-for-icebox-moves.md` - Established that ticket moves require explicit user approval

## Task

Add a fourth approval option "Fail" that moves the ticket to `.workaholic/tickets/fail/` directory and continues to the next ticket.

## Implementation

### 1. Update drive-workflow skill

Edit `plugins/core/skills/drive-workflow/SKILL.md`:

1. Add "Fail" to the AskUserQuestion options in step 3:
   - "Approve" - proceed to commit and continue
   - "Approve and stop" - commit and stop driving
   - "Needs changes" - user will provide feedback
   - **"Fail" - mark as failed and continue to next ticket**

2. Update the approval prompt format:
   ```
   [Approve / Approve and stop / Needs changes / Fail]
   ```

3. Add handling for "Fail" selection:
   - Create `.workaholic/tickets/fail/` if it doesn't exist
   - Move ticket from `todo/` to `fail/` (no archiving, no commit of changes)
   - Discard uncommitted implementation changes (`git checkout -- .`)
   - Continue to next ticket without user confirmation

### 2. Update tickets README

Edit `.workaholic/tickets/README.md`:

1. Add `fail/` to the directory structure:
   ```
   tickets/
   ├── todo/        # Queued tickets (to implement)
   ├── icebox/      # Deferred tickets (for later)
   ├── fail/        # Failed tickets (implementation didn't work)
   └── archive/     # Completed tickets per branch
   ```

2. Add explanation of the fail directory purpose

### 3. Update drive command (if needed)

Review `plugins/core/commands/drive.md` for any mentions of approval options that need updating.

## Verification

1. Run `/drive` with a ticket
2. When prompted for approval, select "Fail"
3. Confirm:
   - Ticket moved to `.workaholic/tickets/fail/`
   - Implementation changes discarded
   - Drive continues to next ticket (if any)

## Final Report

Development completed as planned.
