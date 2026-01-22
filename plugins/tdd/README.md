# TDD

Ticket-driven development workflow for Claude Code projects.

## Commands

| Command                 | Description                                                              |
| ----------------------- | ------------------------------------------------------------------------ |
| `/ticket <description>` | Explore codebase and write implementation ticket                         |
| `/drive`                | Implement tickets from doc/tickets/ one by one, commit each, and archive |

## Skills

| Skill            | Description                                                              |
| ---------------- | ------------------------------------------------------------------------ |
| `archive-ticket` | Complete commit workflow - format, archive, update changelog, and commit |

## Workflow

1. **Create tickets**: Use `/ticket` to write implementation specs
2. **Implement tickets**: Use `/drive` to implement and commit each ticket
3. **Archive**: Tickets are automatically archived after implementation

## Ticket Storage

- Active tickets: `doc/tickets/`
- Icebox (deferred): `doc/tickets/icebox/`
- Archived: `doc/tickets/archive/<branch-name>/`

## Installation

Add to your Claude Code configuration:

```json
{
  "plugins": ["tdd"]
}
```
