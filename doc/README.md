---
title: Documentation
description: Documentation index for Workaholic plugin marketplace
category: developer
last_updated: 2026-01-23
---

# Documentation

## Overview

Workaholic is a Claude Code plugin marketplace containing development workflow plugins. The primary documentation lives in the root README.md file, as this is a simple configuration-based project without complex architecture or runtime code.

## Documentation Structure

This project follows a minimal documentation approach appropriate for a plugin marketplace:

- **[README.md](../README.md)** - Main documentation covering installation, plugin descriptions, and usage
- **[CLAUDE.md](../CLAUDE.md)** - Development instructions for contributors to this repository
- **doc/tickets/** - Implementation tickets managed by the `/ticket` and `/drive` commands

## Ticket System

The ticket-driven development workflow uses this directory structure:

```
doc/
└── tickets/
    ├── <timestamp>-<description>.md  # Queued tickets
    └── archive/
        └── <branch>/
            ├── <timestamp>-<description>.md  # Completed tickets
            └── CHANGELOG.md                  # Changes from that branch
```

Tickets are created with `/ticket <description>` and implemented with `/drive`. After implementation, tickets are automatically archived to `doc/tickets/archive/<branch>/` with corresponding CHANGELOG entries.

## For Plugin Users

All user-facing documentation is in [README.md](../README.md). It covers:

- How to install the marketplace
- What plugins are available (core and tdd)
- Command reference for each plugin
- Development workflow examples

## For Plugin Developers

If you're contributing to this marketplace:

1. Read [CLAUDE.md](../CLAUDE.md) for project structure and commands
2. Use `/ticket` to create implementation specs
3. Use `/drive` to implement tickets one by one
4. Use `/pull-request` to create PRs with auto-generated summaries

## Why This Structure?

This project doesn't need extensive documentation directories because:

- It's a plugin marketplace (configuration, not code)
- Plugins are simple markdown files with JSON metadata
- No APIs, databases, or runtime security concerns
- No build process or complex dependencies

The README.md provides all necessary information for both users and developers. Additional documentation would be redundant and harder to maintain.
