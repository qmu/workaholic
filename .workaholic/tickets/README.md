---
title: Tickets
description: Implementation work queue and archives
category: developer
last_updated: 2026-01-23
---

# Tickets

This directory manages implementation work through ticket files.

## Structure

```
tickets/
├── todo/                          # Queued tickets (to implement)
│   └── <timestamp>-<description>.md
├── icebox/                        # Deferred tickets (for later)
├── fail/                          # Failed tickets (implementation didn't work)
└── archive/
    └── <branch>/                  # Completed tickets per branch
```

## Workflow

1. Create tickets with `/ticket <description>`
2. Implement with `/drive` (processes from top to bottom)
3. Tickets are automatically archived after implementation

## Queued Tickets

Tickets waiting to be implemented appear in `todo/` with timestamp prefixes ensuring chronological order.

## Failed Tickets

Tickets that couldn't be implemented successfully are moved to `fail/` when the user selects "Fail" during `/drive` review. This preserves the ticket for future reference or analysis without cluttering the queue.

## Archive

Completed tickets are moved to `archive/<branch>/` with a Final Report section documenting any deviations from the original plan.
