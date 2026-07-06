---
created_at: 2026-07-06T20:30:44+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain, Config]
effort:
commit_hash:
category:
depends_on:
---

# Introduce the `mission` artifact type, skill, and `/mission` command (foundation)

## Overview

Add a new first-class knowledge artifact to workaholic: a **mission** — an
information-rich, long-lived goal that spans many tickets, drives, reports, and
PRs, akin to an epic or milestone but with a durable narrative and a machine-readable
web of relations. This is the **foundation ticket** of a three-ticket split; it
establishes the artifact, its home in the OKF bundle, the authoring surface, and the
documentation. Linkage from other artifacts (ticket 2) and progress/changelog
automation (ticket 3) build on top of it.

A mission is a **new, distinct artifact** — it does **not** extend or replace `trips/`
(trips remain short design/build sessions). Each mission lives at:

```
.workaholic/missions/<slug>/mission.md
.workaholic/missions/index.md          # regenerated, one entry per mission
```

`mission.md` carries `type: Mission` frontmatter (OKF conformance floor) and a body
with three parts:

1. **Goal / Scope** — the information-rich "why" (business grounding, definition of
   done, out-of-scope notes).
2. **Acceptance criteria** — an explicit checklist; each item names the ticket/story
   expected to satisfy it. Progress toward achievement is `checked ÷ total` (objective,
   not a hand-set percentage). Ticket 3 flips items as related work archives/ships; this
   ticket only defines the checklist convention and computes progress from whatever is
   checked.
3. **Changelog** — a human-readable, append-only timeline of lines relating the mission's
   tickets and reports over time (the "stuck changelog": where work stalled, deferred,
   resumed, or completed). This ticket defines the section and format; ticket 3 appends to
   it from the workflows.

Authoring is a **thin `/mission` command backed by a comprehensive `mission` skill**,
consistent with the rest of workaholic (thin commands, comprehensive skills):

- `/mission "<title>"` — create a new mission (writes `missions/<slug>/mission.md`,
  refreshes the index).
- `/mission` — show existing missions with their computed progress (`checked/total`)
  and recent changelog lines.

## Policies

The standard engineering policies — synced from the corporate site (qmu.co.jp) into the
`workaholic` policy skills — that govern this ticket. The implementing session **MUST**
read each linked policy hard copy before writing code and keep every change defensible
against that policy's Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — the new skill,
  command, scripts, and `.workaholic/missions/` area must follow the conventional layout
  (skill under `skills/mission/`, scripts under `skills/mission/scripts/`, command under
  `commands/mission.md`).
- `workaholic:implementation` / `policies/coding-standards.md` — the JS build change and
  the skill's shell all follow house style.
- `workaholic:implementation` / `policies/command-scripts.md` — all multi-step/conditional
  shell lives in bundled POSIX `#!/bin/sh -eu` scripts referenced via `${CLAUDE_PLUGIN_ROOT}`,
  never inline in the command/skill markdown (`rules/shell.md`).
- `workaholic:implementation` / `policies/objective-documentation.md` — the acceptance
  checklist and progress must be verifiable statements computed from state, not vibes;
  the mission schema documents each field's meaning unambiguously.
- `workaholic:design` / `policies/history-structures.md` — the changelog body is an
  append-only history structure; adopt its conventions for how historical events are
  recorded and ordered.
- `workaholic:planning` / `policies/terminology.md` — "mission" is a new domain term;
  define it once, consistently, and distinguish it explicitly from trip / epic / milestone
  so the vocabulary stays coherent across docs and skills.
- `workaholic:operation` / `policies/ci-cd.md` — the `Outputs Freshness` workflow rebuilds
  and fails on any `outputs/` diff; a cross-agent skill addition must leave a rebuilt tree
  clean.

## Key Files

- `plugins/workaholic/skills/okf/SKILL.md` - documents the allowed `type` values and the
  index hierarchy; add `Mission` and the `missions/` area.
- `plugins/workaholic/skills/okf/scripts/refresh-index.sh` - regenerates the bundle
  hierarchy; add `missions` to the area loops and give it per-subdir handling analogous to
  `trips` (one `missions/index.md` entry per mission linking its `mission.md`), plus the
  root-`index.md` description line.
- `plugins/workaholic/commands/` - new thin `commands/mission.md` (Claude-only).
- `plugins/workaholic/skills/` - new comprehensive `skills/mission/SKILL.md` +
  `skills/mission/scripts/` (create + progress-compute scripts).
- `scripts/build-plugins/build.mjs` - `DEFAULT_TARGETS` (line ~50) lists the workflow
  skills shipped self-contained to `outputs/workflows/`; add `mission` to ship it
  cross-agent (consistent with ticket/drive/report/ship).
- `.claude-plugin/marketplace.json`, `plugins/workaholic/.claude-plugin/plugin.json`,
  `plugins/workaholic/.codex-plugin/plugin.json` - version bump; command auto-discovery.
- `CLAUDE.md`, `README.md`, `.workaholic/README.md` - documentation to update in the same
  change (command table, OKF `type` list, project-structure skills list, `.workaholic/`
  area description).

## Related History

The `.workaholic/` tree is already an OKF bundle whose artifact types (`tickets`, `stories`,
`concerns`, `release-notes`, `trips`, …) each carry a non-empty `type` and are indexed by
`okf/refresh-index.sh`; `trips/<name>/` is the closest existing precedent for a per-slug
subdirectory artifact with its own long-form document, and its `refresh-index.sh` handling
is the template to mirror for `missions/`.

