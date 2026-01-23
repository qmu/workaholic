---
title: Work
description: Working artifacts index for Workaholic plugin marketplace
category: developer
last_updated: 2026-01-23
---

[English](README.md) | [日本語](README_ja.md)

# Work

This is the working artifacts hub for the Workaholic plugin marketplace.

- [changelogs/](changelogs/README.md) - Historical record of changes per branch
- [specs/](specs/README.md) - Current state reference documentation
- [stories/](stories/README.md) - Development narratives per branch
- [terminology/](terminology/README.md) - Consistent term definitions across the project
- [tickets/](tickets/README.md) - Implementation work queue and archives

## Plugins

- [Core](../plugins/core/README.md) - Git workflow commands (`/branch`, `/commit`, `/pull-request`)
- [TDD](../plugins/tdd/README.md) - Ticket-driven development (`/ticket`, `/drive`, `/sync-src-doc`)

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
