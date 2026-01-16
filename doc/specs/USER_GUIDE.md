# User Guide

## Workflows

### Ticket-Driven Development

1. **Create tickets** with `/ticket <description>`

   - Analyzes codebase to understand implementation approach
   - Writes detailed ticket to `doc/tickets/`

2. **Implement tickets** with `/drive`

   - Picks up next ticket from queue
   - Implements and commits each ticket
   - Archives completed tickets

3. **Create PR** with `/pull-request`
   - Auto-generates summary from commits
   - Links to implemented tickets

### Commit Workflow

The `/commit` command:

1. Groups changes into logical units
2. Formats code with prettier
3. Creates meaningful commit messages

### Documentation Auto-Update

The `/drive` command automatically updates documentation in `doc/specs/` when implementing tickets:

- User docs: GETTING_STARTED, USER_GUIDE, FAQ
- Developer docs: FEATURES, ARCHITECTURE, NFR, API, DATA_MODEL, CONFIGURATION, SECURITY, TESTING, DEPENDENCIES

## Commands Reference

See [CLAUDE.md](../../CLAUDE.md) for complete command reference.