## Implementation Steps

1. **Define the mission schema.** Decide `mission.md` frontmatter: `type: Mission` (required,
   OKF floor), `title`, `slug`, `status` (`active | achieved | abandoned`), `created_at`,
   `author`. Reserve machine-readable member lists (`tickets: []`, `stories: []`,
   `concerns: []`) that ticket 2 populates — this ticket documents them but leaves them
   empty. Body sections: `## Goal`, `## Scope`, `## Acceptance`, `## Changelog`.
2. **Write `skills/mission/SKILL.md`** (comprehensive knowledge layer): the schema, the slug
   rule, the Allowed Location (`.workaholic/missions/<slug>/` only), the acceptance-checklist
   convention, the changelog line format, and the progress rule (`checked ÷ total`). Mark
   `metadata: { internal: true }` (script-bearing) per the cross-agent exposure rule.
3. **Add `skills/mission/scripts/create.sh`** — create a mission dir + `mission.md` from a
   title (slugify, stamp `created_at`/`author` from `gather`), then call
   `okf/refresh-index.sh`. POSIX `#!/bin/sh -eu`; git-stage. Add
   `skills/mission/scripts/progress.sh` — read a mission's `## Acceptance` list and emit
   `{checked, total}` JSON.
4. **Write `commands/mission.md`** (thin orchestration, ~50-100 lines): no-arg → list
   missions with progress; with a title → create. Include the standard `**Notice:**` /
   plugin-boundary header. Reach scripts only via `${CLAUDE_PLUGIN_ROOT}`.
5. **Wire `okf/refresh-index.sh`**: add `missions` to both area loops and add per-mission
   index handling mirroring `trips` (link each `mission.md`); add the root-`index.md`
   `* [missions](missions/index.md) - …` line.
6. **Ship cross-agent**: add `mission` to `DEFAULT_TARGETS` in `build.mjs`; run
   `node scripts/build-plugins/build.mjs` and commit the regenerated `outputs/workflows/`.
7. **Bump version** across the four version files per CLAUDE.md's Version Management.
8. **Update docs in the same change**: `CLAUDE.md` (command table, OKF per-file `type` list,
   project-structure skills list, `.workaholic/` area line), `README.md`, `.workaholic/README.md`.

## Quality Gate

How the outcome's quality is assured (Workflow Step 4b — full automated gate).

**Acceptance criteria** — the checkable conditions that must hold:

- `/mission "X"` creates `.workaholic/missions/<slug>/mission.md` with valid `type: Mission`
  frontmatter and the four body sections; `missions/index.md` gains a linking entry.
- `skills/mission/scripts/progress.sh` returns `{checked, total}` matching the `## Acceptance`
  checklist state of a fixture mission (e.g. `2/3`).
- `okf/refresh-index.sh` run twice on a tree containing a mission produces **no diff** on the
  second run (idempotent/deterministic).
- Re-running `node scripts/build-plugins/build.mjs` leaves `git diff outputs/` **and**
  `hooks/policy-index.md` empty (outputs freshness).
- Every touched doc (`CLAUDE.md`, `README.md`, `.workaholic/README.md`) states the new
  `/mission` command, the `Mission` type, and the `missions/` area truthfully.

**Verification method** — the commands/tests/probes that prove them:

- New hermetic assertions in `node scripts/test-workflow-scripts.mjs` exercising
  `create.sh` + `progress.sh` in a throwaway repo (create → assert file/frontmatter/index →
  progress JSON), following the existing smoke-test pattern.
- `node scripts/build-plugins/verify.mjs` — generated skills self-contained, index in sync.
- `node scripts/build-plugins/validate-metadata.mjs` — Codex manifests well-formed and
  version-aligned.
- `node scripts/build-plugins/build.mjs` then `git status --porcelain outputs/ hooks/policy-index.md` empty.
- `posix-lint` clean on the new shell scripts.

**Gate** — what must pass before approval:

- All four `node` checks green, the new smoke tests green, `refresh-index.sh` idempotent,
  posix-lint clean, outputs/ + policy-index.md unchanged after a rebuild, and the docs updated
  in the same commit.

## Considerations

- **Cross-agent shipping is a deliberate default, not a requirement** — adding `mission` to
  `DEFAULT_TARGETS` makes the skill self-contained for non-Claude agents (`scripts/build-plugins/build.mjs`).
  If the mission skill should stay Claude-only, omit it from `DEFAULT_TARGETS` instead — but
  then the `/mission` command (Claude-only) and skill must not reference each other in a way
  that assumes cross-agent presence. Confirm the intent at `/drive`.
- **`missions/index.md` is refresh-generated, not report-maintained** — unlike `stories/index.md`
  (whose per-story descriptions are richer than frontmatter), missions are indexed like `trips`
  from their frontmatter. Keep `okf/refresh-index.sh` the sole writer of that index
  (`plugins/workaholic/skills/okf/scripts/refresh-index.sh`).
- **Terminology drift risk** — "mission" must be clearly distinguished from `trip` and from a
  generic "epic/milestone" in every doc, or readers conflate them (`workaholic:planning` /
  `policies/terminology.md`).
- **`.workaholic/` root file rule** — only `README.md` and `index.md` may sit at the bundle
  root; `missions/` is a subdirectory, so this holds — verify the guard/docs still agree.
