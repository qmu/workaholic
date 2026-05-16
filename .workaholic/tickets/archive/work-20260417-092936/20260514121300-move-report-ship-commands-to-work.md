---
created_at: 2026-05-14T12:13:00+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 0.5h
commit_hash: 91868cb
category: Changed
depends_on:
---

# Move /report and /ship commands from core to work; update manifests and CLAUDE.md

## Overview

Relocate `/report` and `/ship` from `plugins/core/commands/` into `plugins/work/commands/`. Both commands are code-aware orchestration: they detect drive/trip context, invoke work-specific subagents (`work:story-writer`, `work:release-readiness`, `work:pr-creator`), and preload the `trip-protocol` skill. Under the new core/work boundary, code-dependent components belong in `work`. After the move, `core` is purely a reusable-skill library and stops needing the soft reference to `work`. This ticket finalizes the boundary by relocating the commands, rewriting every `${CLAUDE_PLUGIN_ROOT}` path that flips direction, dropping the now-unused soft-reference language from `CLAUDE.md`, and ensuring the dependency diagram and Commands table reflect the final layout. It is a companion to `20260514121259-move-work-skills-to-core.md`; the two are mechanically independent (either can land first) but both edit `CLAUDE.md` and must be reconciled when the second lands.

## Key Files

### Files to move

- `plugins/core/commands/report.md` -> `plugins/work/commands/report.md`
- `plugins/core/commands/ship.md` -> `plugins/work/commands/ship.md`

### Path rewrites inside the moved files (same-plugin <-> cross-plugin direction flips)

In each moved file, references that previously resolved relative to core must be rewritten for work's vantage point. The exact set depends on whether the companion skills-move ticket has already landed:

#### If the skills move has NOT yet landed (`branching`, `ship`, `trip-protocol` still in core)

- `plugins/work/commands/report.md` lines 20, 34, 47, 54, 67 - `${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/*` -> `${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/*` (branching stays in core)
- `plugins/work/commands/ship.md` lines 21, 49, 70 - same branching prefix flip
- `plugins/work/commands/ship.md` lines 35, 58-62 - `${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/*` -> `${CLAUDE_PLUGIN_ROOT}/../core/skills/ship/scripts/*`
- `plugins/work/commands/ship.md` line 61 - `${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/cleanup-worktree.sh` -> same `../core/` prefix
- Frontmatter `skills:` entries flip: `branching` -> `core:branching` (cross-plugin); `ship` -> `core:ship`; `work:trip-protocol` -> `trip-protocol` (now same-plugin in work)

#### If the skills move HAS landed (`trip-protocol` already in core)

