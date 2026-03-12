---
created_at: 2026-03-11T21:20:23+09:00
author: a@qmu.jp
type: refactoring
layer: [UX, Config]
effort: 1h
commit_hash: 437cadc
category: Added
---

# Unify Ship Command and Create Core Plugin

## User Feedback

> Don't store the report or ship commands in the Trippin plugin. Create a core plugin instead. Both /report and /ship should live in the core plugin as shared commands.

## Overview

Create a new **core plugin** (`plugins/core/`) to house shared commands that span both Drivin and Trippin workflows. Move the already-created `/report` command from Trippin to core, and create the unified `/ship` command in core. Also move the branching skill (detect-context.sh) to core since it serves both workflows. Remove `/ship-drive` from Drivin, `/ship-trip` from Trippin, and Drivin's duplicate ship skill.

## Key Files

- `plugins/drivin/commands/ship-drive.md` - Drive ship command to be absorbed and removed
- `plugins/trippin/commands/ship-trip.md` - Trip ship command to be replaced by unified `/ship`
- `plugins/trippin/skills/branching/sh/detect-context.sh` - Context detection script (created by companion report ticket)
- `plugins/trippin/skills/ship/SKILL.md` - Ship skill with cloud.md convention and shell scripts
- `plugins/trippin/skills/ship/sh/pre-check.sh` - PR pre-check script
- `plugins/trippin/skills/ship/sh/merge-pr.sh` - PR merge and main sync script
- `plugins/trippin/skills/ship/sh/find-cloud-md.sh` - Cloud.md discovery script
- `plugins/trippin/skills/trip-protocol/sh/cleanup-worktree.sh` - Worktree cleanup (trip-specific step)
- `plugins/trippin/skills/trip-protocol/sh/list-trip-worktrees.sh` - Worktree discovery for trip context fallback
- `plugins/drivin/skills/ship/SKILL.md` - Drivin's ship skill (can be removed after migration)
- `plugins/drivin/skills/ship/sh/pre-check.sh` - Drivin's pre-check (identical to Trippin's copy)
- `plugins/drivin/skills/ship/sh/merge-pr.sh` - Drivin's merge script (identical to Trippin's copy)
- `plugins/drivin/skills/ship/sh/find-cloud-md.sh` - Drivin's find-cloud-md (identical to Trippin's copy)
- `plugins/drivin/rules/general.md` - References `/ship-drive` in commit-allowed commands
- `CLAUDE.md` - Commands table, project structure, development workflow
- `README.md` - Command tables for both plugins
- `plugins/drivin/README.md` - Drivin commands table, skills table, workflow
- `plugins/trippin/README.md` - Trippin commands table

## Related History

The ship commands were created as a pair following the report commands, with ship-drive establishing the cloud.md convention and ship-trip extending it with worktree cleanup. The shared ship scripts were then extracted from Drivin into Trippin to eliminate cross-plugin dependency. This ticket completes the consolidation by merging both commands into a single unified `/ship`.

Past tickets that touched similar areas:

- [20260311193203-worktree-aware-report-ship-trip.md](.workaholic/tickets/archive/drive-20260311-125319/20260311193203-worktree-aware-report-ship-trip.md) - Added worktree fallback to ship-trip (preserve this logic in unified command)
- [20260311105613-add-ship-drive-command.md](.workaholic/tickets/archive/drive-20260310-220224/20260311105613-add-ship-drive-command.md) - Created /ship-drive with cloud.md convention and ship skill
- [20260311105614-add-ship-trip-command.md](.workaholic/tickets/archive/drive-20260310-220224/20260311105614-add-ship-trip-command.md) - Created /ship-trip with worktree cleanup step
- [20260311121300-extract-shared-ship-scripts.md](.workaholic/tickets/archive/drive-20260310-220224/20260311121300-extract-shared-ship-scripts.md) - Extracted ship scripts to Trippin, eliminating cross-plugin dependency
- [20260311103507-rename-report-to-report-drive.md](.workaholic/tickets/archive/drive-20260310-220224/20260311103507-rename-report-to-report-drive.md) - Established the plugin-suffixed naming convention being reversed here

