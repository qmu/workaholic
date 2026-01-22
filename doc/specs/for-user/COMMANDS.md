---
title: Command Reference
description: Complete documentation for all Workaholic commands
category: user
last_updated: 2026-01-23
---

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

The summary is generated from the branch CHANGELOG, which tracks all commits made during ticket implementation. This provides reviewers with context about what changed and why.

## TDD Plugin

### /ticket

Explores the codebase and writes an implementation specification.

```bash
/ticket add user authentication
/ticket icebox refactor database layer
```

Claude reads your codebase to understand existing patterns and architecture, then generates a detailed implementation ticket. The ticket includes an overview, key files to modify, step-by-step implementation plan, and considerations.

Tickets are saved to `doc/tickets/` with timestamps. Use `icebox` to store tickets for later implementation in `doc/tickets/icebox/`.

### /drive

Implements queued tickets from top to bottom.

```bash
/drive
/drive icebox
```

Claude picks up tickets from `doc/tickets/`, implements them one by one, updates documentation via the doc-writer agent, asks for your approval, then commits and archives each ticket before moving to the next. The `icebox` argument lets you select from deferred tickets.

Documentation updates are mandatory for every ticket. The doc-writer agent audits the entire documentation structure and updates all affected files.

## Workflow Summary

The typical workflow combines these commands:

1. `/branch` - Start a new feature branch
2. `/ticket <description>` - Write implementation spec
3. `/drive` - Implement the ticket
4. `/pull-request` - Create PR for review

Each ticket gets its own commit, and the CHANGELOG tracks all changes for the PR summary.