- Branching/ship script references unchanged from the case above (those skills remain in core regardless).
- Frontmatter `work:trip-protocol` (the original entry in `plugins/core/commands/`) was rewritten to `trip-protocol` by the skills-move ticket; after this ticket moves the file to work, the entry must become `core:trip-protocol` (cross-plugin from work's vantage point).

### Manifest updates

- `plugins/core/.claude-plugin/plugin.json` - The note in `CLAUDE.md` about "core has a soft reference to work (context-aware routing in /report and /ship)" stops being true after this ticket. The `dependencies` array (currently `[]`) stays empty; only the prose explaining the soft reference is removed.
- `plugins/work/.claude-plugin/plugin.json` - `dependencies: ["core"]` stays unchanged. Work already declares core as a dependency; relocating commands does not change that.

### Documentation updates

- `CLAUDE.md` lines 11-33 (Project Structure block) - core's `commands/` line currently lists `report, ship`; after this ticket it is removed entirely (core has no commands). Work's `commands/` line currently lists `ticket, drive, trip`; it gains `report, ship`. The skills lines for each plugin are owned by the companion ticket.
- `CLAUDE.md` line 54 (soft-reference language) - "Core has a soft reference to work (context-aware routing in `/report` and `/ship`)." -- delete this sentence. The remaining "Work has soft references to standards" sentence stays.
- `CLAUDE.md` lines 122-130 (Commands table) - no changes to the visible table (the same command names exist); only the structural layout above changes.

## Related History

The current placement of `/report` and `/ship` in core resulted from past trips of the same commands across the same boundary; this ticket is the next step in a steady consolidation of code-dependent orchestration into `work`. Previous moves established the patterns this ticket reuses: frontmatter prefix flips, `${CLAUDE_PLUGIN_ROOT}/../<plugin>/` path direction, and explicit removal of soft-reference language from `CLAUDE.md`.

Past tickets that touched similar areas:

- [20260404023155-move-ship-command-from-core-to-work.md](.workaholic/tickets/archive/drive-20260403-230430/20260404023155-move-ship-command-from-core-to-work.md) - First moved `/ship` core->work; explicitly recorded the frontmatter and path-prefix flips that this ticket repeats for both commands. The ticket noted that a future ticket could evaluate moving `/report` as well -- that future ticket is the present one.
- [20260406133647-move-ship-scan-commands-from-work-to-core.md](.workaholic/tickets/archive/work-20260404-101424-fix-trip-report-dir-path/20260406133647-move-ship-scan-commands-from-work-to-core.md) - Reverse of the move above; captures the "core has soft reference to work via cross-plugin skill" pattern that this ticket is removing.
- [20260404014402-update-core-crossrefs-for-work-plugin.md](.workaholic/tickets/archive/drive-20260403-230430/20260404014402-update-core-crossrefs-for-work-plugin.md) - Comprehensive audit of cross-plugin frontmatter and inline path references; the verification grep pattern in this ticket mirrors that audit.
- [20260406193700-remove-write-trip-report-skill.md](.workaholic/tickets/archive/work-20260406-193458/20260406193700-remove-write-trip-report-skill.md) - Most recent edit to `plugins/core/commands/report.md` frontmatter `skills:` list and Trip Mode flow; documents the version that this ticket relocates.

## Implementation Steps

1. **Move command files.** Run `git mv plugins/core/commands/report.md plugins/work/commands/report.md` and `git mv plugins/core/commands/ship.md plugins/work/commands/ship.md`. Confirm `plugins/core/commands/` is now empty (the entire directory may be removed if Claude Code allows it; otherwise leave it empty -- both are acceptable).

2. **Determine current trip-protocol location.** Check whether the companion skills-move ticket has landed: `[ -d plugins/core/skills/trip-protocol ] && echo "core" || echo "work"`. The result drives the frontmatter prefix for `trip-protocol` (see step 4 below).

3. **Rewrite `${CLAUDE_PLUGIN_ROOT}` paths in the moved files.** In both `plugins/work/commands/report.md` and `plugins/work/commands/ship.md`:
   - Replace every `${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/` with `${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/` (branching is in core, so from work this is cross-plugin).
   - In `ship.md` only, replace every `${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/` with `${CLAUDE_PLUGIN_ROOT}/../core/skills/ship/scripts/`.
   - If the trip-protocol skill is in core (companion ticket landed): no further inline path changes for trip-protocol are needed because neither command file references trip-protocol scripts inline -- the preload via frontmatter is what matters (see step 4).

4. **Rewrite frontmatter `skills:` lists.** In each moved file, the new prefixes are:
   - `branching` -> `core:branching`
   - `ship` -> `core:ship` (ship.md only)
   - `trip-protocol`: prefix depends on companion ticket. If companion has NOT landed (trip-protocol still in work), use `work:trip-protocol`. If companion HAS landed (trip-protocol in core), use `core:trip-protocol`. The original `work:trip-protocol` entry in the pre-move file may already have been rewritten to `trip-protocol` by the companion ticket's interim patch -- this ticket finalizes it to the correct cross-plugin form.

5. **Update `CLAUDE.md` Project Structure.** Edit the block at lines 11-33:
   - Remove the `commands/ # report, ship` line under `core/`.
   - Update the `commands/ # ticket, drive, trip` line under `work/` to `commands/ # ticket, drive, trip, report, ship`.
   - The skills-line edits in this block are owned by the companion ticket; if it has not yet landed, leave them alone. If it has landed, ensure the listings agree.

6. **Update `CLAUDE.md` dependency narrative.** Delete the sentence "Core has a soft reference to work (context-aware routing in `/report` and `/ship`)." at line 54. The dependency diagram lines 47-52 stay as-is (the soft-reference arrow from core to work was already conceptual; with the commands removed, no link remains). The remaining sentence about work's soft references to standards is preserved.

7. **Verification pass.**
   - `grep -rn '\${CLAUDE_PLUGIN_ROOT}/skills/branching\|\${CLAUDE_PLUGIN_ROOT}/skills/ship/' plugins/work/commands` must return zero matches (every reference must use the `../core/` prefix).
   - `ls plugins/core/commands/` must show no files (or the directory may be removed).
   - `grep -n 'work:trip-protocol\|core: .* report .* ship' CLAUDE.md` should not surface the soft-reference sentence.
   - Run the workflow once end-to-end: from a worktree on a `work-*` branch, invoke `/report` and confirm the context detection and skill preloads still resolve. Then invoke `/ship` on a branch with a merged PR to confirm the same.

## Considerations

- **Order-independent with the companion ticket, but CLAUDE.md is shared.** Either ticket may land first. The Project Structure block in `CLAUDE.md` is touched by both; the second ticket must rebase its edits onto the first ticket's result. Both tickets describe the final state for the sections they own, so a clean reconciliation is straightforward: this ticket owns the `commands/` listings and the soft-reference sentence; the companion owns the `skills/` listings. (`CLAUDE.md` lines 11-33, 54)
- **Trip-protocol prefix is conditional on companion ordering.** Step 4 above explicitly handles both orderings. If implementation happens with the companion already merged, the frontmatter entry is `core:trip-protocol`; otherwise it is `work:trip-protocol`. The implementer must verify the current location before choosing. (`plugins/core/skills/trip-protocol/` vs `plugins/work/skills/trip-protocol/`)
- **Empty `plugins/core/commands/` directory.** After the move, the directory holds no files. Leaving an empty directory is harmless under Claude Code's plugin loader, but `git` does not track empty directories so it will simply disappear from the repo. Removing the directory explicitly is not required.
- **No new dependency edges.** The dependency graph stays `work -> core` (one-way, declared); `work` already declares this in its `plugin.json`. Core's `dependencies: []` stays empty. Soft references (skill preloads, subagent invocations across plugins) are still tolerated by the loader without `plugin.json` changes. (`plugins/core/.claude-plugin/plugin.json`, `plugins/work/.claude-plugin/plugin.json`)
- **Validity lens (Ours/Theirs Layer Segregation).** Pulling code-aware commands into `work` and leaving `core` as a dependency-free library reinforces the "ours" (work-specific) / "theirs" (reusable) split that `standards:leading-validity` advocates. The boundary between the two plugins now correlates with the difference between "code-dependent" and "code-agnostic" -- the same kind of segregation the lead applies to domain-vs-infrastructure code. (`plugins/standards/skills/leading-validity/SKILL.md`)
- **Availability lens (CI/CD Automation First, Observability).** Use `git mv` for both files so history follows; no other availability concerns apply. The Commands table in `CLAUDE.md` stays accurate, preserving documentation observability. (`plugins/standards/skills/leading-availability/SKILL.md`)
- **No behavioral change.** Users invoke `/report` and `/ship` the same way; they cannot tell which plugin a command lives in. The only externally visible change is that installing only the `core` plugin no longer exposes `/report` or `/ship`. Anyone using just core would no longer have these commands -- consistent with the new boundary (core is a library, not a workflow). If a downstream consumer depended on this, surface it in the PR description. (`CLAUDE.md` Commands table lines 122-130)
- **Cross-reference companion ticket.** The companion ticket `20260514121259-move-work-skills-to-core.md` describes the corresponding move in the opposite direction. Together they constitute the full boundary redraw the user requested.

## Patches

> **Note**: The patches below assume the companion skills-move ticket has NOT yet landed (so `trip-protocol` is still in work and `branching`/`ship` are still in core). If the companion ticket lands first, the frontmatter line `- trip-protocol` should be `- core:trip-protocol` instead of `- work:trip-protocol`. The patches are speculative -- verify the trip-protocol location before applying.

### `plugins/core/commands/report.md` -> `plugins/work/commands/report.md`

```diff
--- a/plugins/core/commands/report.md
+++ b/plugins/work/commands/report.md
@@ -1,8 +1,8 @@
 ---
 name: report
 description: Context-aware report generation and PR creation for drive and trip workflows.
 skills:
-  - work:trip-protocol
-  - branching
+  - trip-protocol
+  - core:branching
 ---

 # Report
@@ -17,7 +17,7 @@
 ### Step 0: Workspace Guard

 ```bash
-bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check-workspace.sh
+bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/check-workspace.sh
 ```

 Parse the JSON output. If `clean` is `true`, proceed silently to Step 1.
@@ -31,7 +31,7 @@
 ### Step 1: Detect Context

 ```bash
-bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/detect-context.sh
+bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/detect-context.sh
 ```

 Parse the JSON output. Route to the appropriate workflow based on `context`.
@@ -44,12 +44,12 @@

 ##### Drive Mode (`mode: "drive"`)

-1. **Bump version** following CLAUDE.md Version Management section (patch increment). **Skip if a "Bump version" commit already exists in the current branch** (check with `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check-version-bump.sh`; if `already_bumped` is `true`, skip this step).
+1. **Bump version** following CLAUDE.md Version Management section (patch increment). **Skip if a "Bump version" commit already exists in the current branch** (check with `bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/check-version-bump.sh`; if `already_bumped` is `true`, skip this step).
 2. **Invoke story-writer** (`subagent_type: "work:story-writer"`, `model: "opus"`)
 3. **Display story content**: Read the story file from the `story_file` path in the story-writer result and output the entire Markdown content so the developer can review inline
 4. **Display PR URL** from story-writer result (mandatory)

 ##### Trip Mode (`mode: "trip"`)

-1. **Bump version** following CLAUDE.md Version Management section (patch increment). **Skip if a "Bump version" commit already exists in the current branch** (check with `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check-version-bump.sh`; if `already_bumped` is `true`, skip this step).
+1. **Bump version** following CLAUDE.md Version Management section (patch increment). **Skip if a "Bump version" commit already exists in the current branch** (check with `bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/check-version-bump.sh`; if `already_bumped` is `true`, skip this step).
 2. **Invoke story-writer** (`subagent_type: "work:story-writer"`, `model: "opus"`)
@@ -64,7 +64,7 @@

 Not on a work branch, but worktrees exist.

-1. Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/list-worktrees.sh`
+1. Run `bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/list-worktrees.sh`
 2. Filter to worktrees where `has_pr` is `false` (unreported work)
 3. If no unreported worktrees found: inform the user "No unreported worktrees found." and stop.
```

### `plugins/core/commands/ship.md` -> `plugins/work/commands/ship.md`

```diff
--- a/plugins/core/commands/ship.md
+++ b/plugins/work/commands/ship.md
@@ -1,9 +1,9 @@
 ---
 name: ship
 description: Context-aware ship workflow - merge PR, deploy, and verify (with worktree cleanup for trips).
 skills:
-  - work:trip-protocol
-  - ship
-  - branching
+  - trip-protocol
+  - core:ship
+  - core:branching
 ---

 # Ship
@@ -18,7 +18,7 @@
 ### Step 0: Workspace Guard

 ```bash
-bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check-workspace.sh
+bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/check-workspace.sh
 ```

 Parse the JSON output. If `clean` is `true`, proceed silently to Step 1.
@@ -32,7 +32,7 @@
 ### Step 0.5: Ticket Guard

 ```bash
-bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/check-todo.sh
+bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/ship/scripts/check-todo.sh
 ```

 Parse the JSON output. If `clean` is `true`, proceed silently to Step 1.
@@ -46,7 +46,7 @@
 ### Step 1: Detect Context

 ```bash
-bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/detect-context.sh
+bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/detect-context.sh
 ```

 Parse the JSON output. Route to the appropriate workflow based on `context`.
@@ -55,11 +55,11 @@

 #### Work Context (`context: "work"`)

-1. **Pre-check**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/pre-check.sh "<branch>"`. If `found` is `false`: inform user "No PR found for this branch. Run `/report` first." and stop. If `merged` is `true`: skip to Clean up worktree.
-2. **Merge PR**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/merge-pr.sh "<pr-number>"`. On failure, inform user and stop.
-3. **Sync gitignored files** (if worktree exists): Check if `.worktrees/<branch>/` exists. If yes, run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/find-gitignored-files.sh "<worktree-path>"`. If `has_changes` is `true`, display the file list and ask via AskUserQuestion with options: **"Copy all to main worktree"**, **"Skip and erase"**. If "Copy all", run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/sync-gitignored-files.sh "<worktree-path>" "<main-repo-root>" '<files-json>'` with all file paths. If `has_changes` is `false`, proceed silently. If no worktree exists, skip this step.
-4. **Clean up worktree** (if applicable): Check if `.worktrees/<branch>/` exists. If yes, run `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/cleanup-worktree.sh "<branch>"` and report what was cleaned up. If no worktree exists, skip this step.
-5. **Deploy**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/find-cloud-md.sh`. If `found` is `false`: inform user "No cloud.md found. Deployment skipped." and skip to summary. If `found` is `true`: read the file, find `## Deploy` section, ask confirmation via AskUserQuestion, execute if confirmed.
+1. **Pre-check**: Run `bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/ship/scripts/pre-check.sh "<branch>"`. If `found` is `false`: inform user "No PR found for this branch. Run `/report` first." and stop. If `merged` is `true`: skip to Clean up worktree.
+2. **Merge PR**: Run `bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/ship/scripts/merge-pr.sh "<pr-number>"`. On failure, inform user and stop.
+3. **Sync gitignored files** (if worktree exists): Check if `.worktrees/<branch>/` exists. If yes, run `bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/ship/scripts/find-gitignored-files.sh "<worktree-path>"`. If `has_changes` is `true`, display the file list and ask via AskUserQuestion with options: **"Copy all to main worktree"**, **"Skip and erase"**. If "Copy all", run `bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/ship/scripts/sync-gitignored-files.sh "<worktree-path>" "<main-repo-root>" '<files-json>'` with all file paths. If `has_changes` is `false`, proceed silently. If no worktree exists, skip this step.
+4. **Clean up worktree** (if applicable): Check if `.worktrees/<branch>/` exists. If yes, run `bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/cleanup-worktree.sh "<branch>"` and report what was cleaned up. If no worktree exists, skip this step.
+5. **Deploy**: Run `bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/ship/scripts/find-cloud-md.sh`. If `found` is `false`: inform user "No cloud.md found. Deployment skipped." and skip to summary. If `found` is `true`: read the file, find `## Deploy` section, ask confirmation via AskUserQuestion, execute if confirmed.
 6. **Verify**: If cloud.md found, read `## Verify` section and execute. Report results.
 7. **Summarize**: PR merge status (number, URL), gitignored file sync status, worktree cleanup status, deployment status, verification results.

@@ -67,7 +67,7 @@

 Not on a work branch, but worktrees exist.

-1. Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/list-worktrees.sh`
+1. Run `bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/list-worktrees.sh`
 2. Filter to worktrees where `has_pr` is `true` (branches with PRs ready to ship)
 3. If no shippable worktrees found: inform the user "No worktrees with open PRs found. Run `/report` first." and stop.
```

### `CLAUDE.md`

```diff
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -17,15 +17,15 @@
 plugins/                 # Plugin source directories
   core/                  # Core shared plugin (no dependencies)
     .claude-plugin/      # Plugin configuration
-    commands/            # report, ship
     skills/              # branching, commit, gather-git-context, gather-ticket-metadata, ship, system-safety
   standards/             # Standards policy plugin (no dependencies)
     .claude-plugin/      # Plugin configuration
     agents/              # lead, writers, analysts
     skills/              # leading-*, analyze-*, write-*
   work/                  # Work plugin: drive + trip workflows (depends on: core)
     .claude-plugin/      # Plugin configuration
     agents/              # drive-navigator, story-writer, planner, architect, constructor, etc.
-    commands/            # ticket, drive, trip
+    commands/            # ticket, drive, trip, report, ship
     hooks/               # ticket validation
     rules/               # general, workaholic
     skills/              # create-ticket, discover, drive, report, trip-protocol, check-deps
@@ -51,7 +51,7 @@
 work ─ ─ ─ ─ ─
 ```

-Each plugin declares `dependencies` in its `plugin.json`. Cross-plugin `${CLAUDE_PLUGIN_ROOT}/../<name>/` references must only target declared dependencies. Soft references (skill preloads, subagent invocations) do not require a declared dependency — they are used when the referenced plugin is installed but do not prevent the caller from functioning without it. Core has a soft reference to work (context-aware routing in `/report` and `/ship`). Work has soft references to standards (leading skill preloads, writer subagent invocations).
+Each plugin declares `dependencies` in its `plugin.json`. Cross-plugin `${CLAUDE_PLUGIN_ROOT}/../<name>/` references must only target declared dependencies. Soft references (skill preloads, subagent invocations) do not require a declared dependency — they are used when the referenced plugin is installed but do not prevent the caller from functioning without it. Work has soft references to standards (leading skill preloads, writer subagent invocations).
```

> **Note**: The `skills:` line under `work/` in the Project Structure block is also touched by the companion ticket (which removes all skill names because every skill moves to core). Whichever ticket lands second must reconcile that line. This patch leaves it alone.

## Final Report

Development completed as planned. The companion ticket landed first, so the trip-protocol entry was finalized to `core:trip-protocol` (rather than the original `work:trip-protocol`) and the inline `${CLAUDE_PLUGIN_ROOT}/skills/{branching,ship}/...` paths were rewritten to the `../core/` cross-plugin form. CLAUDE.md reconciliation worked cleanly: this ticket owned the `commands/` listings and the soft-reference sentence; the companion owned the `skills/` listings, so the edits did not collide.

### Discovered Insights

- **Insight**: After both tickets land, `plugins/core/commands/` is empty (no files, no git tracking) and `core` has zero command components. Core's role is purely "skill library + agent runtime"; only `work` (and `standards`) expose user-facing commands.
  **Context**: This sharpens the architectural invariant: any future command added to core would violate the new "code-agnostic library" identity. A lint or doc rule could enforce this if desired.
- **Insight**: The dependency diagram block in CLAUDE.md (lines 47-52) still shows a soft-reference arrow shape (`⤴ soft`, `⤴`), but it refers to work soft-referencing standards — not the now-removed core→work soft reference. The diagram needed no edit because the prior soft-reference prose was the only place that described the (now-defunct) core→work link.
  **Context**: When deleting a relationship, check both the ASCII diagram and the descriptive prose; conventions can drift apart. Here they were already aligned, but it's not a given.
