---
created_at: 2026-07-24T09:30:37+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain]
effort:
commit_hash:
category:
depends_on: [20260724093036-group-mission-roadmap-by-strategy.md]
mission:
---

# Move ownership to strategy-level assignees

## Overview

Relocate stored ownership from the mission to the strategy: `strategy.md` frontmatter gains an **`assignees`** list (the stored ownership), and a mission's ownership becomes **derived** through its `strategy:` link — `EMAIL ∈ strategy.assignees` membership replaces the current `assignee == EMAIL` equality everywhere the mission `assignee` field gates today. Missions stop carrying stored ownership.

**This deliberately amends a recorded design decision.** `strategy/scripts/create.sh` and `strategy/SKILL.md` currently state a strategy has "no assignee" because "adding execution machinery would collapse the granularity split." The developer explicitly ruled to reverse this (2026-07-24, this session): ownership (who the direction belongs to) moves up to the strategy; execution machinery (worktree, tickets, acceptance, `drive_authorized`) stays mission-local — the granularity split survives because ownership is not execution machinery. Every document asserting the old doctrine must be rewritten in this same change.

## Policies

The standard engineering policies that govern this ticket. The implementing session MUST read each linked policy hard copy before writing code.

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout (applies to all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — style conventions; all touched/new scripts stay POSIX `#!/bin/sh -eu` per `rules/shell.md`
- `workaholic:planning` / `policies/modeling-centric-design.md` — this is a hierarchy-model amendment (which element holds ownership); state the amended model in `strategy/SKILL.md`/`mission/SKILL.md` before the scripts instantiate it
- `workaholic:planning` / `policies/terminology.md` — `assignees` (plural, strategy: co-ownable direction) vs the retired singular mission `assignee` is a deliberate terminology decision; record it in the strategy skill's Terminology record
- `workaholic:implementation` / `policies/domain-layer-separation.md` — one single reader owns the new field's wire shape; one derivation helper owns the two-hop; consumers never grep `assignees:` inline
- `workaholic:implementation` / `policies/anti-corruption-structure.md` — the mission→strategy→assignees resolution lives in exactly one script, reused by every consumer
- `workaholic:implementation` / `policies/objective-documentation.md` — the "strategy has no assignee" claim appears in at least five places and every one must be rewritten to the truth in the same change

## Key Files

- `plugins/workaholic/skills/strategy/scripts/create.sh` - scaffold `assignees: [<creator email>]` into strategy.md frontmatter (self-seed, mirroring the old mission default); rewrite the header's no-assignee doctrine
- `plugins/workaholic/skills/strategy/scripts/read-assignees.sh` (NEW) - single reader of a strategy's `assignees` (tolerates bare scalar and `[a, b]` forms; frontmatter-only; never fails), mirroring `read-strategy-relation.sh`
- `plugins/workaholic/skills/mission/scripts/mission-owners.sh` (NEW) - the ownership oracle: given a mission.md, resolve `strategy:` via `read-strategy-relation.sh`, then the strategy's `assignees` via `read-assignees.sh` (search `strategies/active|archive`); when the derivation yields nothing, fall back to the mission's legacy `assignee` value. Prints one owner per line, empty = unassigned
- `plugins/workaholic/skills/mission/scripts/list.sh` - `relation` partition re-derived from `mission-owners.sh` membership (`mine` = EMAIL in owners; `unassigned` = empty owners; else `others`); the `assignee` JSON field is replaced by/aliased to the derived owners (document the wire change)
- `plugins/workaholic/skills/mission/scripts/summary.sh` - the canonical "not somebody else's" gate re-expressed as owners membership
- `plugins/workaholic/skills/mission/scripts/create.sh` - stop self-assigning `assignee:` on mission.md (ownership now arrives via the strategy link at step 3a); scaffold keeps no stored ownership
- `plugins/workaholic/hooks/mission-lens.sh` - inline `assignee:` grep replaced with a `mission-owners.sh` call via `${PLUGIN_ROOT}` (hook, not built)
- `plugins/workaholic/hooks/validate-mission.sh` - drop the `assignee:` key floor; the `drive_authorized: true` floor becomes: linked strategy resolvable AND that strategy has ≥1 assignee ("unattended work needs an owner" preserved, one level up); legacy mission `assignee` tolerated, never required
- `plugins/workaholic/skills/monitor/scripts/preflight.sh` - mine/unassigned pass re-keyed on `mission-owners.sh`; claim mechanic becomes "add the developer to the linked strategy's `assignees`"
- `plugins/workaholic/skills/monitor/SKILL.md` - Scope prose and the claim mechanic rewritten to strategy-level ownership
- `plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh` - the sixth consumer: concern lane `owner` derivation (embedded Python, ~lines 85-108) switches to the same two-hop with the same legacy fallback
- `plugins/workaholic/skills/strategy/SKILL.md`, `plugins/workaholic/skills/mission/SKILL.md`, `plugins/workaholic/skills/report/SKILL.md` (~line 261), `plugins/workaholic/commands/mission.md`, `plugins/workaholic/commands/monitor.md`, `plugins/workaholic/rules/workaholic.md`, `CLAUDE.md`, `README.md`, `.workaholic/README.md` - every assertion of mission-level assignment / strategy-has-no-assignee rewritten in the same change
- `scripts/test-workflow-scripts.mjs` - fixtures gain linked strategy.md files carrying `assignees`; relation/summary assertions rewritten to membership semantics; new coverage for `read-assignees.sh`, `mission-owners.sh` (derived, legacy-fallback, unassigned cases)

## Related History

The mission-level `assignee` gate and the strategy layer both shipped days ago; this inverts the ownership half of that model while keeping the relation and single-reader machinery it established.

- [20260721161212-developer-centric-bare-mission.md](.workaholic/tickets/archive/work-20260721-153431/20260721161212-developer-centric-bare-mission.md) - established the `relation` partition and assignee gate this re-keys
- [20260721025716-link-missions-to-strategies-at-creation.md](.workaholic/tickets/archive/work-20260721-025656/20260721025716-link-missions-to-strategies-at-creation.md) - the `strategy:` relation and single reader the derivation rides on

## Implementation Steps

1. State the amended model: rewrite `strategy/SKILL.md` (schema + doctrine + Terminology record entry explaining plural `assignees` and why the granularity split survives) and `mission/SKILL.md`'s Assignee section (ownership is derived; missions store none).
2. Add `read-assignees.sh` (strategy skill) and `mission-owners.sh` (mission skill; two-hop + legacy `assignee` fallback), both POSIX sh, both following the single-reader pattern and the `${SCRIPT_DIR}/../../<skill>/scripts/` cross-ref form.
3. Seed `assignees: [<creator>]` in `strategy/scripts/create.sh`; remove mission self-assignment from `mission/scripts/create.sh`.
4. Re-key the consumers, all through `mission-owners.sh`: mission `list.sh` (relation), `summary.sh`, `hooks/mission-lens.sh`, `monitor/scripts/preflight.sh` (+ claim = append to strategy `assignees`), `ship/extract-deferred-concerns.sh` (owner), `hooks/validate-mission.sh` (floor moves to "linked strategy has ≥1 assignee" when `drive_authorized: true`).
5. Migrate this repo's live data: add `assignees` to `.workaholic/strategies/` entries, seeded from their missions' current `assignee` values.
6. Update all remaining docs listed in Key Files; rewrite the strategy `create.sh` header comment.
7. Rewrite/extend `scripts/test-workflow-scripts.mjs` per Key Files; run posix-lint.
8. Rebuild `node scripts/build-plugins/build.mjs` (mission and ship closures now pull strategy scripts) and `node scripts/build-plugins/verify.mjs`.

## Quality Gate

Decided: the design reversal itself is developer-ruled (explicit instruction, 2026-07-24) — the old "no assignee on strategy" doctrine is amended, not violated; the amendment rationale is recorded in the strategy Terminology record (developer may override at /drive).
Decided: legacy fallback, not hard cutover — `mission-owners.sh` falls back to a mission's stored `assignee` when the strategy derivation yields nothing, because the plugin is installed in other repos whose existing missions carry only the old field; a hard cutover would silently orphan their ownership (developer may override at /drive).
Decided: `extract-deferred-concerns.sh` (the sixth, unnamed consumer) is in scope — leaving it on the old field would fork the ownership model (developer may override at /drive).
Decided: an unlinked mission (no `strategy:`) with no legacy `assignee` reads as `unassigned`/claimable — preserving the lens/monitor "not somebody else's" semantics (developer may override at /drive).
Decided: claiming a mission = adding the developer to its strategy's `assignees`, which claims that strategy's other missions too — the direct consequence of strategy-level ownership; recorded so the /monitor claim prose says it plainly (developer may override at /drive).
Decided: hermetic suite only — every touched surface is scripts/hooks/prose with existing hermetic coverage patterns; no live environment proves more (developer may override at /drive).

**Acceptance criteria** — the checkable conditions that must hold:

- `strategy/scripts/create.sh` scaffolds `assignees: [<creator email>]`; `read-assignees.sh` returns them (bare and list forms).
- `mission-owners.sh` returns: strategy-derived owners when present; the legacy mission `assignee` when the derivation is empty; nothing when both are absent.
- Mission `list.sh` `relation`, `summary.sh`, `mission-lens.sh`, `preflight.sh`, and `extract-deferred-concerns.sh` all resolve ownership only through `mission-owners.sh` (no inline `assignee:`/`assignees:` parsing outside the two readers).
- `validate-mission.sh` no longer requires a mission `assignee:` key; a `drive_authorized: true` mission whose linked strategy has zero assignees is rejected; a legacy authorized mission with a stored `assignee` and an assignee-less strategy still passes (fallback honored).
- `mission/scripts/create.sh` writes no `assignee:`; this repo's live `.workaholic/strategies/` files carry seeded `assignees`.
- No stale "strategy has no assignee" sentence remains anywhere in the repo (`grep -ri "no assignee" plugins/ CLAUDE.md README.md .workaholic/README.md` returns only the amended-history mentions, if any).

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` green, including new blocks for `read-assignees.sh`, `mission-owners.sh` (derived / fallback / unassigned), membership-based relation and summary, and the validate-mission floor.
- posix-lint conforming on every touched/new script.
- `node scripts/build-plugins/build.mjs` + `node scripts/build-plugins/verify.mjs` pass; `outputs/` diff committed (mission + ship closures).
- The grep in the last acceptance criterion, run at review time.

**Gate** — what must pass before approval:

- Suite green, posix-lint conforming, outputs/ rebuilt and fresh, live strategy files migrated, and every doc listed in Key Files updated in the same change.

## Considerations

- Depends on `20260724093036-group-mission-roadmap-by-strategy.md`: the `strategy` field and its cross-ref plumbing in `list.sh` land there; this ticket builds the membership partition on top (`plugins/workaholic/skills/mission/scripts/list.sh`).
- Multi-owner consequence: a strategy with `[a, b]` makes all its missions "mine" for both developers; concurrent `/monitor` runs on the same mission worktree become possible — the 1:1 mission↔worktree claim remains the collision backstop; say so in monitor SKILL.md Scope (`plugins/workaholic/skills/monitor/SKILL.md`).
- `list.sh`'s `assignee` JSON field is consumed by tests only today, but treat the wire change as breaking: grep all consumers before renaming (`scripts/test-workflow-scripts.mjs`).
- Hooks (`mission-lens.sh`, `validate-mission.sh`) have no outputs/ footprint — do not expect them in the rebuild; mission and ship skills DO rebuild (`scripts/build-plugins/build.mjs` DEFAULT_TARGETS).
- The strategy skill becomes part of two built closures; its scripts must stay self-containable (no `${CLAUDE_PLUGIN_ROOT}` inside scripts, `${SCRIPT_DIR}` relative refs only) (`scripts/build-plugins/script-ref-patterns.mjs`).
- `retire.sh` moves a strategy to `archive/` with its `assignees` intact; `mission-owners.sh` must search both `strategies/active/` and `strategies/archive/` so archived strategies never dangle ownership (`plugins/workaholic/skills/strategy/scripts/retire.sh`).
