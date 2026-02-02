---
created_at: 2026-02-02T20:54:05+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.1h
commit_hash: 73d9130
category: Changed
---

# Strengthen /ticket Command Notice to Prohibit Code Implementation

## Overview

Add explicit instruction to the `/ticket` command's notice section to prevent Claude from implementing code changes when the command is invoked. Currently, there is risk that Claude may interpret a ticket request as a request to both create a ticket AND implement the changes. The notice must clearly state that `/ticket` creates tickets only - never implements code.

## Key Files

- `plugins/core/commands/ticket.md` - Command file to modify (add prohibition to notice section)
- `plugins/core/agents/ticket-organizer.md` - Subagent may also benefit from similar instruction

## Related History

Past tickets about ticket command behavior and architecture:

- [20260202125814-ticket-command-alias-refactor.md](.workaholic/tickets/archive/drive-20260201-112920/20260202125814-ticket-command-alias-refactor.md) - Refactored /ticket to thin alias pattern (same command file)
- [20260128004252-thin-ticket-command.md](.workaholic/tickets/archive/feat-20260128-001720/20260128004252-thin-ticket-command.md) - Simplified ticket command structure (same layer: Config)
- [20260202205242-standardize-notice-section-format.md](.workaholic/tickets/todo/20260202205242-standardize-notice-section-format.md) - Pending ticket about notice format (related: same section)

## Implementation Steps

1. **Update the notice section in `ticket.md`**:
   - Locate line 8 (blockquote starting with `> When user input contains...`)
   - Add a clear prohibition statement: "NEVER implement code changes when this command is invoked - only create tickets"
   - Keep the existing command recognition hint

2. **Consider updating `ticket-organizer.md`**:
   - Review if the subagent needs similar explicit instruction
   - The organizer already has "CRITICAL: Never commit. Never use AskUserQuestion. Return JSON only."
   - May add: "CRITICAL: Never implement code changes - only discover context and write tickets"

3. **Example final notice format**:
   ```markdown
   > When user input contains `/ticket` - whether "create /ticket", "write /ticket", "add /ticket for X", or similar - they likely want this command.
   >
   > **CRITICAL: NEVER implement code changes when this command is invoked - only create tickets. The actual implementation happens later via `/drive`.**
   ```

## Considerations

- This change complements the pending ticket about notice section format standardization
- The prohibition should be prominent but not duplicate across too many files
- The TiDD workflow relies on clear separation: `/ticket` creates specs, `/drive` implements them
- Consider whether similar prohibitions are needed in other commands (e.g., `/story` should not implement code either)

## Final Report

Added explicit prohibition to both ticket.md and ticket-organizer.md. The command now has a `**CRITICAL:**` section stating code implementation is not allowed, and the subagent's existing CRITICAL section was extended with the same prohibition.
