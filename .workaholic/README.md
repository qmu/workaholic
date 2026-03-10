---
title: Work
description: Working artifacts index for Workaholic plugin marketplace
category: developer
modified_at: 2026-03-10T01:13:03+09:00
commit_hash: f76bde2
---

[English](README.md) | [日本語](README_ja.md)

# Work

This is the working artifacts hub for the Workaholic plugin marketplace.

- [constraints/](constraints/) - Manager-generated prescriptive boundaries
- [guides/](guides/README.md) - User documentation
- [policies/](policies/README.md) - Policy documentation (testing, security, quality, operations)
- [specs/](specs/README.md) - Technical specifications
- [stories/](stories/README.md) - Development narratives and PR descriptions per branch
- [terms/](terms/README.md) - Consistent term definitions across the project
- [tickets/](tickets/README.md) - Implementation work queue and archives

## Plugins

- [Drivin](../plugins/drivin/README.md) - Core development workflow: branch, commit, pull-request, ticket-driven development
- [Trippin](../plugins/trippin/README.md) - AI-oriented exploration and creative development workflow

## Design Policy

### Cultivating Semantics

Developer cognitive load is the primary bottleneck in software productivity. Workaholic invests heavily in generating structured knowledge artifacts to reduce this load. The trade-off is intentional: more upfront work creating documentation pays dividends in reduced context-switching, faster onboarding, and better decision-making.

Each artifact type serves a specific cognitive purpose:

| Artifact   | Purpose                           | Reduces cognitive load by...           |
| ---------- | --------------------------------- | -------------------------------------- |
| Tickets    | Change requests (future and past) | Capturing intent before implementation |
| Specs      | Current state snapshot            | Providing authoritative reference      |
| Stories    | Development narrative             | Preserving decision context            |
