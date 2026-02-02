---
created_at: 2026-02-02T19:24:08+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.1h
commit_hash: 94a6108
category: Added
---

# Implement Continuous Drive Loop

## Overview

When `/drive` finishes implementing all tickets that the navigator initially planned, it should re-check the `.workaholic/tickets/todo/` directory for any new tickets that may have been created during the drive session (e.g., by the user in another terminal, or by a `/ticket` command during revisions). If new tickets exist, invoke the navigator again to prioritize them and continue driving. This creates a loop that only stops when the todo directory is truly empty or the user explicitly stops with "Approve and stop".

## Key Files

- `plugins/core/commands/drive.md` - Main drive command, Phase 3 completion logic needs enhancement
- `plugins/core/agents/drive-navigator.md` - Navigator that lists/prioritizes tickets, will be re-invoked

## Related History

Historical tickets show progressive enhancement of the /drive command from simple sequential processing to intelligent prioritization with approval flow. The auto-continue feature removes friction between tickets, but the drive still terminates after one batch of navigator-planned tickets.

Past tickets that touched similar areas:

- [20260123002535-drive-auto-continue.md](.workaholic/tickets/archive/feat-20260122-210543/20260123002535-drive-auto-continue.md) - Removed between-ticket confirmation (same command: drive.md)
- [20260131194500-per-ticket-approval-in-drive-loop.md](.workaholic/tickets/archive/feat-20260131-125844/20260131194500-per-ticket-approval-in-drive-loop.md) - Moved approval to command level, established current loop architecture
- [20260131125946-intelligent-drive-prioritization.md](.workaholic/tickets/archive/feat-20260131-125844/20260131125946-intelligent-drive-prioritization.md) - Added navigator-based prioritization and icebox fallback

## Implementation Steps

### 1. Update Phase 3 completion logic in drive.md

Replace the current Phase 3 (which simply summarizes and ends) with a continuous loop:

```markdown
### Phase 3: Re-check and Continue

After all tickets from the navigator's list are processed:

1. **Re-check todo directory**:
   ```bash
   ls -1 .workaholic/tickets/todo/*.md 2>/dev/null
   ```

2. **If new tickets found**:
   - Inform user: "Found N new ticket(s) added during this session."
   - Re-invoke drive-navigator with mode = "normal"
   - Handle navigator response (same as Phase 1)
   - Continue to Phase 2 with the new ticket list
   - Repeat until todo is empty or user stops

3. **If no new tickets**:
   - Check icebox (existing behavior from navigator)
   - If user declines icebox or icebox empty, proceed to Phase 4

### Phase 4: Completion

After todo is truly empty (and user declines icebox):
- Summarize what was done
- List all commits created across all batches
- Inform user that all tickets have been processed
```

### 2. Track session-wide statistics

Maintain counters across multiple navigator batches:

- Total tickets implemented
- Total commits created
- List of all commit hashes

These should persist across re-invocations of the navigator.

### 3. Handle the "Approve and stop" escape hatch

The existing "Approve and stop" option should break out of the entire continuous loop (not just the current batch). This is already the expected behavior but should be documented clearly.

### 4. Update the Example Workflow section (if present)

Illustrate the new continuous behavior:

```markdown
Example flow:
1. Navigator finds 3 tickets, prioritizes them
2. Drive implements ticket 1, user approves
3. Drive implements ticket 2, user approves
4. User creates ticket 4 in another terminal
5. Drive implements ticket 3, user approves
6. Re-check: finds ticket 4
7. Navigator re-invoked, prioritizes ticket 4
8. Drive implements ticket 4, user approves
9. Re-check: no new tickets
10. Check icebox (if any)
11. Session complete
```

## Considerations

- **Session-wide state**: The drive command already maintains context across the Phase 2 loop. Extending this to include re-navigator invocations should be natural since the command conversation persists.
- **User awareness**: Users may not realize new tickets were picked up. The "Found N new ticket(s)" message helps with transparency.
- **Infinite loop risk**: The only way to stop is "Approve and stop" or natural completion. This is intentional - users who want to pause should use the stop option.
- **Navigator mode**: Re-invocations should use mode = "normal" (not icebox), since we're checking for new todo tickets.
- **Icebox check timing**: Only check icebox after todo is confirmed empty on re-check, not after each batch.

## Final Report

Implemented the continuous drive loop by updating `plugins/core/commands/drive.md`:

- Replaced Phase 3 "Completion" with "Re-check and Continue" that checks for new tickets via `ls` and re-invokes the navigator if found
- Added Phase 4 "Completion" for final session summary after todo is truly empty
- Added session-wide tracking guidance for maintaining counters across navigator batches
- Updated "Approve and stop" to explicitly break out of the entire continuous loop
