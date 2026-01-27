---
created_at: 2026-01-27T10:07:40+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash: 6cb68d0
category: Changed
---

# Fix /ticket to skip commit step when called during /drive

## Overview

When `/ticket` is invoked during a `/drive` session, it should skip the commit step (step 6). The drive command's archive script already includes uncommitted ticket files via `git add -A`, so tickets created mid-drive will be committed with the next implementation.

Currently, `/ticket` always commits, creating unnecessary "Add ticket for X" commits that break the clean one-commit-per-implementation flow of `/drive`.

## Key Files

- `plugins/core/commands/ticket.md` - The ticket command that needs conditional commit logic

## Implementation Steps

1. Add a note to step 6 in `plugins/core/commands/ticket.md`:

   ```markdown
   6. **Commit the Ticket**

      **IMPORTANT**: Skip this step if invoked during `/drive`. The drive command's archive script includes uncommitted tickets via `git add -A`, so the ticket will be committed with the implementation.

      - Stage only the newly created ticket file: `git add <ticket-path>`
      - Commit with message: "Add ticket for <short-description>"
      ...
   ```

2. Update step 7 presentation to reflect conditional behavior:
   - If during `/drive`: "Ticket created (will be committed with implementation)"
   - If standalone: existing behavior with commit confirmation

## Considerations

- Claude cannot programmatically detect if it's "during /drive" - it must use context awareness
- The instruction must be clear enough that Claude recognizes the drive context
- This aligns with drive.md line 137-141 which states tickets are auto-included
