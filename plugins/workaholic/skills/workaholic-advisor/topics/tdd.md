# TDD Workflow

Best practices for ticket-driven development with `/ticket` and `/drive` commands.

## Overview

Two commands that work together:

1. **`/ticket`** - Write implementation tickets before coding
2. **`/drive`** - Implement tickets one by one with approval gates

## When to Propose

- Project has no ticket-driven workflow
- User wants structured implementation process
- Team needs approval gates before commits

## Workflow

```
User: /ticket add dark mode
Claude: [explores codebase, writes ticket to doc/tickets/20260115-add-dark-mode.md]

User: /drive
Claude: [implements ticket, asks for review, commits, archives]
```

## Directory Structure

```
doc/tickets/
├── 20260115-feature-a.md      # Pending tickets (queue)
├── 20260115-feature-b.md
├── icebox/                    # Deferred tickets
│   └── 20260110-idea.md
└── archive/
    └── <branch-name>/
        ├── CHANGELOG.md       # Branch-level changelog
        └── 20260114-done.md   # Completed tickets
```

## Customization Questions

| Question         | Options                              | Default      |
| ---------------- | ------------------------------------ | ------------ |
| Ticket location  | doc/tickets/, .tickets/, custom      | doc/tickets/ |
| Approval gates   | implementation + commit, commit only | both         |
| Archive strategy | by branch, flat                      | by branch    |
| Branch CHANGELOG | yes, no                              | yes          |

## Templates

- `../templates/ticket-command.md` - Ticket writing command
- `../templates/drive-command.md` - Ticket implementation command
