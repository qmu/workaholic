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

- **Rules**: General and TypeScript coding guidelines

### tdd

Ticket-driven development workflow for structured implementation.

| Command                 | Description                                                   |
| ----------------------- | ------------------------------------------------------------- |
| /ticket `<description>` | Explore codebase and write implementation spec                |
| /drive                  | Implement tickets from `.work/tickets/` one by one, commit each |

Also includes:

- **Skills**: `archive-ticket` - Complete commit workflow

## Workflow

1. **Create ticket**: `/ticket add user authentication` - writes ticket to `.work/tickets/`
2. **Implement**: `/drive` - picks up tickets, implements, commits, archives
3. **Ship**: `/pull-request` - creates PR with summary from changelog

## Development Routine

Workaholic takes a local-first approach to development planning. Instead of creating GitHub issues and waiting for discussion, you write implementation tickets directly as markdown files in your repository. Claude Code explores your codebase, understands the context, and generates detailed implementation specs that you review and approve before any code is written.

This workflow differs significantly from traditional issue-driven development. In conventional workflows, you create a GitHub issue, discuss requirements in comments, wait for assignment, create a branch, implement the feature, and finally open a pull request for review. With workaholic, you run `/ticket` to generate a spec, run `/drive` to implement it immediately after approval, and only touch GitHub when you run `/pull-request` at the end.

The benefits become apparent in rapid prototyping and small team environments. There's no waiting for issue triage or assignment, no context switching between GitHub's web interface and your editor, and no long discussion threads to parse. Claude Code acts as an AI pair programmer that reads your entire codebase, writes thorough specs, and implements them in one continuous flow. You stay in your terminal, review specs when they're ready, and ship features faster.

This approach works best when you have clear goals and don't need extensive stakeholder discussion before implementation. For solo developers and small teams who want to move quickly, keeping planning artifacts local as markdown files provides the same documentation benefits as GitHub issues without the coordination overhead. GitHub remains valuable for pull request review and collaboration, but planning and implementation happen locally with AI assistance.

## Author

tamurayoshiya <a@qmu.jp>
