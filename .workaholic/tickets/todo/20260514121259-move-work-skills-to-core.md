---
created_at: 2026-05-14T12:12:59+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
depends_on:
---

# Move work skills to core (check-deps, create-ticket, discover, drive, report, trip-protocol)

## Overview

Relocate every skill currently under `plugins/work/skills/` into `plugins/core/skills/`. The intent is to redraw the core/work boundary so that `core` becomes the home of reusable, agentic skills (knowledge layer reusable across codebases) while `work` retains only code-dependent configuration (agents, commands, hooks, rules). This ticket performs the file moves and rewrites every `${CLAUDE_PLUGIN_ROOT}` path and `skills:` frontmatter reference affected by the move. The plugin manifest dependency direction stays `work -> core` and is unchanged in this ticket; cross-plugin references from work agents into the relocated skills become `core:<skill>` and `${CLAUDE_PLUGIN_ROOT}/../core/skills/<skill>/...`. The companion ticket `20260514121300-move-report-ship-commands-to-work.md` moves `/report` and `/ship` in the opposite direction and updates `CLAUDE.md` and `plugin.json`; the two are mechanically independent and can be implemented in either order, but both must land before the new boundary is coherent.

## Key Files

### Skills to move (each entire directory, including `scripts/` subdirectory)

- `plugins/work/skills/check-deps/` -> `plugins/core/skills/check-deps/` - dependency probe used by `/ticket`, `/drive`, `/trip`
- `plugins/work/skills/create-ticket/` -> `plugins/core/skills/create-ticket/` - ticket-format guidelines preloaded by `ticket-organizer`
- `plugins/work/skills/discover/` -> `plugins/core/skills/discover/` - history/source/policy discovery guidelines preloaded by `discoverer`
- `plugins/work/skills/drive/` -> `plugins/core/skills/drive/` - workflow, approval, final report, archive, frontmatter update used by `/drive`
- `plugins/work/skills/report/` -> `plugins/core/skills/report/` - story writing, PR creation, release readiness used by `story-writer`, `pr-creator`, `release-readiness`
- `plugins/work/skills/trip-protocol/` -> `plugins/core/skills/trip-protocol/` - trip phase gate / artifact conventions used by `/trip`, `planner`, `architect`, `constructor`

### Skill-internal path rewrites (same-plugin and cross-plugin references flip)

- `plugins/work/skills/create-ticket/SKILL.md` line 18 - currently `${CLAUDE_PLUGIN_ROOT}/../core/skills/gather-ticket-metadata/...` (cross-plugin); after move becomes `${CLAUDE_PLUGIN_ROOT}/skills/gather-ticket-metadata/...` (same-plugin in core)
- `plugins/work/skills/drive/SKILL.md` line 227 - currently `${CLAUDE_PLUGIN_ROOT}/../core/skills/commit/scripts/commit.sh` (cross-plugin); after move becomes `${CLAUDE_PLUGIN_ROOT}/skills/commit/scripts/commit.sh` (same-plugin)
- `plugins/work/skills/trip-protocol/SKILL.md` lines 45-46, 133 - currently mixes core cross-plugin (`${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/`, `${CLAUDE_PLUGIN_ROOT}/../core/skills/system-safety/scripts/detect.sh`) and same-plugin (`${CLAUDE_PLUGIN_ROOT}/skills/trip-protocol/scripts/`); after move BOTH become same-plugin (`${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/`, `${CLAUDE_PLUGIN_ROOT}/skills/system-safety/scripts/detect.sh`, `${CLAUDE_PLUGIN_ROOT}/skills/trip-protocol/scripts/`). The Script base paths table in trip-protocol must be updated accordingly.

### Skill `skills:` frontmatter rewrites

- `plugins/work/skills/create-ticket/SKILL.md` frontmatter line 5 - `core:gather-ticket-metadata` -> `gather-ticket-metadata` (now same-plugin)
- `plugins/work/skills/drive/SKILL.md` frontmatter line 5 - `core:commit` -> `commit` (now same-plugin)

### Work-side callers that must flip same-plugin -> cross-plugin / unprefixed -> `core:` prefixed

#### `plugins/work/commands/`

