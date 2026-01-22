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

- **[For Users](specs/for-user/)** - Installation, commands, and workflow guides
- **[For Developers](specs/for-developer/)** - Architecture and contribution guidelines

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

| Document                                             | Description                     |
| ---------------------------------------------------- | ------------------------------- |
| [Getting Started](specs/for-user/GETTING_STARTED.md) | Installation and setup          |
| [Commands](specs/for-user/COMMANDS.md)               | All available commands          |
| [Workflow](specs/for-user/WORKFLOW.md)               | Ticket-driven development guide |
| [Architecture](specs/for-developer/ARCHITECTURE.md)  | Plugin structure                |
| [Contributing](specs/for-developer/CONTRIBUTING.md)  | How to contribute               |