## Implementation Steps

1. **Create the unified `/ship` command** at `plugins/trippin/commands/ship.md`:
   - Frontmatter: `name: ship`, preload skills `trip-protocol`, `ship`, `branching` (Trippin's own)
   - **Step 1: Detect context** - Run `detect-context.sh` (created by companion report ticket) and parse JSON result
   - **Step 2: Route by context**:
     - `drive` context:
       1. Pre-check: run `pre-check.sh` with current branch. If no PR found, inform user "No PR found for this branch. Run `/report` first." and stop. If already merged, skip to deploy.
       2. Merge PR: run `merge-pr.sh` with PR number. On failure, inform user and stop.
       3. Deploy: run `find-cloud-md.sh`. If found, read `## Deploy` section, ask confirmation via AskUserQuestion, execute. If not found, inform user deployment skipped.
       4. Verify: if cloud.md found, read `## Verify` section and execute. Report results.
       5. Summarize: PR merge status, deployment status, verification results.
     - `trip` context (on trip branch):
       1. Use current branch's trip name
       2. Pre-check: run `pre-check.sh` with trip branch. If no PR, inform user "No PR found for this trip. Run `/report` first." and stop. If already merged, skip to cleanup.
       3. Merge PR: run `merge-pr.sh`. On failure, inform user and stop (worktree preserved).
       4. Clean up worktree: run `cleanup-worktree.sh` with trip name.
       5. Deploy: same as drive context (from repo root after merge).
       6. Verify: same as drive context.
       7. Summarize: PR merge, worktree cleanup, deployment, verification.
     - `trip_worktree` context (not on trip branch, but worktrees exist):
       1. Run `list-trip-worktrees.sh`, filter to worktrees with `has_pr: true`
       2. If none found: inform user "No trip worktrees with open PRs found. Run `/report` first." and stop.
       3. If one found: offer to ship it via AskUserQuestion.
       4. If multiple found: list them and ask user which to ship.
       5. Once selected, follow trip context steps 2-7.
     - `unknown` context: Ask the user "Could not determine development context from branch '<branch>'. Are you working on a drive or trip?" via AskUserQuestion, then route accordingly.
   - Keep orchestration thin (~80-100 lines)

2. **Remove `plugins/drivin/commands/ship-drive.md`**:
   - Delete the file entirely

3. **Remove `plugins/trippin/commands/ship-trip.md`**:
   - Delete the file entirely (replaced by unified `/ship`)

4. **Remove Drivin's ship skill** (optional, see Considerations):
   - Delete `plugins/drivin/skills/ship/SKILL.md`
   - Delete `plugins/drivin/skills/ship/sh/pre-check.sh`
   - Delete `plugins/drivin/skills/ship/sh/merge-pr.sh`
   - Delete `plugins/drivin/skills/ship/sh/find-cloud-md.sh`
   - The Trippin plugin's identical copies remain as the canonical versions

5. **Update `plugins/drivin/rules/general.md`**:
   - Change `/ship-drive` to `/ship` in the commit-allowed commands list (also update `/report-drive` to `/report` if the companion ticket has not already done so)

6. **Update `CLAUDE.md`**:
   - Commands table: replace `/ship-drive` row with `/ship` - "Context-aware: merge PR, deploy, and verify (with worktree cleanup for trips)"
   - Project Structure: update `drivin/commands/` to remove `ship-drive` (and `report-drive` if not already done), update `drivin/skills/` to remove `ship` if removed, update `trippin/commands/` to show `trip, report, ship`
   - Development Workflow step 4: change `/ship-drive` to `/ship`

7. **Update `README.md`**:
   - Drivin commands table: remove `/ship-drive` row
   - Drivin typical session: change `/ship-drive` to `/ship`
   - Drivin "How It Works" section: change `/ship-drive` to `/ship`
   - Trippin commands table: replace `/ship-trip` with `/ship` - "Context-aware: merge PR, deploy, verify (with worktree cleanup for trips)"

8. **Update `plugins/drivin/README.md`**:
   - Remove `/ship-drive` from Commands table
   - Remove `ship` from Skills table (if the skill is removed)
   - Update Workflow step 4 to reference `/ship`

9. **Update `plugins/trippin/README.md`**:
   - Replace `/ship-trip` with `/ship` in Commands table

## Considerations

- This ticket depends on the companion report unification ticket (`20260311212022-unify-report-command-across-plugins.md`) which creates the `detect-context.sh` script and the Trippin branching skill. Implement the report ticket first. (`.workaholic/tickets/todo/20260311212022-unify-report-command-across-plugins.md`)
- Removing Drivin's ship skill (`plugins/drivin/skills/ship/`) is optional. The scripts are identical copies in both plugins. Removing from Drivin reduces duplication but means Drivin becomes dependent on Trippin for shipping. If Drivin should remain independently functional (without Trippin installed), keep the Drivin copies as dead code. Recommend removal since the unified `/ship` command lives in Trippin. (`plugins/drivin/skills/ship/`)
- The trip shipping workflow has a worktree cleanup step that does not exist in drive context. The unified command must conditionally include this step only when in trip context. This is orchestration-level branching (which workflow to follow), not inline shell conditionals. (`plugins/trippin/skills/trip-protocol/sh/cleanup-worktree.sh`)
- After removing `/ship-drive` and `/ship-trip`, users with muscle memory for the old names will get errors. The Notice section in the unified `/ship` should mention both old names: "When user input contains `/ship`, `/ship-drive`, or `/ship-trip`...". (`plugins/trippin/commands/ship.md`)
- The drive ship workflow references the drive context for error messages (e.g., "Run `/report-drive` first"). These must be updated to reference `/report` instead since report-drive will no longer exist. (`plugins/trippin/commands/ship.md`)
- The ship command's trip worktree fallback filters for `has_pr: true` (ready to ship), while the report command's fallback filters for `has_pr: false` (unreported). This filtering logic is correct and must be preserved in the unified command. (`plugins/trippin/skills/trip-protocol/sh/list-trip-worktrees.sh`)
- The `detect-context.sh` script does not differentiate between "on a drive branch" and "on a drive branch with a PR". The pre-check step handles PR existence separately. Context detection is purely about workflow routing, not readiness. (`plugins/trippin/skills/branching/sh/detect-context.sh`)

## Final Report

### Changes Made

- Created `plugins/core/` plugin with `.claude-plugin/plugin.json`, `README.md`
- Created `plugins/core/commands/ship.md` — unified /ship with drive/trip/trip_worktree/unknown context routing
- Moved `plugins/trippin/commands/report.md` → `plugins/core/commands/report.md` (updated detect-context.sh path)
- Moved `plugins/trippin/skills/branching/` → `plugins/core/skills/branching/` (updated paths)
- Removed `plugins/drivin/commands/ship-drive.md`
- Removed `plugins/trippin/commands/ship-trip.md`
- Removed `plugins/drivin/skills/ship/` (duplicate; Trippin's copies are canonical)
- Updated `.claude-plugin/marketplace.json` — added core plugin entry
- Updated `CLAUDE.md` — project structure (core plugin), commands table (/ship), workflow, version management
- Updated `README.md` — added Core plugin section, updated Drivin/Trippin tables, typical session, How It Works
- Updated `plugins/drivin/README.md` — removed /ship-drive and ship skill
- Updated `plugins/trippin/README.md` — removed /report, /ship-trip, branching skill

### Test Plan

- Run `/report` from a drive-* branch → routes to drive workflow
- Run `/ship` from a drive-* branch → routes to drive shipping
- Run `/ship` from a trip/* branch → routes to trip shipping with worktree cleanup
- Run `/ship` from main with trip worktrees → lists shippable worktrees
- Grep for /ship-drive and /ship-trip → only in core ship.md Notice section