- `plugins/work/commands/ticket.md` line 21 - `${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/check.sh` -> `${CLAUDE_PLUGIN_ROOT}/../core/skills/check-deps/scripts/check.sh`
- `plugins/work/commands/drive.md` line 24 - `${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/check.sh` -> `${CLAUDE_PLUGIN_ROOT}/../core/skills/check-deps/scripts/check.sh`
- `plugins/work/commands/drive.md` lines 87-89 - `${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/archive.sh` -> `${CLAUDE_PLUGIN_ROOT}/../core/skills/drive/scripts/archive.sh`
- `plugins/work/commands/drive.md` frontmatter line 5 - `drive` -> `core:drive`
- `plugins/work/commands/trip.md` line 19 - `${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/check.sh` -> `${CLAUDE_PLUGIN_ROOT}/../core/skills/check-deps/scripts/check.sh`
- `plugins/work/commands/trip.md` lines 36, 59, 65 - `${CLAUDE_PLUGIN_ROOT}/skills/trip-protocol/scripts/*` -> `${CLAUDE_PLUGIN_ROOT}/../core/skills/trip-protocol/scripts/*`
- `plugins/work/commands/trip.md` frontmatter line 5 - `trip-protocol` -> `core:trip-protocol`

#### `plugins/work/agents/`

- `plugins/work/agents/ticket-organizer.md` frontmatter line 8 - `create-ticket` -> `core:create-ticket`
- `plugins/work/agents/discoverer.md` frontmatter line 7 - `discover` -> `core:discover`
- `plugins/work/agents/story-writer.md` frontmatter line 7 - `report` -> `core:report`
- `plugins/work/agents/pr-creator.md` frontmatter line 6 - `report` -> `core:report`
- `plugins/work/agents/release-readiness.md` frontmatter line 6 - `report` -> `core:report`
- `plugins/work/agents/planner.md` frontmatter line 8 - `trip-protocol` -> `core:trip-protocol`
- `plugins/work/agents/architect.md` frontmatter line 8 - `trip-protocol` -> `core:trip-protocol`
- `plugins/work/agents/constructor.md` frontmatter line 8 - `trip-protocol` -> `core:trip-protocol`

### Hook reference

- `plugins/work/hooks/validate-ticket.sh` line 9 - the error message points users at `plugins/work/skills/create-ticket/SKILL.md`. Update to `plugins/core/skills/create-ticket/SKILL.md`.

### Documentation/spec touch points

- `.workaholic/specs/application.md` line 499 references `plugins/work/skills/drive/SKILL.md`. Update to `plugins/core/skills/drive/SKILL.md`.
- `.workaholic/specs/usecase.md` line 374 references the same path. Update similarly.
- `CLAUDE.md` lines 18-32 (Project Structure) describe the skill inventory per plugin. Update the bullet listings: core gains the moved skills, work loses them. (`CLAUDE.md` is also touched by the companion ticket for the commands move and the dependency-diagram update.)

## Related History

The current core/work boundary was established by prior reorganizations that already moved skills back and forth between the two plugins; the same path-rewrite pattern (same-plugin to cross-plugin, frontmatter prefix updates, hook reference updates) applies here at larger scale. The most directly comparable predecessor is the work-plugin consolidation that introduced today's directory layout, and the ship/scan boundary trips that flipped commands and skills across the same boundary.

Past tickets that touched similar areas:

- [20260404014400-create-work-plugin-merge-drivin-trippin.md](.workaholic/tickets/archive/drive-20260403-230430/20260404014400-create-work-plugin-merge-drivin-trippin.md) - Created the work plugin and standardized `work:` cross-plugin prefixes; the rewrites it performed are the mirror image of this ticket.
- [20260404014402-update-core-crossrefs-for-work-plugin.md](.workaholic/tickets/archive/drive-20260403-230430/20260404014402-update-core-crossrefs-for-work-plugin.md) - Walked through every `skills:` frontmatter entry and inline `${CLAUDE_PLUGIN_ROOT}` reference in `core` to update prefixes; this ticket performs the same kind of audit in the opposite direction.
- [20260404023155-move-ship-command-from-core-to-work.md](.workaholic/tickets/archive/drive-20260403-230430/20260404023155-move-ship-command-from-core-to-work.md) - Earlier attempt to move `/ship` core->work; documents the path-rewrite and frontmatter-prefix mechanics in detail.
- [20260406133647-move-ship-scan-commands-from-work-to-core.md](.workaholic/tickets/archive/work-20260404-101424-fix-trip-report-dir-path/20260406133647-move-ship-scan-commands-from-work-to-core.md) - Reverse of the move above; explicitly captures the soft-reference pattern for cross-plugin skill preloads.

