---
created_at: 2026-07-28T18:32:02+09:00
author: a@qmu.jp
type: refactoring
layer: [Domain]
effort: 2h
commit_hash:
category: Changed
depends_on:
mission: loop-engineering-foundation
---

# Carry mission ownership on the mission's assignees

## Overview

Move mission ownership back onto the mission itself, as a **plural** `assignees` list, ahead of the strategy layer's retirement (dependent ticket `20260728183203`). Decision B4 of `docs/loop-engineering-workflow.md`: in the team + AI-proposal model, the mission's approver becomes its default owner, an unassigned mission is team-owned and claimable, and ownership must survive without the strategy layer.

Ownership history, so this is not read as churn: it lived on the mission (`assignee`, singular) → moved to the strategy's `assignees` (2026-07-24, unmerged branch `work-20260724-092537`) → returns to the mission here, plural, because the layer above it is being retired. The single-oracle design (`mission-owners.sh`) is what makes this move cheap: every consumer reads through it, so only the oracle's resolution order changes.

Resolution order after this ticket:

1. the mission's own `assignees` (non-empty wins);
2. the strategy's `assignees` (transition fallback — removed by `20260728183203`);
3. the mission's legacy singular `assignee`.

**Reconcile-at-drive-time note:** this worktree is cut from `main`, where `mission-owners.sh` and the strategy-side `assignees` may not yet exist (they ride `work-20260724-092537`). Land on whatever state the catch-up-with-main produces: if the oracle exists, reorder it; if not, create it with the order above and point every consumer (mission-lens, `/monitor` scope, `summary.sh`, `list.sh` `relation`, `validate-mission.sh` owner floor, `ship` concern lane) at it.

## Policies

The standard engineering policies that govern this ticket. Read each linked hard copy before writing code; keep every change defensible against its Goal, Responsibility, and Practices.

- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `#!/bin/sh -eu`, no bash (applies to all code work)
- `workaholic:planning` / `policies/modeling-centric-design.md` — ownership is a property of the mission in the new model; state the model change in the SKILL.md before the scripts
- `workaholic:design` / `policies/history-structures.md` — record the ownership move as a dated redefinition record in the mission SKILL.md, appended to the existing ownership section's history, never rewriting it away
- `workaholic:implementation` / `policies/objective-documentation.md` — the resolution order is documented as a verifiable list; every consumer named

## Key Files

- `plugins/workaholic/skills/mission/scripts/mission-owners.sh` — the single ownership oracle: put the mission's own `assignees` first in the resolution order (create the script with this order if the merged base lacks it).
- `plugins/workaholic/skills/mission/scripts/create.sh` — scaffold `assignees: [<creator email>]` (creator-seeded — the interactive creator is the approver; the phase-2 proposal batch will scaffold it empty for draft missions).
- `plugins/workaholic/skills/mission/SKILL.md` — schema (`assignees` list documented; `assignee` demoted to legacy fallback), Ownership section rewritten: claiming a mission = adding yourself to *that mission's* `assignees` (a one-line, mission-local edit — no longer joining a strategy and inheriting its other missions).
- `plugins/workaholic/hooks/validate-mission.sh` — the authorized-owner floor keeps reading `mission-owners.sh`; no check may grep `assignees` directly.
- Consumers (verify, do not fork): `hooks/mission-lens.sh`, `skills/mission/scripts/summary.sh`, `skills/mission/scripts/list.sh`, `/monitor` scope (monitor skill), `ship`'s concern-lane owner — all must still read through the oracle.
- `scripts/test-workflow-scripts.mjs` — precedence tests.
- `CLAUDE.md`, `README.md` — ownership paragraphs updated in the same change.

## Implementation Steps

1. Reconcile with main first (see the note above); locate or create `mission-owners.sh`.
2. Implement the three-step resolution order; tolerate `assignees: [a, b]` and bare `assignees: a` forms, one owner per line out, empty output = unowned.
3. Seed `assignees` with the creator in `create.sh`; keep the singular `assignee` key emitted but empty (legacy readers).
4. Rewrite the SKILL.md Ownership section with the dated redefinition record (returned to the mission, 2026-07-28, reason: strategy retirement + team model; provenance: this mission).
5. Confirm every consumer reads through the oracle (grep for direct `assignee` parsing outside it; fix any).
6. Hermetic tests: mission `assignees` present → wins; empty + strategy assignees → strategy (until 183203); both empty + legacy `assignee` → legacy; all empty → unowned.
7. Docs; argument-less `node scripts/build-plugins/build.mjs` (the mission skill is built into `outputs/workflows`) and commit the regenerated artifacts.

## Quality Gate

Interrogated at mission creation (2026-07-28, decision record `docs/loop-engineering-workflow.md`); verification depth ruling: hermetic suite + consumer smoke, per repo precedent.

**Acceptance criteria**

- `mission-owners.sh` resolves in the documented order; empty output means unowned/claimable; no consumer parses ownership frontmatter directly.
- New missions scaffold creator-seeded plural `assignees`; `validate-mission.sh`'s authorized floor passes a mission owned via its own `assignees` with no strategy link involved.
- The mission lens, bare `/mission`, `/monitor` scope, `summary.sh`, and `ship`'s concern lane behave exactly as before for owned missions.
- The redefinition record is in the SKILL.md; docs updated in the same change.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green with the precedence cases.
- `node scripts/build-plugins/build.mjs` then `verify.mjs` + `validate-metadata.mjs` green; regenerated `outputs/` committed.
- POSIX lint conformance for touched scripts.

**Gate**

- Suite green, build/verify green, and an in-session demo: this mission's own `mission.md` gains `assignees: [a@qmu.jp]` and `mission-owners.sh` resolves it without consulting any strategy.

## Considerations

- Keep the strategy-hop fallback in this ticket — removing it belongs to `20260728183203`; this ticket must leave a tree where *both* ownership models still resolve (transition safety on whatever main state it lands on).
- Do not touch `.worktrees/<slug>` keying, `/drive`'s multi-mission commitment, or any placement rule — data moves, placement stays singular (CLAUDE.md runtime-OKF section).
- The phase-2 proposal batch depends on "unassigned = claimable/team-owned" surviving exactly as `summary.sh` states it today; do not tighten that gate here.

