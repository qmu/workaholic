# Lazy mkdir for /ticket Command

## Overview

Update the `/ticket` command instructions to only create the `doc/tickets/` directory when it doesn't already exist. Currently, Claude proactively runs `mkdir -p doc/tickets` every time the command is invoked, which is unnecessary and clutters output when the directory already exists.

## Key Files

- `plugins/tdd/commands/ticket.md` - The ticket command definition that needs updating

## Implementation Steps

1. Add a new instruction step between "Ask Clarifying Questions" and "Write the Ticket" in `ticket.md`
2. The new step should instruct Claude to check if `doc/tickets/` exists before creating it
3. Use the pattern: "Only create the directory if it doesn't exist" with guidance to use Bash with `[ -d dir ] || mkdir -p dir` or simply use the Write tool which handles parent directory creation automatically

## Considerations

- The Write tool in Claude Code automatically creates parent directories, so explicit mkdir may not be needed at all
- The instruction should be clear that the goal is to avoid unnecessary mkdir operations
- For icebox tickets (`doc/tickets/icebox/`), the same lazy-creation pattern should apply
