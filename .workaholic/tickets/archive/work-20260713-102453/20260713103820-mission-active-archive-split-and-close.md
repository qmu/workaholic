---
created_at: 2026-07-13T10:38:20+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 2h
commit_hash: 100f859
category: Changed
depends_on:
mission:
---

# Split missions into active/ and archive/ areas with living migration and an end-mission mutator

## Overview

Reorganize the runtime missions tree from the flat `.workaholic/missions/<slug>/mission.md` into a working/archived split that mirrors the tickets tree: active missions live under `.workaholic/missions/active/<slug>/mission.md`, ended missions (status `achieved` or `abandoned`) under `.workaholic/missions/archive/<slug>/mission.md`. Three coupled pieces land together:

1. **Layout split + shared resolver** — one shared, POSIX-sh slug→path resolver replaces the path idiom currently triplicated across the mission scripts; it searches `active/` then `archive/`.
2. **Living migration** — the resolver also detects a legacy flat mission dir sitting directly under `.workaholic/missions/` and relocates it (`git mv`, preserving history) into the correct area by its `status` frontmatter. It runs at the top of every mission script, so any downstream repo that already adopted missions in the flat layout self-heals on the next touch — create, list, progress, changelog append, or acceptance tick. Idempotent (re-run is a no-op) and best-effort (never blocks the calling seam).
3. **End-mission mechanism** — today `status: active | achieved | abandoned` exists in the schema but nothing ever ends a mission. Add `mission/scripts/close.sh`: flips `status` to `achieved` or `abandoned`, appends a closing changelog line via `append-changelog.sh` (the single changelog writer), and `git mv`s the mission dir from `active/` to `archive/`. Extend `/mission` (`commands/mission.md`) with a close verb so `archive/` is reachable from day one.

Also fixes a pre-existing gap: `missions` is absent from both `hooks/workaholic-layout-allowlist.txt` and the `rules/workaholic.md` layout table even though `missions/` is a live, indexed directory.

## Policies

The standard engineering policies — synced from the corporate site (qmu.co.jp) into the `workaholic` policy skills — that govern this ticket. The implementing session **MUST** read each linked policy hard copy before writing code and keep every change defensible against that policy's Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — the whole point of the change: placement readable from structure; mirror the established tickets working-vs-archive shape instead of inventing a new convention
- `workaholic:implementation` / `policies/coding-standards.md` — applies to all code work; the new/changed scripts follow house shell style
- `workaholic:design` / `policies/history-structures.md` — ending a mission must preserve, not overwrite, the past: the archived mission keeps its append-only `## Changelog`, and `close.sh` records the transition as a dated changelog line before the move
- `workaholic:implementation` / `policies/objective-documentation.md` — every doc that describes the missions layout is updated in the same change; acceptance criteria below are phrased verifiably
- `workaholic:implementation` / `policies/command-scripts.md` — migration/close logic lives in bundled skill scripts reached via `${CLAUDE_PLUGIN_ROOT}`, never as inline shell in command/skill markdown

## Key Files

Mission scripts (all gain the shared resolver + living migration):

- `plugins/workaholic/skills/mission/scripts/create.sh` — writes `MISSION_DIR=.workaholic/missions/${SLUG}`; must write into `active/` and treat a slug already present in *either* area as existing
- `plugins/workaholic/skills/mission/scripts/list.sh` — `find $ROOT -maxdepth 1` over the flat root; must enumerate both areas (ended missions still appear, with their `status`)
- `plugins/workaholic/skills/mission/scripts/progress.sh` — bare-slug resolution to the flat path; switch to the shared resolver
- `plugins/workaholic/skills/mission/scripts/append-changelog.sh` — same flat resolution; switch to the shared resolver (fixing this transparently fixes the drive/report/ship seams, which pass bare slugs)
- `plugins/workaholic/skills/mission/scripts/tick-acceptance.sh` — same flat resolution; switch to the shared resolver
- `plugins/workaholic/skills/mission/scripts/close.sh` — **new**: `close.sh <slug> <achieved|abandoned>`; flips status, appends the closing changelog line, `git mv`s to `archive/`, idempotent JSON output
- `plugins/workaholic/skills/mission/SKILL.md` — Allowed Location block, scripts contract, status→area mapping, migration behavior, seam table

