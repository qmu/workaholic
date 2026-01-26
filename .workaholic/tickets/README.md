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
├── <timestamp>-<description>.md  # Queued tickets (to implement)
├── icebox/                        # Deferred tickets (for later)
└── archive/
    └── <branch>/                  # Completed tickets per branch
```

## Workflow

1. Create tickets with `/ticket <description>`
2. Implement with `/drive` (processes from top to bottom)
3. Tickets are automatically archived after implementation

## Queued Tickets

Tickets waiting to be implemented appear here with timestamp prefixes ensuring chronological order.

## Archive

Completed tickets are moved to `archive/<branch>/` with a Final Report section documenting any deviations from the original plan.
