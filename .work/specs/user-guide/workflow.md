---
title: Workflow Guide
description: How to use ticket-driven development with Workaholic
category: user
last_updated: 2026-01-24
commit_hash: 56855c7
---

[English](workflow.md) | [日本語](workflow_ja.md)

# Workflow Guide

Workaholic uses a ticket-driven development approach where implementation planning happens locally in your repository rather than in GitHub issues.

## The Local-First Approach

Traditional development creates GitHub issues, discusses requirements in comments, waits for assignment, and only then begins implementation. Workaholic inverts this: you write specs locally, implement immediately after approval, and only touch GitHub when opening a pull request.

This works well for solo developers and small teams who want to move quickly without coordination overhead. Planning artifacts remain as markdown files in your repository, providing the same documentation benefits without the context switching.

## Workflow Diagram

```mermaid
flowchart TD
    A[Start feature] --> B[/branch]
    B --> C[/ticket description]
    C --> D{Review spec}
    D -->|Approve| E[/drive]
    D -->|Revise| C
    E --> F{More tickets?}
    F -->|Yes| C
    F -->|No| G[/pull-request]
    G --> H[Code review]
    H --> I[Merge]
```

## Step-by-Step

### 1. Create a Branch

Start with a clean branch for your work:

```bash
/branch
```

This creates a timestamped branch like `feat-20260123-143022`.

### 2. Write a Ticket

Describe what you want to implement:

```bash
/ticket add dark mode toggle to settings
```

Claude explores your codebase, understands the architecture, and generates a detailed implementation spec. Review the spec in `.work/tickets/` and revise if needed.

### 3. Implement the Ticket

Run drive to implement:

```bash
/drive
```

Claude follows the spec, makes changes, and runs any type checks. After implementation, Claude asks for your approval. If you approve, it writes a Final Report to the ticket documenting any deviations from the plan, then commits and archives the ticket. If not, provide feedback and it will adjust.

### 4. Repeat as Needed

For multi-ticket features, write additional tickets and run `/drive` again. Each ticket becomes one commit with a clear purpose.

### 5. Create Pull Request

When ready for review:

```bash
/pull-request
```

The command automatically runs `/sync-doc-specs` to update documentation before creating the PR. The PR summary is generated from archived tickets, which contain the commit hash, category, and description of what each change accomplished and why.

## Directory Structure

Tickets follow this structure:

```
.work/tickets/
├── 20260123-add-dark-mode.md      # Queued ticket
├── 20260123-fix-login-bug.md      # Another queued ticket
├── icebox/                         # Deferred tickets
│   └── 20260120-refactor-db.md
└── archive/
    └── feat-20260123-143022/       # Branch-specific archive
        └── 20260122-add-auth.md    # Completed ticket with Final Report
```

Each ticket includes YAML frontmatter with metadata: `date`, `author`, `type`, `layer`, `effort`, plus `commit_hash` and `category` added when archived.

Completed tickets include a "Final Report" section that documents whether implementation went as planned or any deviations that occurred during development. This creates a historical record of decisions made during implementation.

## Benefits

The ticket-driven approach provides several advantages. Specs are reviewed before implementation, catching issues early. Each commit maps to one ticket, creating clean history. Tickets serve as the single source of truth for change metadata, and the root CHANGELOG is auto-generated from them during PR creation. All planning artifacts stay in the repository for future reference. Final Reports in archived tickets document what actually happened during implementation, preserving institutional knowledge. Branch stories synthesize the entire development journey into a narrative, giving reviewers quick context before diving into individual changes. Performance metrics in stories use hours for single-session work and business days for multi-day work, providing meaningful velocity measurements rather than misleading raw elapsed time.

## When to Use Icebox

Use icebox for tickets you want to defer:

```bash
/ticket icebox optimize image loading
```

Later, retrieve from icebox:

```bash
/drive icebox
```

This lets you capture ideas without committing to immediate implementation.