Direct dir-scanners (bypass the scripts; must become area-aware themselves):

- `plugins/workaholic/skills/okf/scripts/refresh-index.sh` — missions index block does `find .workaholic/missions -maxdepth 1`; must index the new hierarchy deterministically (same tree in, same bytes out)
- `plugins/workaholic/skills/catch/scripts/scan-window.sh` — window-events changelog walk does the same `maxdepth 1` find; must walk missions in both areas (its `list.sh` call is covered by the resolver work)
- `plugins/workaholic/commands/mission.md` — list mode reads changelog tails at the flat path; resolve area-aware (or read the path from `list.sh` output); add the close verb

Layout governance and docs (same-change lockstep):

- `plugins/workaholic/hooks/workaholic-layout-allowlist.txt` — add `missions` (pre-existing gap)
- `plugins/workaholic/rules/workaholic.md` — add the missing `missions/` row with `(active/, archive/)`, phrased like the tickets row
- `plugins/workaholic/skills/okf/SKILL.md`, `README.md` (line ~150: "file preserved" lifecycle text), `.workaholic/README.md`, `CLAUDE.md` — describe the split and the archive move
- `plugins/workaholic/skills/catch/SKILL.md` — light-touch note that archived missions render compactly/omitted (behavior already keys off `status`)

Build/test:

- `scripts/test-workflow-scripts.mjs` — add hermetic mission cases (currently no mission coverage; existing assertions that hardcode the flat path must move to the new layout)
- `outputs/workflows/` — generated bundle contains copies of every affected script/skill; full rebuild required

## Related History

The mission artifact and its flat layout were introduced as a three-ticket split in PR #77 and extended by PR #80's `/catch` integration; no prior work splits the tree or automates migration — the repo's recorded stance so far (concern #77) is hand-written targeted migration tickets, and this ticket deliberately introduces the first self-healing migration.

Past tickets that touched similar areas:

- [20260706203044-mission-artifact-type-and-command.md](.workaholic/tickets/archive/work-20260706-182705/20260706203044-mission-artifact-type-and-command.md) - Introduced the mission artifact, flat layout, `/mission` command, and `create.sh` (the structure this ticket reorganizes)
- [20260706203045-mission-frontmatter-linkage.md](.workaholic/tickets/archive/work-20260706-182705/20260706203045-mission-frontmatter-linkage.md) - Added the `mission: <slug>` relation; slug-based resolution must survive the split
- [20260706203046-mission-progress-and-changelog-automation.md](.workaholic/tickets/archive/work-20260706-182705/20260706203046-mission-progress-and-changelog-automation.md) - Added the shared mutators and drive/report/ship seams whose slug resolution this ticket centralizes
- [20260709023255-catch-scan-mission-join.md](.workaholic/tickets/archive/work-20260707-104047/20260709023255-catch-scan-mission-join.md) - `/catch` scanner reads missions via `list.sh` and a direct dir-walk (both affected)
- [20260709023256-catch-report-missions-section.md](.workaholic/tickets/archive/work-20260707-104047/20260709023256-catch-report-missions-section.md) - Catch report's active/ended rendering keys off `status` (unchanged, verify only)

## Implementation Steps