## Implementation Steps

1. **Move skill directories.** For each of `check-deps`, `create-ticket`, `discover`, `drive`, `report`, `trip-protocol`, move the full directory (including `scripts/` and any bundled assets) from `plugins/work/skills/<name>/` to `plugins/core/skills/<name>/`. Use `git mv` so history follows. Verify executable bits on shell scripts survive the move (`ls -l plugins/core/skills/*/scripts/*.sh`).

2. **Rewrite skill-internal references** in the moved files:
   - `plugins/core/skills/create-ticket/SKILL.md`: change `${CLAUDE_PLUGIN_ROOT}/../core/skills/gather-ticket-metadata/scripts/gather.sh` to `${CLAUDE_PLUGIN_ROOT}/skills/gather-ticket-metadata/scripts/gather.sh`; change `skills: - core:gather-ticket-metadata` frontmatter entry to `skills: - gather-ticket-metadata`.
   - `plugins/core/skills/drive/SKILL.md`: change `${CLAUDE_PLUGIN_ROOT}/../core/skills/commit/scripts/commit.sh` to `${CLAUDE_PLUGIN_ROOT}/skills/commit/scripts/commit.sh`; change frontmatter `skills: - core:commit` to `skills: - commit`.
   - `plugins/core/skills/trip-protocol/SKILL.md`: change `${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/` to `${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/`; change `${CLAUDE_PLUGIN_ROOT}/../core/skills/system-safety/scripts/detect.sh` to `${CLAUDE_PLUGIN_ROOT}/skills/system-safety/scripts/detect.sh`. The same-plugin `${CLAUDE_PLUGIN_ROOT}/skills/trip-protocol/scripts/` references already work as-is. Update the "Script base paths" table to reflect that both branching and trip-protocol scripts are now under `${CLAUDE_PLUGIN_ROOT}/skills/`.

3. **Update work-command path references.** In `plugins/work/commands/`:
   - `ticket.md`: prefix the `check-deps` script reference with `../core/`.
   - `drive.md`: prefix the `check-deps` and `drive/scripts/archive.sh` references with `../core/`; change frontmatter `skills: - drive` to `skills: - core:drive`.
   - `trip.md`: prefix the `check-deps` and `trip-protocol/scripts/*` references with `../core/`; change frontmatter `skills: - trip-protocol` to `skills: - core:trip-protocol`.

4. **Update work-agent frontmatter skill prefixes.** In `plugins/work/agents/`, change the frontmatter `skills:` entries to add the `core:` prefix wherever the entry currently names a moved skill: `ticket-organizer.md` (`create-ticket`), `discoverer.md` (`discover`), `story-writer.md` (`report`), `pr-creator.md` (`report`), `release-readiness.md` (`report`), `planner.md` (`trip-protocol`), `architect.md` (`trip-protocol`), `constructor.md` (`trip-protocol`). Body text that says "follow the preloaded **report** skill" or similar does NOT need rewriting -- skill names resolve regardless of prefix once loaded.

5. **Update the validate-ticket hook error message.** In `plugins/work/hooks/validate-ticket.sh`, change the `print_skill_reference` echo string from `plugins/work/skills/create-ticket/SKILL.md` to `plugins/core/skills/create-ticket/SKILL.md`.

6. **Update spec/documentation references.** In `.workaholic/specs/application.md` and `.workaholic/specs/usecase.md`, replace `plugins/work/skills/drive/SKILL.md` with `plugins/core/skills/drive/SKILL.md`. (Frontmatter `modified_at` should be refreshed per the work directory rule.) In `CLAUDE.md`, update the Project Structure block: core's skills line lists the moved skills; work's skills line is removed entirely (no skills remain in work after this ticket).

