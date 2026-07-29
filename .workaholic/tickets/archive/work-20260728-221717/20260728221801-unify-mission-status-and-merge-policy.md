---
created_at: 2026-07-28T22:18:01+09:00
author: a@qmu.jp
type: refactoring
layer: [Domain]
effort: 4h
commit_hash:
category: Changed
depends_on:
mission: loop-engineering-unified-drive
---

# Unify mission status and add merge policy

## Overview

Execute decisions I2 and G5 of `docs/loop-engineering-workflow.md`: the mission lifecycle becomes **one axis** — `status: draft | approved | achieved | abandoned | carried` — and the merge gate becomes a **per-artifact recorded choice**.

- **`drive_authorized` retires into `status: approved`.** "Approved" *is* what the stamp asserted: a human answered every judgment call about this exact plan. New missions never carry the key; legacy files migrate on the next mission-script touch (living migration in `lib/resolve.sh`: `status: active` + `drive_authorized: true` → `approved`; `status: active` without it → `draft`; the key line is dropped when rewritten). Area mapping is unchanged: `draft|approved` live in `active/`, the three end states in `archive/`.
- **The approval flip becomes executable.** `/mission approve <slug>` (a new argument route beside `close`) — and any replan of a draft that reaches drive-readiness — runs the standard interrogation to drive-ready, asks the **one genuinely human ruling** this flow owns (G5: may this mission's completed units merge automatically? `merge_policy: auto | review`), seeds `assignees` with the approver (B4: the approver is the default owner), and sets `status: approved`. The `validate-mission.sh` floor (owner + Experience + Acceptance) moves from the `drive_authorized: true` trigger to the `status: approved` trigger.
- **Tickets gain the same axis.** `/ticket` asks the auto-merge question at creation and records `merge_policy: auto | review` in ticket frontmatter (validated when present; **absent means `review`** — the conservative default, so no legacy ticket ever auto-merges by omission). Mission-emitted tickets inherit the mission's policy unless the interrogation rules otherwise.

## Policies

The standard engineering policies that govern this ticket. Read each linked hard copy before writing code; keep every change defensible against its Goal, Responsibility, and Practices.

- `workaholic:planning` / `policies/terminology.md` — "approved" replaces "drive-authorized" as the word: one concept, one word; record the redefinition in the mission SKILL
- `workaholic:planning` / `policies/modeling-centric-design.md` — the single-axis lifecycle is stated as a model (states + transitions + who flips) before the mechanics
- `workaholic:design` / `policies/history-structures.md` — the migration is a recorded transform; changelog lines record approvals (`mission approved — merge_policy: <p>`)
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `#!/bin/sh -eu` (applies to all code work)
- `workaholic:implementation` / `policies/objective-documentation.md` — every reader's keying is stated verifiably; the conservative absent-means-review default is written where the field is defined

## Key Files

- `plugins/workaholic/skills/mission/scripts/lib/resolve.sh` — extend the living migration: normalize legacy `status: active` (+/− `drive_authorized`) to `approved`/`draft`, dropping the retired key when the file is rewritten. Area keying (`achieved|abandoned|carried` → archive) is untouched.
- `plugins/workaholic/skills/mission/scripts/create.sh` — scaffold `status: draft` (an interactively created mission is a draft until its interrogation completes); no `drive_authorized` key. The interactive create flow ends by running the approval flip, so `/mission "<title>"` still hands over an approved, drive-ready mission.
- `plugins/workaholic/skills/mission/scripts/approve.sh` — NEW shared mutator: validate the floor is met, set `status: approved` + `merge_policy: <auto|review>`, seed `assignees` with the approver when empty, append the changelog line, refresh indexes, git-stage. The ONLY sanctioned approver (commands never hand-edit status).
- `plugins/workaholic/skills/mission/scripts/drive-authorized.sh` — authorized iff the resolved mission's `status` is `approved` (legacy `drive_authorized: true` honored pre-migration); same JSON contract so `/drive` callers are unchanged.
- `plugins/workaholic/skills/mission/scripts/{list.sh,summary.sh,close.sh,gate.sh}` + `hooks/mission-lens.sh` + `hooks/validate-mission.sh` — key on the status axis: `ready` = `approved` + plan; `ready_reason` gains `draft` → "awaiting approval" semantics (already present) and drops `not_authorized` in favor of it; `summary.sh`/lens treat `draft|approved` in the active area as the working set; the validator floor fires on `approved` (and on a legacy authorized stamp), never on drafts; `close.sh` flips from either in-flight state.
- `plugins/workaholic/commands/mission.md` — the `approve <slug>` route (Position Report → interrogation-to-ready → the `merge_policy` question via `AskUserQuestion` with the `[<project label>]` prefix → `approve.sh`); the create flow's step 4b becomes "run the approval flip"; the replan re-stamp language moves to approval.
- `plugins/workaholic/skills/create-ticket/SKILL.md` + `commands/ticket.md` + `hooks/validate-ticket.sh` — the ticket-side `merge_policy` field (optional; enum-validated when present; absent = `review`), the creation-time question, and the mission-inheritance rule for emitted sets.
- `plugins/workaholic/skills/propose/SKILL.md` + `scripts/scaffold-draft.sh` — already scaffold `status: draft`; update prose that says "approval (phase 3)" to name the now-real flow.
- `scripts/test-workflow-scripts.mjs` — migration cases (active+stamp → approved; active bare → draft), approve.sh floor/idempotency, drive-authorized.sh on both new and legacy shapes, validator trigger move, ticket merge_policy validation.
- `CLAUDE.md`, `README.md`, `.workaholic/README.md` — lifecycle and `/mission` rows updated in the same change. This mission's own file migrates as the live demo.

## Implementation Steps

1. State the lifecycle model in the mission SKILL (states, transitions, who flips: `/propose` mints drafts, `approve.sh` flips to approved, `close.sh` ends), with the redefinition record for `drive_authorized`.
2. Implement the living migration in `resolve.sh`; then `approve.sh`; then re-key `drive-authorized.sh` and the readers/validator/lens.
3. Rewire `create.sh` (draft scaffold) and `commands/mission.md` (approve route + create-flow flip + replan language).
4. Add the ticket-side `merge_policy` (schema, question, validation, inheritance).
5. Tests; run the migration live on this repo's missions (this mission itself becomes `approved`).
6. Docs sweep; argument-less `node scripts/build-plugins/build.mjs`; commit regenerated `outputs/`.

## Quality Gate

Interrogated at mission creation (2026-07-28, decision record I2/G5/B4); verification depth ruling: hermetic suite + live migration demo, per repo precedent.

**Acceptance criteria**

- New missions never carry `drive_authorized`; legacy files migrate on first touch (`approved`/`draft` per the stamp) and every reader — executors, validator, lens, list/summary — keys on the status axis with unchanged consumer contracts.
- `approve.sh` refuses a floor-failing mission, is idempotent, records `merge_policy`, seeds the approver, and is the only status-flipping path besides `close.sh`.
- `/ticket` records `merge_policy` when asked-and-answered; absent reads as `review`; the validator enforces the enum only when present.
- `grep -rn "drive_authorized" plugins/` returns only migration/legacy-tolerance code and the redefinition record.
- Suite/build/verify/metadata green; docs updated in the same change.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green with the new cases; build + verify + validate-metadata green; posix-lint conforming.

**Gate**

- Suite green, and a live demo: this repo's missions read back `approved` through `list.sh` after migration, and `drive-authorized.sh` answers identically for a new-shape and a legacy-shape mission.

## Considerations

- **This mission's own frontmatter** is stamped `drive_authorized: true` at kickoff (pre-change machinery); the migration must convert it mid-drive without invalidating the in-flight queue — land the migration and the `drive-authorized.sh` re-keying in the same commit.
- The pre-v1.0.106 installed plugin may still validate on `drive_authorized` in other sessions until refresh; the validator keeps honoring the legacy stamp as a trigger for exactly that transition window.
- Do not add an `active` synonym back: `approved` is the word (terminology policy); prose saying "active missions" means "the active area (drafts + approved)".
- `merge_policy` on missions is asked at **approval**, not creation (a draft has no human yet); on tickets at creation (the human is present). Never default a mission to `auto`.