1. **Shared resolver** — add `plugins/workaholic/skills/mission/scripts/lib/resolve.sh` (or equivalent sourced helper, POSIX `sh -eu`): given a slug, return the mission.md path by checking `active/<slug>/` then `archive/<slug>/`. Before resolving, run the living migration: for each dir directly under `.workaholic/missions/` other than `active`/`archive` that contains a `mission.md`, read its `status` and `git mv` it to `active/` (status `active` or missing) or `archive/` (`achieved`/`abandoned`). Fall back to plain `mv` when `git mv` is unavailable (not a work tree). Idempotent; failures never propagate to the caller (best-effort, matching the seams' existing `|| true` guarantee).
2. **Rewire the five mission scripts** onto the resolver: `create.sh` writes to `active/<slug>/` and its exists-check covers both areas; `list.sh` enumerates `active/*` and `archive/*` (deterministic `LC_ALL=C` order, JSON shape unchanged — `status` already distinguishes ended missions); `progress.sh`, `append-changelog.sh`, `tick-acceptance.sh` resolve via the helper.
3. **`close.sh`** — new mutator `close.sh <slug-or-file> <achieved|abandoned>`: resolve the mission, flip `status:` frontmatter, call `append-changelog.sh` with a standard closing event (e.g. `mission achieved` / `mission abandoned`, artifact = `mission.md` — keeping `(event, artifact)` idempotency), `git mv` the dir into `archive/`, git-stage, emit JSON. Re-running on an already-archived mission is a no-op.
4. **Direct scanners** — update `okf/scripts/refresh-index.sh`'s missions block to index the hierarchy (missions grouped or listed across both areas; deterministic bytes) and `catch/scripts/scan-window.sh`'s changelog walk to find mission dirs in both areas.
5. **`/mission` command** — `commands/mission.md`: list-mode changelog-tail read becomes area-aware; add a close verb (`/mission close <slug>` → confirm achieved vs abandoned via AskUserQuestion, then run `close.sh`).
6. **Layout governance** — add `missions` to `hooks/workaholic-layout-allowlist.txt` and the `rules/workaholic.md` table in lockstep.
7. **Docs** — update `mission/SKILL.md` (Allowed Location, scripts, status→area mapping, migration), `okf/SKILL.md`, `README.md`, `.workaholic/README.md`, `CLAUDE.md`, `catch/SKILL.md` in the same commit.
8. **Tests** — extend `scripts/test-workflow-scripts.mjs` with hermetic throwaway-repo cases (see Quality Gate).
9. **Rebuild** — `node scripts/build-plugins/build.mjs` (full, argument-less), then `verify.mjs` and `validate-metadata.mjs`; commit the regenerated `outputs/`.

## Quality Gate

How the outcome's quality is assured, captured from the developer at ticket time. `/drive` surfaces this in its approval prompt and forwards it into the commit `Verify:` key.

**Acceptance criteria** — the checkable conditions that must hold:

- `create.sh` in a fresh repo writes `.workaholic/missions/active/<slug>/mission.md`; a second `create.sh` with the same slug fails with `"exists"` even after the mission is archived
- Given a legacy flat repo (`.workaholic/missions/<slug>/mission.md` with `status: active`, another with `status: achieved`), running **any** mission script relocates them to `active/<slug>/` and `archive/<slug>/` respectively; running it again changes nothing (`git status --porcelain` identical before/after the second run)
- `progress.sh`, `append-changelog.sh`, and `tick-acceptance.sh` resolve a bare slug in either area; `list.sh` output includes missions from both areas with correct `status`
- `close.sh <slug> achieved` flips `status`, appends exactly one closing changelog line (re-run appends none), and the dir ends at `archive/<slug>/`; the mission's pre-existing `## Changelog` lines survive the move byte-identical
- `okf refresh-index.sh` run twice on the new layout produces identical bytes (deterministic), and `missions/index.md` links every mission in both areas
- `missions` is present in `workaholic-layout-allowlist.txt`; `layout-doctor.sh` no longer flags `missions/` as undesignated

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` is green, including new hermetic mission cases covering: flat→split migration by status, migration idempotency, both-area slug resolution, both-area `list.sh`, `close.sh` move + changelog idempotency
- `node scripts/build-plugins/build.mjs` then `node scripts/build-plugins/verify.mjs` and `node scripts/build-plugins/validate-metadata.mjs` all pass with zero `outputs/` drift (`git status --porcelain outputs/` empty after rebuild)
- posix-lint passes on every new/changed script (all `#!/bin/sh -eu`, no bashisms)

**Gate** — what must pass before approval:

- The full suite above is green in-session: smoke tests (with the new mission cases), build + verify + validate-metadata with no generated-artifact drift, posix-lint clean

## Considerations

- **Departure from the recorded migration stance**: concern #77 (`.workaholic/concerns/77-existing-artifacts-are-not-backfilled-into.md`) records "forward-only; write a targeted migration ticket" and `layout-doctor.sh` deliberately reports without mutating. The living migration is a deliberate, developer-chosen departure — scope it strictly to mission dirs containing a `mission.md` directly under `.workaholic/missions/`, and document the rationale in `mission/SKILL.md`
- **Slug is the stable cross-artifact key**: the `mission:` relation on tickets/stories/concerns must keep resolving after a move — the area is never part of the key, only `<slug>` (`plugins/workaholic/skills/mission/scripts/`)
- **Seams stay untouched by design**: `drive/scripts/archive.sh`, `report/SKILL.md`, and `ship/extract-deferred-concerns.sh` pass bare slugs to the mutators and `git add` `.workaholic/missions/` recursively, so they need no edits — verify, don't modify (`plugins/workaholic/skills/drive/scripts/archive.sh` lines 63-72)
- **Best-effort contract**: seams wrap mutator calls in `|| true`; migration and close must never exit non-zero into a seam in a way that blocks archiving/shipping
- **create-ticket association scope**: Step 4c offers missions from `list.sh` for `mission:` frontmatter — consider offering only `status: active` (working-area) missions; note in `create-ticket/SKILL.md` if changed (`plugins/workaholic/skills/create-ticket/SKILL.md` line ~183)
- **This repo has no `.workaholic/missions/` yet** — the migration cannot be exercised against the local tree; the hermetic tests are the only proof, hence their place in the gate (`scripts/test-workflow-scripts.mjs`)
- **Generated-bundle footprint**: every affected script/skill is copied into `outputs/workflows/`; forgetting the rebuild fails the Outputs Freshness CI (`scripts/build-plugins/build.mjs`)
- **`missions/index.md` structure choice**: either one flat list annotated by area or per-area grouping — pick one, keep it deterministic, and document it in `okf/SKILL.md`

## Final Report

Development completed as planned. Per-area grouping was chosen for `missions/index.md` (`## active` / `## archive` sections, legacy flat dirs listed at the top level until migrated), and the create-ticket association scope consideration was implemented: `/ticket` now offers only `status: active` missions.

### Discovered Insights

- **Insight**: The self-containment checker (`verify.mjs`) treats any `${SCRIPT_DIR}/<path>.sh` occurrence in a script — including inside comments — as a reference resolved from that script's own directory.
  **Context**: A usage comment in `lib/resolve.sh` showing how callers source it (`${SCRIPT_DIR}/lib/resolve.sh`) failed the bundle verification six times, because from inside `lib/` the path resolves to `lib/lib/resolve.sh`. Doc comments in bundled scripts must avoid the literal `${SCRIPT_DIR}/` form for paths that are not real from that file's location.
- **Insight**: Every workflow seam reaches missions through bare slugs passed to the shared mutators, so centralizing slug→path resolution in one sourced helper made the drive/report/ship seams area-aware with zero edits to the seams themselves.
  **Context**: Confirms the "single writer" architecture pays off: only the two direct dir-scanners (`okf/refresh-index.sh`, `catch/scan-window.sh`) and the `/mission` command's tail-read needed their own updates.
- **Insight**: `/catch` is documented as read-only over missions, but its `list.sh` call now triggers the living migration — a tree mutation (file moves) without a content mutation.
  **Context**: The read-only contract was reworded to "mutates no mission content" in both catch and mission SKILL.md; anyone tightening that contract later must exempt the migration or exclude readers from it.
