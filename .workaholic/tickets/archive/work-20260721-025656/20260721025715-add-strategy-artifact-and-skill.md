---
created_at: 2026-07-21T02:57:15+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain, Config]
effort: 2h
commit_hash:
category: Added
depends_on:
mission: reorganize-missions-under-strategies
---

# Add the strategy artifact and skill

## Overview

Introduce **strategy** as a first-class knowledge artifact above missions: the long-lived statement of *direction* — 戦略 in the word's plain sense — with **no concrete completion conditions**. Missions are a strategy's execution plans ("which missions do we launch to execute this strategy"); the strategy outlives every one of them. This ticket builds the artifact and its internal skill only; wiring the mission-creation linkage is the dependent ticket `20260721025716`.

Layout mirrors missions (minus worktrees — a strategy never gets a worktree or tickets of its own):

```
.workaholic/strategies/active/<slug>/strategy.md    # status: active
.workaholic/strategies/archive/<slug>/strategy.md   # status: retired (ended; rare)
```

Schema (frontmatter): `type: Strategy`, `title`, `slug`, `status: active|retired`, `created_at`, `author`. Body sections, in order: `## Direction` (the strategy's substance — the prose statement of where and why; observable consequences welcome, completion conditions deliberately absent), `## Missions` is **not** a section — the mission→strategy relation lives on the mission (single source, read via the new reader), and per-strategy rollups are computed — and `## Changelog` (append-only, dated, same line format as missions).

## Policies

The standard engineering policies that govern this ticket. Read each linked hard copy before writing code; keep every change defensible against its Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — conventional layout for the new skill dir and scripts (applies to all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `#!/bin/sh -eu` scripts, no bash (applies to all code work)
- `workaholic:planning` / `policies/terminology.md` — "strategy" is a new artifact term: one concept, one word; record in the SKILL.md why it was chosen and what was rejected (epic/roadmap/theme/initiative)
- `workaholic:planning` / `policies/modeling-centric-design.md` — the strategy→mission→ticket→commit hierarchy is a model first; the SKILL.md states the elements and relations before the scripts
- `workaholic:design` / `policies/history-structures.md` — append-only changelog; retirement is a recorded transition, never a deletion
- `workaholic:implementation` / `policies/objective-documentation.md` — schema documented in verifiable language; decisions recorded with reasons

## Key Files

- `plugins/workaholic/skills/strategy/SKILL.md` — new internal skill (`metadata.internal: true`, `user-invocable: false`): schema, allowed location, the no-completion-conditions rule, terminology record, script contracts. Model it on `skills/mission/SKILL.md`'s structure at smaller scale.
- `plugins/workaholic/skills/strategy/scripts/create.sh` — scaffold `.workaholic/strategies/active/<slug>/strategy.md` (reuse `mission/scripts/slug.sh` for the slug rule — single source; do not copy it), stamp metadata via the gather skill, refresh OKF indexes, git-stage. Refuse an existing slug in either area. Emit `{created, slug, path}`.
- `plugins/workaholic/skills/strategy/scripts/list.sh` — JSON array `{slug, title, status, path, missions: [<mission-slugs>]}` across both areas; the `missions` rollup is computed by scanning mission files' `strategy:` field through the reader below, never stored.
- `plugins/workaholic/skills/strategy/scripts/read-strategy-relation.sh` — the **single reader** of a mission's `strategy:` frontmatter field (mirror `mission/scripts/read-relation.sh`: frontmatter-only, tolerates bare value and `[a]` list form, prints one slug per line, never fails). Convention is **one strategy per mission** (an execution plan executes one strategy); the reader tolerating list form keeps the parse future-proof without blessing plurality.
- `plugins/workaholic/skills/strategy/scripts/retire.sh` — flip `status` to `retired`, append the changelog line, move to `archive/`, refresh indexes, git-stage (the `close.sh` analogue; no worktree concerns).
- `plugins/workaholic/skills/strategy/scripts/lib/resolve.sh` — root/area resolution, modeled on `mission/scripts/lib/resolve.sh` (explicit root, absolute paths; no living migration needed — there is no legacy layout).
- `plugins/workaholic/skills/okf/scripts/refresh-index.sh` — add the `strategies/` area to the deterministic index regeneration (bundle root + per-area `index.md`), same as `missions/`.
- `scripts/build-plugins/build.mjs` — the mission skill is a build target and ticket `20260721025716` makes it reference strategy scripts; ensure the build closure carries `skills/strategy/` into `outputs/workflows` (verify with `verify.mjs` self-containment assertions) and run the argument-less full build.
- `scripts/test-workflow-scripts.mjs` — hermetic coverage (below).
- `CLAUDE.md`, `README.md`, `.workaholic/README.md` — document the new artifact and OKF `type: Strategy` in the same change.

## Implementation Steps

1. Write `skills/strategy/SKILL.md`: concept (long-lived direction, no completion conditions, missions as execution plans), schema, allowed locations, slug rule (delegates to `mission/scripts/slug.sh`), script contracts, and the terminology record (why "strategy"; rejected: *epic* — banned generic PM word here, *roadmap* — implies ordering/dates, *theme/initiative* — weaker commitment; "strategy" matches the user's own vocabulary and the execution-plan relation).
2. Implement `lib/resolve.sh`, `create.sh`, `list.sh`, `read-strategy-relation.sh`, `retire.sh` — POSIX `sh -eu`, JSON out, `set -eu`, no bash-isms; reuse `gather` scripts for metadata.
3. Extend `okf/scripts/refresh-index.sh` for the `strategies/` area.
4. Add hermetic tests in `scripts/test-workflow-scripts.mjs`: create → list (both areas) → relation reader (bare, list, absent, no-frontmatter) → retire (idempotent re-retire) → index refresh, in a throwaway repo.
5. Update `CLAUDE.md` (OKF runtime-bundle paragraph: add `Strategy` to the frontmatter-type list; project structure), `README.md`, `.workaholic/README.md`.
6. Run the argument-less `node scripts/build-plugins/build.mjs`; confirm `verify.mjs` and `validate-metadata.mjs` pass and `outputs/` diff is committed.

## Quality Gate

Interrogated at mission creation (2026-07-21); verification depth ruling: hermetic suite + in-session demo.

**Acceptance criteria**

- `create.sh` scaffolds a conformant `strategy.md` under `strategies/active/<slug>/` and refuses an existing slug in either area.
- `list.sh` reports both areas with computed (never stored) `missions` rollups; `read-strategy-relation.sh` handles bare/list/absent/malformed identically to `read-relation.sh`'s contract.
- `retire.sh` is idempotent and archive-moving; changelog lines are append-only.
- OKF: `strategy.md` carries non-empty `type: Strategy`; `refresh-index.sh` emits `strategies/` area indexes; bundle root still declares `okf_version`.
- Docs (`SKILL.md`, `CLAUDE.md`, `README.md`, `.workaholic/README.md`) updated in the same change; terminology record present.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green with the new strategy cases.
- `node scripts/build-plugins/build.mjs` then `verify.mjs` + `validate-metadata.mjs` green; `git status` shows no uncommitted `outputs/` drift after commit.
- POSIX lint conformance for every new script.

**Gate**

- Suite green, build/verify green, lint conforming, and an in-session demo: create a real strategy in this repository (the bootstrap strategy ticket `20260721025716` will link this mission to) and show `list.sh` output.

## Considerations

- Do not give strategies worktrees, tickets, assignees, acceptance checklists, or `drive_authorized` — a strategy is direction, not work; adding execution machinery here would collapse the granularity split this mission exists to create (`skills/strategy/SKILL.md`).
- The relation direction is mission→strategy (a field on `mission.md`), matching ticket→mission; nothing is stored on the strategy side, so archives never dangle (`skills/strategy/scripts/read-strategy-relation.sh`).
- `metadata.internal: true` is mandatory — the skill is script-bearing (CLAUDE.md Cross-Agent Skill Exposure).
- Keep `retire.sh` rare-path simple: no successor/carry semantics — a strategy that changed is *rewritten* (its changelog records the turn); only a strategy that is genuinely over is retired (`skills/strategy/SKILL.md`).

## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: The build closure is automatic — because `computeClosure` in `build.mjs` follows `${SCRIPT_DIR}/../../<x>/scripts/` cross-references, the strategy skill needs no manual entry in `build.mjs`. It will be pulled into `outputs/workflows` the moment ticket 20260721025716 makes the mission skill reference `strategy/scripts/read-strategy-relation.sh`. No build.mjs edit was required in this ticket.
  **Context**: `scripts/build-plugins/build.mjs` `computeClosure` — a new script-bearing skill becomes cross-agent-shipped purely by being referenced from a built skill; the closure is a set keyed on the reference patterns.
- **Insight**: `retire.sh` reuses `mission/scripts/append-changelog.sh` by passing the full strategy.md path, which the mission resolver's `[ -f "$arg" ]` fast-path returns as-is. This keeps the changelog format and idempotency rule in one writer across both artifacts rather than forking a strategy-specific appender.
  **Context**: `skills/strategy/scripts/retire.sh` — the cross-skill dependency is intentional and mirrors the slug.sh reuse in create.sh.
- **Insight**: The real bootstrap strategy `agent-orchestrated-development` now exists in this repo; ticket 20260721025716 links this mission to it by stamping `strategy:` on mission.md (create.sh will refuse to recreate it, so 025716 only stamps).
  **Context**: `.workaholic/strategies/active/agent-orchestrated-development/strategy.md`.
