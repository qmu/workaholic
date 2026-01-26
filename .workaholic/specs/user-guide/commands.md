---
title: Command Reference
description: Complete documentation for all Workaholic commands
category: user
modified_at: 2026-01-27T01:21:14+09:00
commit_hash: 5d468b0
---

[English](commands.md) | [日本語](commands_ja.md)

# Command Reference

Workaholic provides a unified **core** plugin with all development workflow commands.

## Git Workflow Commands

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

The PR description is generated from a story document that includes seven sections: Summary, Motivation, Journey, Changes, Outcome, Performance, and Notes. The story serves as the single source of truth for PR content and is saved to `.workaholic/stories/<branch-name>.md`. Performance metrics use hours for single-session work (under 8 hours) and business days for multi-day work, providing meaningful velocity measurements.

Any remaining unfinished tickets are automatically moved to icebox before creating the PR.

## Ticket-Driven Development Commands

### /ticket

Explores the codebase and writes an implementation specification.

```bash
/ticket add user authentication
/ticket icebox refactor database layer
```

Claude reads your codebase to understand existing patterns and architecture, then generates a detailed implementation ticket. The ticket includes an overview, key files to modify, step-by-step implementation plan, and considerations.

Tickets are saved to `.workaholic/tickets/` with timestamps. Use `icebox` to store tickets for later implementation in `.workaholic/tickets/icebox/`. Ticket files don't need to be committed separately - they're automatically included in the next `/drive` commit.

### /drive

Implements queued tickets from top to bottom.

```bash
/drive
/drive icebox
```

Claude picks up tickets from `.workaholic/tickets/`, implements them one by one, asks for your approval, writes a Final Report documenting any deviations, then commits and archives each ticket before moving to the next. The `icebox` argument lets you select from deferred tickets.

## Workflow Summary

The typical workflow combines these commands:

1. `/branch` - Start a new feature branch
2. `/ticket <description>` - Write implementation spec
3. `/drive` - Implement the ticket
4. `/pull-request` - Create PR for review (automatically updates documentation)

Each ticket gets its own commit, and the CHANGELOG tracks all changes for the PR summary.
