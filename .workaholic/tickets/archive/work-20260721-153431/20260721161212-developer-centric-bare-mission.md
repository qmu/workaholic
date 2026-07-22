---
created_at: 2026-07-21T16:12:12+09:00
author: a@qmu.jp
type: enhancement
layer: [UX]
effort: 2h
commit_hash:
category: Changed
depends_on:
mission:
---

# Center bare `/mission` on the current developer; retire `summary`

## Overview

Bare `/mission` (no argument) today lists **every** mission uniformly — title, slug, status, progress, and a `## Changelog` tail narrated for each. For a developer checking "where are we and where are we heading", most of that output is somebody else's detail. Re-center the view on the caller: the missions that are **their business** (assigned to them, or unassigned/claimable — the same "not somebody else's" gate `summary.sh` and `mission-lens.sh` already share) get the **full treatment** (status, `checked/total`, next unchecked acceptance item, recent changelog movement, own-missions-first with unclaimed marked claimable); every other developer's mission collapses to a **bare one-line entry** (title, slug, status, `checked/total`) with no changelog narration. The whole roadmap stays visible — only the weighting shifts (no-dark-patterns: de-emphasize, never hide).

**Developer decision (recorded 2026-07-21): retire the `summary` subcommand.** Once bare `/mission` is developer-centric, `summary` would differ only by omitting others' missions entirely — a near-duplicate mode. One concept, one word: the bare command becomes the single habitual view, and the `summary` argument routing is removed from the command. Decided at ticket time; do not re-ask.

Decided here rather than asked later (decide-and-record): an **archived** mission collapses to the bare tier even when it is the caller's own — a closed mission has no next step, so full treatment is moot; active missions stay grouped before archived ones.

## Policies

- **Design / self-explanatory-ui** — the default view must surface the caller's most relevant slice first, mark an unclaimed mission as claimable (never as taken), and design the empty state ("no missions yet; `/mission \"<title>\"` starts one").
- **Design / no-dark-patterns** — others' missions are de-emphasized to one line, not hidden; the full team picture remains in the output.
- **Design / modeless-design & terminology** — `$ARGUMENT` stays content-routed; retiring `summary` removes a near-synonym mode (one concept, one word).
- **Implementation / observability** — progress stays computed (`progress.sh`/`next-acceptance.sh`) on demand; no stored counts.
- **Shell Script Principle** — the mine/unassigned/others partition is conditional logic and lives in a bundled script (enrich `list.sh`), never inline in `commands/mission.md`.
- **rules/interaction.md (decide-and-record)** — this is a read-only report; add no `AskUserQuestion`.

## Key Files

- `plugins/workaholic/commands/mission.md` — rewrite the "Without a title — list missions" section to the two-tier rendering; remove the `summary` branch from the mode routing (and its match-order note); command file is Claude-only (not built).
- `plugins/workaholic/skills/mission/scripts/list.sh` — enrich **additively** (existing keys/order preserved: `catch/scan-window.sh` greps a subset): add `relation` (`mine|unassigned|others`, from `git config user.email` + the shared "assignee empty or mine" gate) and `next` (via `next-acceptance.sh`). Must **not** early-exit on an empty git email (unlike `summary.sh`): empty email ⇒ nothing is `mine`, unassigned stays `unassigned`, the rest `others`. POSIX `#!/bin/sh -eu`.
- `plugins/workaholic/skills/mission/scripts/summary.sh` — the `summary` command mode is retired, but the **script has a second consumer**: the monitor skill's "Scope: whose missions" names the `summary.sh` gate as its scope definition. Either keep the script for that role (and say so in its header) or repoint monitor's prose to the gate as expressed in `list.sh`'s `relation` — do not leave a dangling reference.
- `plugins/workaholic/skills/mission/SKILL.md` — document the partition and new `list.sh` fields in the Assignee / read-only-consumers prose; remove the `summary` mode description. Built skill ⇒ rebuild.
- Docs in the same change: `CLAUDE.md` (`/mission` command-table row; the mission-lens section's "summary keeps the lower bar" contrast — that divergence disappears with `summary`, so rewrite the paragraph to contrast the lens with the bare list's tiering), `README.md` (`/mission` row mentions `/mission summary`).
- `outputs/workflows/` — regenerate with argument-less `node scripts/build-plugins/build.mjs` (list.sh and SKILL.md are built); commit the diff.

