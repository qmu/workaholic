---
title: Documentation
description: Documentation index for Workaholic plugin marketplace
category: developer
last_updated: 2026-01-23
---

# Documentation

This directory contains documentation for the Workaholic plugin marketplace.

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
        ├── <ticket>.md            # Completed tickets
        └── CHANGELOG.md           # Branch changes
```

Create tickets with `/ticket <description>` and implement with `/drive`.

## Quick Links

| Document                                               | Description                     |
| ------------------------------------------------------ | ------------------------------- |
| [Getting Started](specs/user-guide/GETTING_STARTED.md) | Installation and setup          |
| [Commands](specs/user-guide/COMMANDS.md)               | All available commands          |
| [Workflow](specs/user-guide/WORKFLOW.md)               | Ticket-driven development guide |
| [Architecture](specs/developer-guide/ARCHITECTURE.md)  | Plugin structure                |
| [Contributing](specs/developer-guide/CONTRIBUTING.md)  | How to contribute               |
