---
title: Command Reference
description: Complete documentation for all Workaholic commands
category: user
modified_at: 2026-01-28T01:00:15+09:00
commit_hash: 88b4b18
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

### /report

Generates comprehensive documentation and creates or updates a pull request.

```bash
/report
```

The command orchestrates documentation generation in two phases. In Phase 1, four subagents run in parallel: changelog-writer updates `CHANGELOG.md`, spec-writer updates `.workaholic/specs/`, terms-writer updates `.workaholic/terms/`, and release-readiness analyzes changes for release preparation. In Phase 2, story-writer generates the PR narrative using the release-readiness output. Finally, pr-creator handles GitHub PR creation using the generated story as the body.

The PR description is generated from a story document that includes eleven sections: Overview, Motivation, Journey, Changes, Outcome, Historical Analysis, Concerns, Ideas, Performance, Release Preparation, and Notes. The Journey section includes a Mermaid flowchart (Topic Tree) showing relationships between changes grouped by theme or concern, giving reviewers visual context for the narrative. The Changes section lists each ticket as its own subsection in chronological order. The Release Preparation section includes a release-readiness verdict with concerns and pre/post-release instructions. The story serves as the single source of truth for PR content and is saved to `.workaholic/stories/<branch-name>.md`. Performance metrics use hours for single-session work (under 8 hours) and business days for multi-day work, providing meaningful velocity measurements.

Any remaining unfinished tickets are automatically moved to icebox before creating the PR.

## Ticket-Driven Development Commands

### /ticket

Explores the codebase and writes an implementation specification.

```bash
/ticket add user authentication
/ticket icebox refactor database layer
```

Claude reads your codebase to understand existing patterns and architecture, then generates a detailed implementation ticket. The ticket includes an overview, key files to modify, step-by-step implementation plan, and considerations.

Tickets are saved to `.workaholic/tickets/todo/` with timestamps. Use `icebox` to store tickets for later implementation in `.workaholic/tickets/icebox/`. Ticket files don't need to be committed separately - they're automatically included in the next `/drive` commit.

### /drive

Implements queued tickets from top to bottom.

```bash
/drive
/drive icebox
```

Claude picks up tickets from `.workaholic/tickets/todo/`, implements them one by one, asks for your approval, writes a Final Report documenting any deviations, then commits and archives each ticket before moving to the next. The `icebox` argument lets you select from deferred tickets.

## Workflow Summary

The typical workflow combines these commands:

1. `/branch` - Start a new feature branch
2. `/ticket <description>` - Write implementation spec
3. `/drive` - Implement the ticket
4. `/report` - Generate documentation and create PR for review

Each ticket gets its own commit, and the CHANGELOG tracks all changes for the PR summary.
