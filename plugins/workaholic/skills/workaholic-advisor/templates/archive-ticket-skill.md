---
name: archive-ticket
description: Archive a completed ticket to the branch-specific archive folder. Use after committing a ticket implementation.
allowed-tools: Bash
---

# Archive Ticket

Archive a completed ticket to `doc/tickets/archive/<branch>/`.

## Usage

Invoke after committing a ticket:

```
/archive-ticket doc/tickets/20260115-feature.md
```

## Instructions

Run the archive script with the ticket path:

```bash
bash .claude/skills/archive-ticket/scripts/archive.sh "$ARGUMENTS"
```

The script will:
1. Get the current branch name
2. Create the archive directory if needed
3. Move the ticket to `doc/tickets/archive/<branch>/`
4. Output the new location
