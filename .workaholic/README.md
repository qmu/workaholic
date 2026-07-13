---
type: Guide
title: Work
description: Working artifacts hub for the workaholic plugin — what lives here and where to enter
category: developer
---

# Work

This is the working artifacts hub for the `workaholic` plugin. The tree is an [Open Knowledge Format](https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf) bundle: enter at [index.md](index.md) (regenerated automatically by the workflows) and every document carries frontmatter with a `type` key.

- [concerns/](concerns/index.md) - Deferred concerns surfaced in past PR stories, judged on later reports (living corpus)
- [deployments/](deployments/index.md) - Deployment targets and confirmation methods `/ship` executes
- [guides/](guides/) - User documentation
- [missions/](missions/index.md) - Long-lived goals spanning many tickets, with acceptance progress and an append-only changelog; in-progress missions live under `missions/active/`, ended ones under `missions/archive/` (moved by `/mission close`, which also tears down the mission's worktree). Creating a mission with `/mission "<title>"` spins up a dedicated `.worktrees/<slug>/` worktree holding the mission statement and ordered kickoff tickets, so the developer opens that worktree and immediately `/drive`s. Each mission worktree is assigned a unique local port base (in its `.env`) so several worktrees can run dev/docs servers at once without colliding. Auto-rolled by `/drive`, `/report`, and `/ship` as missioned work lands; surfaced read-only in `/catch`, which also shows unmerged in-flight work heading toward each mission, and in `/mission summary` (just your assigned active missions)
- [policies/](policies/) - Project-local policy documentation
- [release-notes/](release-notes/index.md) - Per-ship release records
- [specs/](specs/index.md) - Technical specifications
- [stories/](stories/index.md) - Development narratives and PR descriptions per branch
- [terms/](terms/index.md) - Consistent term definitions across the project
- [tickets/](tickets/) - Implementation work queue and archives (`todo/`, `archive/`, `icebox/`, `abandoned/`)
- [trips/](trips/index.md) - Trip design/decision artifacts per trip

For the full per-artifact lifecycle (who writes it, when, and how it survives or is eliminated through the ship process), see the **Artifacts under `.workaholic/`** section of the [root README](../README.md).

## Design Policy

### Cultivating Semantics

Developer cognitive load is the primary bottleneck in software productivity. Workaholic invests heavily in generating structured knowledge artifacts to reduce this load. The trade-off is intentional: more upfront work creating documentation pays dividends in reduced context-switching, faster onboarding, and better decision-making.

Each artifact type serves a specific cognitive purpose:

| Artifact   | Purpose                           | Reduces cognitive load by...           |
| ---------- | --------------------------------- | -------------------------------------- |
| Tickets    | Change requests (future and past) | Capturing intent before implementation |
| Specs      | Current state snapshot            | Providing authoritative reference      |
| Stories    | Development narrative             | Preserving decision context            |