## Related History

- `20260715215008-summary-unassigned-missions.md` — established the shared "not somebody else's" gate and the mine-first/unclaimed-after ordering this ticket reuses as a partition.
- `20260714000528-command-summary-mode.md` — introduced the `summary` mode this ticket retires.
- `20260715163311-mission-lens-says-less.md` — precedent for saying less about what is not actionable (the lens's "summarize on change" tiering is the in-repo model for full-vs-compact).

## Implementation Steps

1. Enrich `list.sh` with `relation` and `next` (additive; empty-email degradation; reuse `next-acceptance.sh`).
2. Rewrite `commands/mission.md` "Without a title" to render two tiers from `relation` (full: mine + unassigned **active** missions, mine first, unclaimed marked claimable, changelog tail read from each entry's `path`; bare line: others and all archived), and delete the `summary` routing (empty argument and `summary` both… no — `summary` becomes an unrecognized argument that falls through to the existing reference-judgment, which will find no mission named "summary" and treat it as a title; add a one-line guard: the literal word `summary` gets a short deprecation note pointing at bare `/mission` instead of becoming a mission title).
3. Resolve `summary.sh`'s remaining role (monitor scope reference) per Key Files.
4. Update SKILL.md, CLAUDE.md, README.md in the same change; rebuild `outputs/` and run the verification suite.

## Quality Gate

Pre-answered at ticket time; `/drive` verifies against these:

- `node scripts/test-workflow-scripts.mjs` green, **with new hermetic fixtures** pinning: (a) `list.sh`'s enriched JSON — `relation` computed correctly for mine/unassigned/others against a configured `git config user.email`, `next` present for a mission with unchecked acceptance; (b) existing keys unchanged (additive-only, `scan-window.sh` compatibility); (c) empty-email degradation (nothing `mine`, no early exit).
- `node scripts/build-plugins/build.mjs` then `git status --porcelain outputs/` empty at commit; `verify.mjs` and `validate-metadata.mjs` pass.
- The literal argument `summary` does not create a mission and does not crash — it lands on the deprecation note (manual check recorded in the Final Report).
- Doc truthfulness: no remaining reference to a live `summary` mode in `commands/mission.md`, `SKILL.md`, `CLAUDE.md`, `README.md` (grep recorded in the Final Report); the monitor scope reference resolves.
- No `AskUserQuestion` added anywhere in the bare-`/mission` path.

## Considerations

- The assignee gate stays a small shared rule inlined per reader (repo precedent accepts the duplication); factoring a shared lib is optional, not required.
- The user intent behind this change: make `/mission` the habitual team check of current position and direction — output should read in seconds, with the caller's own work first.

## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: `summary.sh` could not simply be deleted with its command mode — the monitor skill's Scope section and the mission lens both cite it as the canonical statement of the "not somebody else's" gate. Retiring a mode and retiring its script are separate decisions; the script survived as the gate's single home.
  **Context**: When a command mode is folded away, grep for *script* consumers before removing the engine — this repo's single-source pattern means a script often outlives the surface that introduced it.
- **Insight**: The lens's compact pointer (`/mission summary for the full list`) was pinned by a prose sentinel in the test suite; the retirement required updating hook text and sentinel in the same change — exactly the deliberate-sentinel-update practice the "monitor's contract lives in prose" concern prescribes.
  **Context**: Sentinel tests make prose contracts breakable on purpose; a red sentinel on a rename is the mechanism working, not test noise.
