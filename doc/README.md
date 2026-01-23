---
title: Documentation
description: Documentation index for Workaholic plugin marketplace
category: developer
last_updated: 2026-01-23
---

# Documentation

This directory contains documentation for the Workaholic plugin marketplace.

## Design Policy

### Cognitive Investment

Developer cognitive load is the primary bottleneck in software productivity. Workaholic invests heavily in generating structured knowledge artifacts to reduce this load. The trade-off is intentional: more upfront work creating documentation pays dividends in reduced context-switching, faster onboarding, and better decision-making.

Each artifact type serves a specific cognitive purpose:

| Artifact   | Purpose                           | Reduces cognitive load by...           |
| ---------- | --------------------------------- | -------------------------------------- |
| Tickets    | Change requests (future and past) | Capturing intent before implementation |
| Specs      | Current state snapshot            | Providing authoritative reference      |
| Stories    | Development narrative             | Preserving decision context            |
| Changelogs | Historical record                 | Explaining what changed and why        |

### Specs (doc/specs/)

Specifications represent a **snapshot of the current state**. They describe what exists now - the comprehensive present situation of the project. When you read specs, you understand how things work today.

- Always up-to-date with the current implementation
- Comprehensive coverage of all features and architecture
- Written as reference documentation

### Tickets (doc/tickets/)

Tickets represent **change requests** - past and future. They are a working log focused on specific topics. Each ticket captures what needs to change or what has changed.

- Queued tickets: Future work to be implemented
- Archived tickets: Historical record of completed changes
- Focused on the delta, not the whole picture

## Specifications

Detailed documentation is organized in [specs/](specs/README.md):

- **[For Users](specs/user-guide/)** - Installation, commands, and workflow guides
- **[For Developers](specs/developer-guide/)** - Architecture and contribution guidelines

## Tickets

The [tickets/](tickets/) directory manages implementation work:

```
tickets/
├── <timestamp>-<description>.md  # Queued tickets
├── icebox/                        # Deferred tickets
└── archive/
    └── <branch>/
        └── <ticket>.md            # Completed tickets
```

Create tickets with `/ticket <description>` and implement with `/drive`.

## Changelogs

The [changelogs/](changelogs/) directory tracks changes per branch:

```
changelogs/
├── README.md                      # Index
├── main.md                        # Changes on main
└── <branch>.md                    # Branch-specific changes
```

Each branch changelog records commits during development. When a PR is created, entries are consolidated into the root `CHANGELOG.md`.

## Quick Links

| Document                                               | Description                     |
| ------------------------------------------------------ | ------------------------------- |
| [Getting Started](specs/user-guide/getting-started.md) | Installation and setup          |
| [Commands](specs/user-guide/commands.md)               | All available commands          |
| [Workflow](specs/user-guide/workflow.md)               | Ticket-driven development guide |
| [Architecture](specs/developer-guide/architecture.md)  | Plugin structure                |
| [Contributing](specs/developer-guide/contributing.md)  | How to contribute               |
