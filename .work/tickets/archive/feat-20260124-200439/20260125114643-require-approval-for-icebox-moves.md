---
date: 2026-01-25
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash: 8935f8a
category: Changed
---

# Require Developer Approval Before Moving Tickets to Icebox

## Overview

When Claude Code encounters a ticket it considers "out of scope" or "too complex," it sometimes autonomously moves the ticket to icebox and commits the change without asking the developer. This is unacceptable because:

1. The developer loses visibility into what happened
2. The developer loses control over their ticket queue
3. Commits happen without consent

Claude Code must **always** ask the developer before moving any ticket to icebox.

## Key Files

- `plugins/core/commands/drive.md` - The drive command that processes tickets

## Implementation Steps

1. Add a new section to drive.md titled "## Critical Rules" after the "## Notes" section
2. Add explicit prohibition: "NEVER autonomously move tickets to icebox"
3. Add instruction: "If a ticket cannot be implemented, use AskUserQuestion to ask the developer what to do"
4. Provide options for the developer:
   - "Move to icebox" - Claude moves it and continues
   - "Skip for now" - Leave in queue, move to next ticket
   - "Abort drive" - Stop the drive session entirely

## Considerations

- This is a behavior constraint, not a feature addition
- The explicit prohibition needs to be prominent so Claude Code follows it
- The options give the developer control while not blocking progress entirely

## Final Report

Added "## Critical Rules" section to `plugins/core/commands/drive.md`:

1. Explicit prohibition: "NEVER autonomously move tickets to icebox"
2. Instructions to stop and ask developer when ticket cannot be implemented
3. Three options: "Move to icebox", "Skip for now", "Abort drive"
4. Final reminder about requiring explicit approval for all ticket moves
