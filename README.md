# Workaholic

Claude Code plugin marketplace for development workflow.

## Installation

```bash
claude
```

```bash
/plugin marketplace add qmu/workaholic
```

Choose user scope, and better enable auto-updates.

## Plugins

### core

Essential development commands for everyday git workflow.

| Command       | Description                                                       |
| ------------- | ----------------------------------------------------------------- |
| /branch       | Create topic branch with timestamp (e.g., `feat-20260120-205418`) |
| /commit       | Commit changes in logical units with meaningful messages          |
| /pull-request | Create or update PR with auto-generated summary                   |

Also includes:

- **Agents**: `discover-project`, `discover-claude-dir` - Codebase exploration
- **Rules**: General and TypeScript coding guidelines

### tdd

Ticket-driven development workflow for structured implementation.

| Command                 | Description                                                   |
| ----------------------- | ------------------------------------------------------------- |
| /ticket `<description>` | Explore codebase and write implementation spec                |
| /drive                  | Implement tickets from `doc/tickets/` one by one, commit each |

Also includes:

- **Skills**: `archive-ticket` - Complete commit workflow with changelog update

## Workflow

1. **Create ticket**: `/ticket add user authentication` - writes ticket to `doc/tickets/`
2. **Implement**: `/drive` - picks up tickets, implements, commits, archives
3. **Ship**: `/pull-request` - creates PR with summary from changelog

## Author

tamurayoshiya <a@qmu.jp>
