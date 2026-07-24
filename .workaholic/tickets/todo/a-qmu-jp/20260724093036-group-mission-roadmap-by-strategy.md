---
created_at: 2026-07-24T09:30:36+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain]
effort:
commit_hash:
category:
depends_on:
mission:
---

# Group the bare /mission roadmap by strategy

## Overview

The bare `/mission` planning session (Step 1 of `commands/mission.md`) renders a flat, slug-sorted roadmap and never says which strategy each mission executes — the strategy layer only appears at Step 4's gap survey. Surface the mission→strategy relation in `mission/scripts/list.sh` output as a new `strategy` field (read through the single reader `strategy/scripts/read-strategy-relation.sh`), and restructure the Step 1 rendering to group missions **by strategy**: one block per strategy (title as the group heading), with an **"unlinked"** bucket for missions whose `strategy:` is empty. The mine/unassigned full-treatment vs others one-line distinction is kept *within* each group.

Developer decision (2026-07-24, this session): the developer explicitly requested that the roadmap show missions grouped by strategy. Moderation found no duplicate; the related archived tickets (`20260721161212-developer-centric-bare-mission.md`, `20260722081407-strategy-gap-discussion.md`) built the surfaces this extends.

## Policies

The standard engineering policies that govern this ticket. The implementing session MUST read each linked policy hard copy before writing code.

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout (applies to all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — style conventions; touched scripts stay POSIX `#!/bin/sh -eu` per `rules/shell.md` (machine-checked by posix-lint)
- `workaholic:implementation` / `policies/domain-layer-separation.md` — the mission→strategy relation is read ONLY through `read-strategy-relation.sh`; `list.sh` must call it, never parse `strategy:` frontmatter inline
- `workaholic:implementation` / `policies/objective-documentation.md` — `commands/mission.md` Step 1 and `mission/SKILL.md`'s `list.sh` description must be rewritten to the new truth in the same change

## Key Files

- `plugins/workaholic/skills/mission/scripts/list.sh` - add a `strategy` field per entry (first slug from `read-strategy-relation.sh`, `""` when unlinked); all other fields unchanged so existing consumers (`catch/scan-window.sh`, the replan judge) parse their subset unaffected
- `plugins/workaholic/skills/strategy/scripts/read-strategy-relation.sh` - the single reader to call; mirror `monitor/scripts/preflight.sh` line ~118 (`read-strategy-relation.sh "$f" | head -n 1`)
- `plugins/workaholic/commands/mission.md` - Step 1 prose: group the full-treatment tier by the new `strategy` field, strategy title as heading (titles from `strategy/scripts/list.sh`), plus an "unlinked" bucket; keep the mine/unassigned vs others tiering inside each group
- `plugins/workaholic/skills/mission/SKILL.md` - `list.sh` output documentation gains the `strategy` field
- `scripts/test-workflow-scripts.mjs` - "bare-list partition" block (~lines 794-846): fixtures and assertions for the new field
- `scripts/build-plugins/build.mjs` + `scripts/build-plugins/script-ref-patterns.mjs` - the new cross-skill call must use the `${SCRIPT_DIR}/../../strategy/scripts/` form so `strategy` enters the built mission skill's closure

## Related History

The strategy layer and the developer-centric bare `/mission` view both shipped in v1.0.99; the relation and its single reader already exist, so this is additive.

- [20260721161212-developer-centric-bare-mission.md](.workaholic/tickets/archive/work-20260721-153431/20260721161212-developer-centric-bare-mission.md) - built the current two-tier bare /mission view and list.sh's `relation` partition (the rendering this restructures)
- [20260721025716-link-missions-to-strategies-at-creation.md](.workaholic/tickets/archive/work-20260721-025656/20260721025716-link-missions-to-strategies-at-creation.md) - established the `strategy:` relation and `read-strategy-relation.sh` (the reader this consumes)
- [20260722081407-strategy-gap-discussion.md](.workaholic/tickets/archive/work-20260721-153431/20260722081407-strategy-gap-discussion.md) - added the `active_missions` rollup; shows bare /mission already reasons per-strategy at Step 4

## Implementation Steps

1. In `mission/scripts/list.sh`, resolve each mission's strategy via `sh "${SCRIPT_DIR}/../../strategy/scripts/read-strategy-relation.sh" "$f" | head -n 1` (exact `SCRIPT_CROSS_REF` form) and emit it as `"strategy": "<slug>"` (`""` when unlinked) in each entry's JSON. Update the script's header comment.
2. Rewrite `commands/mission.md` Step 1: read `strategy/scripts/list.sh` once for strategy titles, group the roadmap by the `strategy` field — per-strategy blocks (strategy title + slug as heading) with the existing full-treatment/one-line tiers inside, then an "unlinked" bucket last. An unlinked mission is also a visible signal for the Step 2 replan loop (the replan flow already stamps missing strategy links).
3. Update `mission/SKILL.md`'s `list.sh` output description (additive field, compute-don't-store unchanged).
4. Extend `scripts/test-workflow-scripts.mjs`: fixture missions with a linked strategy and without; assert the `strategy` field value and `""` for unlinked.
5. Rebuild `node scripts/build-plugins/build.mjs` (the strategy scripts join the built mission skill's closure) and run `node scripts/build-plugins/verify.mjs`.

## Quality Gate

Decided: single ticket for the grouping change, with the ownership relocation split into a dependent follow-up ticket — the grouping is additive and independently shippable; the ownership move rewrites the model underneath and must not block this (developer may override at /drive).
Decided: hermetic suite only (`node scripts/test-workflow-scripts.mjs`) — the change is script/prose-internal with no runtime service surface; a live run proves nothing extra (developer may override at /drive).
Decided: `strategy` is emitted as the FIRST slug only (mirroring `preflight.sh`), since the mission→strategy relation is single-valued by design (developer may override at /drive).

**Acceptance criteria** — the checkable conditions that must hold:

- `mission/scripts/list.sh` output entries carry `strategy` (linked slug, or `""` when the mission has no `strategy:` value); all pre-existing fields unchanged.
- The strategy value is obtained via `read-strategy-relation.sh` using the `${SCRIPT_DIR}/../../strategy/scripts/` cross-ref form — no inline `strategy:` grep in `list.sh`.
- `commands/mission.md` Step 1 renders grouped-by-strategy with an "unlinked" bucket, and the mine/unassigned vs others tiering survives within groups; no grouping logic beyond reading computed fields lives in the prose.
- `mission/SKILL.md` documents the new field.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` is green, including new assertions for the `strategy` field (linked and unlinked fixtures).
- `bash plugins/workaholic/hooks/posix-lint.sh` (or the suite's lint pass) passes on the touched script.
- `node scripts/build-plugins/build.mjs` then `node scripts/build-plugins/verify.mjs` pass with a clean `git status` on `outputs/` afterwards committed (Outputs Freshness parity).

**Gate** — what must pass before approval:

- Suite green, posix-lint conforming, outputs/ rebuilt and fresh, and the docs listed above updated in the same commit.

## Considerations

- Additive-only on `list.sh`: existing consumers parse a subset (`catch/scripts/scan-window.sh` line ~233, the replan judge) and must remain unaffected — do not rename or reorder existing fields (`plugins/workaholic/skills/catch/scripts/scan-window.sh`).
- The cross-skill call must be the build-detectable `${SCRIPT_DIR}/../../strategy/scripts/` form, or `outputs/workflows` ships a broken mission skill (`scripts/build-plugins/script-ref-patterns.mjs`).
- Grouping is computed, never asked: no new AskUserQuestion is introduced by the grouped rendering (`plugins/workaholic/rules/interaction.md`).
- Follow-up ticket `20260724093037-move-ownership-to-strategy-assignees.md` re-keys the `relation` partition onto strategy-level ownership; keep this change minimal so that ticket's diff stays reviewable.