7. **Verification pass.** Run `grep -rn '\${CLAUDE_PLUGIN_ROOT}/skills/\(check-deps\|create-ticket\|discover\|drive\|report\|trip-protocol\)' plugins/work` and confirm no matches remain (every reference from work into these skills must now go through `../core/`). Run the same grep with `${CLAUDE_PLUGIN_ROOT}/../core/skills/(branching|system-safety|commit|gather-ticket-metadata)` against `plugins/core` and confirm no matches remain (every same-core same-plugin reference must now be unprefixed). Run `grep -rn 'skills:' plugins/work/agents plugins/work/commands | grep -E '(check-deps|create-ticket|discover|drive|report|trip-protocol)'` and confirm every match uses the `core:` prefix.

## Considerations

- **No new cross-plugin coupling is introduced.** All moved skills are consumed by `work` agents and commands; `work` already declares `core` as a dependency in `plugins/work/.claude-plugin/plugin.json`. The reverse direction (core consuming work) is NOT introduced by this ticket -- nothing in the moved skills back-references work assets. The trip-protocol scripts are bundled with the skill and travel with it, so no work-only assets are referenced from core after the move. (`plugins/work/.claude-plugin/plugin.json`)
- **`work:trip-protocol` soft references in `plugins/core/commands/`.** While the commands `/report` and `/ship` still live in core (they are moved in the companion ticket), they preload `work:trip-protocol`. After this ticket lands but before the companion ticket lands, those preload entries become incorrect (`trip-protocol` will now live in core, not work). To avoid a temporary broken state, update those entries in this ticket as well: `plugins/core/commands/report.md` frontmatter line 5 and `plugins/core/commands/ship.md` frontmatter line 5 -- change `work:trip-protocol` to `trip-protocol` (same-plugin once trip-protocol moves to core). The companion ticket then removes these files entirely, so the rewrite is short-lived but necessary for ordering safety. (`plugins/core/commands/report.md`, `plugins/core/commands/ship.md`)
- **Hook path independence.** `plugins/work/hooks/hooks.json` uses `${CLAUDE_PLUGIN_ROOT}/hooks/validate-ticket.sh` -- the hook script stays in work, so no path change there. Only the human-readable error message inside the script needs updating. (`plugins/work/hooks/hooks.json`)
- **CLAUDE.md dependency diagram unchanged.** The diagram and dependency rules (`work -> core`, work soft-references standards, core soft-references work) are preserved by this ticket. The companion ticket revisits the "core soft-references work" claim because once `/report` and `/ship` leave core, core no longer has a reason to soft-reference work. (`CLAUDE.md` lines 45-54)
- **Validity lens (Ours/Theirs Layer Segregation, Ubiquitous Language).** Moving the skills places reusable knowledge in the dependency-free base plugin and confines code-specific orchestration to work. This sharpens the "core = library, work = application" segregation that `standards:leading-validity` advocates. Naming stays stable: skill basenames (`drive`, `report`, etc.) are unchanged, so the ubiquitous-language principle (one term per concept) is preserved. (`plugins/standards/skills/leading-validity/SKILL.md`)
- **Availability lens (Vendor Neutrality).** No external dependencies are introduced; the move is purely internal restructuring. The `git mv` preserves history, satisfying observability of past changes. (`plugins/standards/skills/leading-availability/SKILL.md`)
- **Skill-name-only references in body text.** Markdown body text in agents and commands frequently says "follow the preloaded **trip-protocol** skill". These do not need a `core:` prefix in body text -- the prefix is only meaningful in frontmatter `skills:` lists and in `${CLAUDE_PLUGIN_ROOT}` paths. Leaving body text as-is keeps prose readable. (`plugins/work/agents/architect.md` line 35, `plugins/work/agents/constructor.md` line 36, `plugins/work/agents/planner.md` line 35)
- **Independent of companion ticket on file moves, coupled on CLAUDE.md.** This ticket and `20260514121300-move-report-ship-commands-to-work.md` can be implemented in either order. Both edit `CLAUDE.md`, so whichever lands second must reconcile its diff with the first. The `depends_on` field is left empty so that either may go first.

## Patches

### `plugins/work/commands/ticket.md`

