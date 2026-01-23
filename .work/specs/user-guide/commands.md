---
title: Command Reference
description: Complete documentation for all Workaholic commands
category: user
last_updated: 2026-01-23
commit_hash: 5df4de4
---

[English](commands.md) | [日本語](commands_ja.md)

# Command Reference

Workaholic provides two plugins: **core** for essential git workflow commands, and **tdd** for ticket-driven development.

## Core Plugin

### /branch

Creates a topic branch with a timestamp prefix for consistent naming.

```bash
/branch
```

This generates branches like `feat-20260120-205418`, ensuring unique branch names and chronological ordering. The prefix helps identify when work started on a feature.

### /commit

Commits changes in logical units with meaningful commit messages.

```bash
/commit
```

Claude analyzes your staged and unstaged changes, groups them logically, and creates commits with messages that explain the purpose of each change. The commit message follows conventional style: present-tense verb, focused on the "why" rather than the "what".

### /pull-request

Creates or updates a pull request with an auto-generated summary.

```bash
/pull-request
```

The PR description includes three main sections:

- **Summary** - A numbered list of changes generated from the branch CHANGELOG
- **Story** - A narrative synthesized from archived tickets that explains the motivation, journey, and decisions made during development
- **Changes** - Detailed explanations for each change

The story document is also saved to `.work/stories/<branch-name>.md` for future reference.

## TDD Plugin

### /sync-doc-specs

Updates documentation in `.work/specs/` to reflect the current codebase state.

```bash
/sync-doc-specs
```

Claude gathers context from archived tickets in the current branch, audits existing documentation, identifies what needs to be updated, and applies changes following documentation standards. This command ensures documentation stays synchronized with code changes before creating a pull request.

### /ticket

Explores the codebase and writes an implementation specification.

```bash
/ticket add user authentication
/ticket icebox refactor database layer
```

Claude reads your codebase to understand existing patterns and architecture, then generates a detailed implementation ticket. The ticket includes an overview, key files to modify, step-by-step implementation plan, and considerations.

Tickets are saved to `.work/tickets/` with timestamps. Use `icebox` to store tickets for later implementation in `.work/tickets/icebox/`.

### /drive

Implements queued tickets from top to bottom.

```bash
/drive
/drive icebox
```

Claude picks up tickets from `.work/tickets/`, implements them one by one, asks for your approval, writes a Final Report documenting any deviations, then commits and archives each ticket before moving to the next. The `icebox` argument lets you select from deferred tickets.

## Workflow Summary

The typical workflow combines these commands:

1. `/branch` - Start a new feature branch
2. `/ticket <description>` - Write implementation spec
3. `/drive` - Implement the ticket
4. `/sync-doc-specs` - Update documentation (optional, also runs during `/pull-request`)
5. `/pull-request` - Create PR for review

Each ticket gets its own commit, and the CHANGELOG tracks all changes for the PR summary.
