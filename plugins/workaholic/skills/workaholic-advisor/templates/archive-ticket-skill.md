---
name: archive-ticket
description: Archive a completed ticket to branch-specific folder. Use when moving a ticket file to the archive after implementation is committed.
allowed-tools: Bash
user-invocable: false
---

# Archive Ticket

Move a completed ticket to `doc/tickets/archive/<branch>/`.

## When to Use

Use this skill after committing a ticket implementation to archive the ticket file.

## Instructions

Run the bundled script with the ticket path:

```bash
bash .claude/skills/archive-ticket/scripts/archive.sh <ticket-path>
```

Example:

```bash
bash .claude/skills/archive-ticket/scripts/archive.sh doc/tickets/20260115-feature.md
```
