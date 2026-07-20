---
name: strategy
description: Use when the user asks to "start a strategy", "record our direction", "what strategies are in flight", or when mission creation needs to resolve which strategy a mission executes. A strategy is long-lived direction (戦略) with no completion conditions; missions are its execution plans. This skill creates a strategy, lists strategies with their computed mission rollups, reads the mission→strategy relation, and retires a strategy.
allowed-tools: Bash
user-invocable: false
metadata:
  internal: true
---

# Strategy

A **strategy** is a first-class knowledge artifact that sits **above missions**: the long-lived statement of *direction* — 戦略 in the word's plain sense — with **no concrete completion conditions**. It answers *why are these missions being launched*. Missions are a strategy's **execution plans** ("which missions do we launch to execute this strategy"); the strategy outlives every one of them.

The hierarchy is a **model first** (`workaholic:planning` / `modeling-centric-design`): the elements and their relations are stated before any script instantiates them.

- **Elements**: strategy → mission → ticket → commit, each describing code change and its planning at *its own* granularity.
- **Relation**: a mission records the one strategy it executes (`strategy: <slug>` on `mission.md`), the same direction as ticket→mission (`mission:` on a ticket). Nothing is stored on the strategy side, so an archived mission never leaves a dangling reference and per-strategy rollups are always **computed**, never stored.
- **Granularity rule**: no artifact restates a lower level's detail. A strategy answers "why", a mission "what does this batch of tickets accomplish", a ticket "what is this one change". (The full four-layer discipline and its balance test live in `workaholic:mission`'s Granularity section.)

## Terminology record

"Strategy" is a new artifact term, chosen deliberately (`workaholic:planning` / `terminology` — one concept, one word). Rejected alternatives and why:

- **epic** — a generic project-management word this repo bans as an artifact name (same reason "mission" is not called an epic).
- **roadmap** — implies ordering and dates; a strategy carries neither, only direction.
- **theme / initiative** — weaker, vaguer commitment than the durable direction intended.

"Strategy" matches the developer's own vocabulary and the execution-plan relation (a mission *executes a strategy*), so it is the one word for this concept.

## Schema

`strategy.md` frontmatter — a strategy is **direction, not work**, so it has none of the mission's execution machinery (no worktree, no tickets, no assignee, no acceptance checklist, no `drive_authorized`). Adding any of those would collapse the granularity split this artifact exists to create.

```yaml
---
type: Strategy          # non-empty OKF type
title: <human title>
slug: <derived slug>    # mission/scripts/slug.sh, the single slug source
status: active          # active | retired
created_at: <ISO8601>
author: <id/email>
---
```

Body sections, in order:

- `## Direction` — the strategy's substance: the prose statement of where and why. Observable consequences are welcome; **completion conditions are deliberately absent**.
- `## Changelog` — append-only, dated, one line per event (same line format as a mission). Retirement is a recorded transition, never a deletion.

There is **no `## Missions` section**: the mission→strategy relation lives on the mission (single source, read via `read-strategy-relation.sh`), and per-strategy rollups are computed by `list.sh`.

## Allowed locations

```
.workaholic/strategies/active/<slug>/strategy.md    # status: active
.workaholic/strategies/archive/<slug>/strategy.md   # status: retired (ended; rare)
```

Two areas keyed off `status` — the same active/archive split as missions and tickets, minus worktrees. `README.md`/`index.md` conventions match the rest of the `.workaholic/` OKF bundle.

## Scripts

All POSIX `#!/bin/sh -eu`, JSON out, git-staging their writes; slug and layout helpers are reused, never copied.

- `scripts/lib/resolve.sh` — the single source of slug-to-path resolution (root from a domain fact, absolute paths). Modeled on `mission/scripts/lib/resolve.sh` at smaller scale; **no living migration** (strategies have no legacy layout).
- `scripts/create.sh` `"<title>"` — scaffold `strategies/active/<slug>/strategy.md`, stamp metadata via the gather skill, refresh OKF indexes, git-stage. Reuses `mission/scripts/slug.sh` (single slug source). Refuses an existing slug in either area. Emits `{created, slug, path}`.
- `scripts/list.sh` — JSON array `{slug, title, status, path, missions: [<mission-slug>]}` across both areas; the `missions` rollup is **computed** by scanning missions' `strategy:` field through the reader, never stored.
- `scripts/read-strategy-relation.sh` `<mission-file>` — the single reader of a mission's `strategy:` frontmatter field (mirror of `mission/scripts/read-relation.sh`: frontmatter-only, tolerates bare value and `[a]` list form, one slug per line, never fails). Convention is **one strategy per mission**; the list tolerance keeps a future many-valued turn migration-free.
- `scripts/retire.sh` `<slug-or-file> [date]` — flip `status` to `retired`, append the changelog line (via `mission/scripts/append-changelog.sh`, the single changelog writer), move to `archive/`, refresh indexes, git-stage. The `close.sh` analogue with **no** worktree/successor/carry semantics.

## Retirement is rare

A strategy whose direction **changed** is *rewritten in place* (its changelog records the turn), not retired. Only a strategy that is genuinely **over** is retired. There is no "carried" outcome and no acceptance list to reconcile — that machinery belongs to missions, which are work; a strategy is direction.

## OKF

`strategy.md` carries a non-empty `type: Strategy`, and `okf/scripts/refresh-index.sh` regenerates the `strategies/` area indexes (per-area + bundle root) exactly as it does for `missions/`.
