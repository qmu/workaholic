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
| `doc-writer`     | Documentation specialist that updates docs for every code change         |

## Workflow

1. **Create tickets**: Use `/ticket` to write implementation specs
2. **Implement tickets**: Use `/drive` to implement and commit each ticket
3. **Archive**: Tickets are automatically archived after implementation

## Feedback Loop

When reviewing an implementation and requesting changes:

1. **Update the ticket first** - Add/modify steps based on feedback
2. **Then implement** - Make the requested changes
3. **Review again** - Ask for approval once more

```
User:   [Needs changes] "Add error handling for edge case X"
Claude: [Updates ticket with new step for error handling]
Claude: [Implements error handling]
Claude: [Asks for review again]
```

**Why this matters**: Archived tickets become project documentation. Keeping tickets updated ensures accurate history of what was built and helps future developers understand the full scope of changes.

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