```diff
--- a/plugins/work/commands/ticket.md
+++ b/plugins/work/commands/ticket.md
@@ -18,7 +18,7 @@
 ### Pre-check: Dependencies

 ```bash
-bash ${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/check.sh
+bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/check-deps/scripts/check.sh
 ```

 If `ok` is `false`, display the `message` to the user and stop.
```

### `plugins/work/commands/drive.md`

```diff
--- a/plugins/work/commands/drive.md
+++ b/plugins/work/commands/drive.md
@@ -2,7 +2,7 @@
 name: drive
 description: Implement tickets from .workaholic/tickets/ one by one, commit each, and archive.
 skills:
-  - drive
+  - core:drive
   - core:system-safety
   - standards:leading-validity
   - standards:leading-accessibility
@@ -21,7 +21,7 @@
 ### Pre-check: Dependencies

 ```bash
-bash ${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/check.sh
+bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/check-deps/scripts/check.sh
 ```

 If `ok` is `false`, display the `message` to the user and stop.
@@ -84,7 +84,7 @@
 2. **Verify update succeeded**: If Edit tool fails, halt and report the error to user. DO NOT proceed to archive.
 3. Archive and commit by calling the archive script directly:
    ```bash
-   bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/archive.sh \
+   bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/drive/scripts/archive.sh \
      <ticket-path> "<title>" <repo-url> "<description>" "<changes>" "<test-plan>" "<release-prep>"
    ```
    Where `<ticket-path>` is the current ticket file path in `todo/`, `<title>` is the commit title,
```

### `plugins/work/commands/trip.md`

```diff
--- a/plugins/work/commands/trip.md
+++ b/plugins/work/commands/trip.md
@@ -2,7 +2,7 @@
 name: trip
 description: Launch Agent Teams session with Planner, Architect, and Constructor
 skills:
-  - trip-protocol
+  - core:trip-protocol
 ---

 # Trip
@@ -16,7 +16,7 @@
 ## Pre-check: Dependencies

 ```bash
-bash ${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/check.sh
+bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/check-deps/scripts/check.sh
 ```

 If `ok` is `false`, display the `message` to the user and stop.
@@ -33,7 +33,7 @@

 **Resume (worktree)**: Use selected worktree's path/branch. Read plan state:
 ```bash
-bash ${CLAUDE_PLUGIN_ROOT}/skills/trip-protocol/scripts/read-plan.sh "<trip-path>"
+bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/trip-protocol/scripts/read-plan.sh "<trip-path>"
 ```
 Route by state: `planning/not-started` -> Step 3, any other planning/coding step -> Step 4 with resume context, `complete/done` -> inform user and suggest `/report`.

@@ -56,13 +56,13 @@
 ## Step 2: Initialize Trip Artifacts

 ```bash
-bash ${CLAUDE_PLUGIN_ROOT}/skills/trip-protocol/scripts/init-trip.sh "<trip-name>" "$ARGUMENT" "<working_dir>"
+bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/trip-protocol/scripts/init-trip.sh "<trip-name>" "$ARGUMENT" "<working_dir>"
 ```

 ## Step 3: Validate Dev Environment

 ```bash
-bash ${CLAUDE_PLUGIN_ROOT}/skills/trip-protocol/scripts/validate-dev-env.sh "<working_dir>"
+bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/trip-protocol/scripts/validate-dev-env.sh "<working_dir>"
 ```

 If `ready` is false, fix each failing check (copy env files, install dependencies, configure ports) and re-run.
```

### `plugins/work/agents/ticket-organizer.md`

```diff
--- a/plugins/work/agents/ticket-organizer.md
+++ b/plugins/work/agents/ticket-organizer.md
@@ -5,7 +5,7 @@ tools: Read, Write, Edit, Glob, Grep, Bash, Task
 model: opus
 skills:
   - core:branching
-  - create-ticket
+  - core:create-ticket
   - core:gather-ticket-metadata
   - standards:leading-validity
   - standards:leading-accessibility
```

### `plugins/work/agents/discoverer.md`

```diff
--- a/plugins/work/agents/discoverer.md
+++ b/plugins/work/agents/discoverer.md
@@ -4,7 +4,7 @@ description: Context discovery agent supporting history, source, and policy anal
 tools: Bash, Read, Glob, Grep
 model: opus
 skills:
-  - discover
+  - core:discover
 ---
```

### `plugins/work/agents/story-writer.md`

```diff
--- a/plugins/work/agents/story-writer.md
+++ b/plugins/work/agents/story-writer.md
@@ -4,7 +4,7 @@ description: Generate branch story for PR description and create/update the pull
 tools: Read, Write, Edit, Bash, Glob, Grep, Task
 skills:
   - core:gather-git-context
-  - report
+  - core:report
 ---
```

### `plugins/work/agents/pr-creator.md`

```diff
--- a/plugins/work/agents/pr-creator.md
+++ b/plugins/work/agents/pr-creator.md
@@ -3,7 +3,7 @@ name: pr-creator
 description: Create or update GitHub PR from story file. Handles PR existence check, title derivation, and gh CLI operations.
 tools: Read, Bash, Glob
 skills:
-  - report
+  - core:report
 ---
```

### `plugins/work/agents/release-readiness.md`

```diff
--- a/plugins/work/agents/release-readiness.md
+++ b/plugins/work/agents/release-readiness.md
@@ -3,7 +3,7 @@ name: release-readiness
 description: Assess if a branch is ready for release. Reads codebase changes and identifies blocking issues.
 tools: Read, Bash, Glob, Grep
 skills:
-  - report
+  - core:report
 ---
```

### `plugins/work/agents/planner.md`

```diff
--- a/plugins/work/agents/planner.md
+++ b/plugins/work/agents/planner.md
@@ -5,7 +5,7 @@ tools: Read, Write, Edit, Glob, Grep, Bash
 model: opus
 color: blue
 skills:
-  - trip-protocol
+  - core:trip-protocol
   - standards:leading-validity
```

### `plugins/work/agents/architect.md`

```diff
--- a/plugins/work/agents/architect.md
+++ b/plugins/work/agents/architect.md
@@ -5,7 +5,7 @@ tools: Read, Write, Edit, Glob, Grep, Bash
 model: opus
 color: green
 skills:
-  - trip-protocol
+  - core:trip-protocol
   - standards:leading-validity
```

### `plugins/work/agents/constructor.md`

```diff
--- a/plugins/work/agents/constructor.md
+++ b/plugins/work/agents/constructor.md
@@ -5,7 +5,7 @@ tools: Read, Write, Edit, Glob, Grep, Bash
 model: opus
 color: red
 skills:
-  - trip-protocol
+  - core:trip-protocol
   - core:system-safety
   - standards:leading-validity
```

### `plugins/work/hooks/validate-ticket.sh`

```diff
--- a/plugins/work/hooks/validate-ticket.sh
+++ b/plugins/work/hooks/validate-ticket.sh
@@ -6,7 +6,7 @@ set -e

 # Print reference to authoritative skill documentation
 print_skill_reference() {
-  echo "See: plugins/work/skills/create-ticket/SKILL.md" >&2
+  echo "See: plugins/core/skills/create-ticket/SKILL.md" >&2
 }
```

### `plugins/core/commands/report.md`

> **Note**: This patch is short-lived; the companion ticket relocates this file to `plugins/work/commands/report.md` and rewrites the frontmatter again. Apply it only if this ticket lands first. (The patch is speculative -- verify before applying.)

```diff
--- a/plugins/core/commands/report.md
+++ b/plugins/core/commands/report.md
@@ -2,7 +2,7 @@
 name: report
 description: Context-aware report generation and PR creation for drive and trip workflows.
 skills:
-  - work:trip-protocol
+  - trip-protocol
   - branching
 ---
```

### `plugins/core/commands/ship.md`

> **Note**: Same short-lived caveat as `report.md` above. Speculative -- verify before applying.

```diff
--- a/plugins/core/commands/ship.md
+++ b/plugins/core/commands/ship.md
@@ -2,7 +2,7 @@
 name: ship
 description: Context-aware ship workflow - merge PR, deploy, and verify (with worktree cleanup for trips).
 skills:
-  - work:trip-protocol
+  - trip-protocol
   - ship
   - branching
 ---
```
