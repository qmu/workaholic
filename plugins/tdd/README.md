# TDD

Ticket-driven development workflow for Claude Code projects.

## Why So Much Documentation?

TDD intentionally generates extensive documentation artifacts (tickets, changelogs, archives) as **cognitive investments**. Developer cognitive load is the primary bottleneck in software productivity - context-switching, onboarding, and understanding past decisions consume significant mental energy.

Each artifact reduces this load:
- **Tickets** capture intent before implementation, preventing "what was I trying to do?"
- **Specs** provide authoritative reference for current state, eliminating guesswork
- **Stories** preserve the narrative of how decisions were made across a feature
- **Changelogs** explain what changed and why, enabling quick catch-up

The upfront cost of documentation pays dividends when you (or a teammate) return to code weeks later.

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
