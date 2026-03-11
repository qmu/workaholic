---
created_at: 2026-03-11T21:20:22+09:00
author: a@qmu.jp
type: refactoring
layer: [UX, Config]
effort:
commit_hash:
category:
---

# Unify Report Command Across Drivin and Trippin Plugins

## Overview

Merge the separate `/report-drive` (Drivin) and `/report-trip` (Trippin) commands into a single context-aware `/report` command in the Trippin plugin. The unified command auto-detects the development context from the current branch pattern (`drive-*` vs `trip/*`) and delegates to the appropriate workflow. This eliminates the need for users to remember which report variant to invoke and positions Trippin as the core plugin for shared commands.

## Key Files

- `plugins/drivin/commands/report-drive.md` - Drive report command to be absorbed and removed
- `plugins/trippin/commands/report-trip.md` - Trip report command to be replaced by unified `/report`
- `plugins/drivin/agents/story-writer.md` - Story-writer subagent invoked by drive reporting workflow
- `plugins/drivin/skills/branching/sh/check.sh` - Existing branch detection script (returns `on_main` and `branch`)
- `plugins/drivin/skills/branching/sh/check-version-bump.sh` - Version bump check used by drive report workflow
- `plugins/trippin/skills/write-trip-report/SKILL.md` - Trip report generation skill
- `plugins/trippin/skills/write-trip-report/sh/gather-artifacts.sh` - Trip artifact gathering script
- `plugins/trippin/skills/trip-protocol/sh/list-trip-worktrees.sh` - Worktree discovery fallback for trip context
- `plugins/drivin/rules/general.md` - References `/report-drive` in commit-allowed commands
- `CLAUDE.md` - Commands table, project structure, development workflow
- `README.md` - Command tables for both plugins
- `plugins/drivin/README.md` - Drivin commands table and workflow
- `plugins/trippin/README.md` - Trippin commands table

## Related History

The report commands have been through multiple naming iterations. The original `/report` was renamed to `/report-drive` specifically to make room for `/report-trip` in Trippin, establishing a plugin-suffixed naming convention. Both commands were then enhanced with worktree-aware fallback logic. This ticket reverses the split by creating a unified `/report` that subsumes both variants, using branch pattern detection rather than separate command names.

Past tickets that touched similar areas:

- [20260311193203-worktree-aware-report-ship-trip.md](.workaholic/tickets/archive/drive-20260311-125319/20260311193203-worktree-aware-report-ship-trip.md) - Added worktree fallback to report-trip and ship-trip (preserve this logic in unified command)
- [20260311103507-rename-report-to-report-drive.md](.workaholic/tickets/archive/drive-20260310-220224/20260311103507-rename-report-to-report-drive.md) - Renamed /report to /report-drive; this ticket reverses that split
- [20260311103508-add-report-trip-command.md](.workaholic/tickets/archive/drive-20260310-220224/20260311103508-add-report-trip-command.md) - Created /report-trip with agent-based report structure
- [20260311105613-add-ship-drive-command.md](.workaholic/tickets/archive/drive-20260310-220224/20260311105613-add-ship-drive-command.md) - Established the ship skill and cloud.md convention
- [20260311121300-extract-shared-ship-scripts.md](.workaholic/tickets/archive/drive-20260310-220224/20260311121300-extract-shared-ship-scripts.md) - Extracted shared ship scripts to Trippin (same de-duplication motivation)

## Implementation Steps

1. **Create a context detection shell script** at `plugins/trippin/skills/branching/sh/detect-context.sh`:
   - Read the current branch name via `git branch --show-current`
   - If branch matches `drive-*` pattern: output `{"context": "drive", "branch": "<branch>"}`
   - If branch matches `trip/*` pattern: output `{"context": "trip", "branch": "<branch>", "trip_name": "<name>"}`
   - If branch matches `main` or `master`: output `{"context": "unknown", "branch": "<branch>"}`
   - Otherwise: check for trip worktrees via `list-trip-worktrees.sh`; if any exist output `{"context": "trip_worktree", "branch": "<branch>"}`, else output `{"context": "unknown", "branch": "<branch>"}`
   - This script consolidates the branch detection logic currently scattered across both commands

2. **Create a branching skill in Trippin** at `plugins/trippin/skills/branching/SKILL.md`:
   - Document the `detect-context.sh` script
   - Reference: `bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/branching/sh/detect-context.sh`
   - Output format documentation with all context types

3. **Create the unified `/report` command** at `plugins/trippin/commands/report.md`:
   - Frontmatter: `name: report`, preload skills `trip-protocol`, `write-trip-report`, `branching` (Trippin's own)
   - **Step 1: Detect context** - Run `detect-context.sh` and parse JSON result
   - **Step 2: Route by context**:
     - `drive` context: Bump version (check with Drivin's `check-version-bump.sh`, skip if already bumped), then invoke `story-writer` subagent (`subagent_type: "drivin:story-writer"`, `model: "opus"`), display PR URL
     - `trip` context: Follow existing report-trip Steps 2-6 (gather artifacts, generate report, commit/push, create PR, return URL)
     - `trip_worktree` context: Run `list-trip-worktrees.sh`, filter to unreported trips (`has_pr: false`), present selection to user via AskUserQuestion, then follow trip workflow for selected trip
     - `unknown` context: Ask the user "Could not determine development context from branch '<branch>'. Are you working on a drive or trip?" via AskUserQuestion, then route accordingly
   - Keep orchestration thin (~60-80 lines), delegating to skills and subagents

4. **Remove `plugins/drivin/commands/report-drive.md`**:
   - Delete the file entirely (its functionality is now in the unified `/report`)

5. **Remove `plugins/trippin/commands/report-trip.md`**:
   - Delete the file entirely (replaced by the unified `/report`)

6. **Update `plugins/drivin/rules/general.md`**:
   - Change `/report-drive` to `/report` in the commit-allowed commands list

7. **Update `CLAUDE.md`**:
   - Commands table: replace `/report-drive` row with `/report` - "Context-aware: generate story (drive) or journey report (trip) and create PR"
   - Remove `/ship-drive` from Commands table (handled by companion ticket)
   - Project Structure: update `drivin/commands/` to remove `report-drive`, update `trippin/commands/` to show `trip, report, ship-trip` (ship-trip becomes `/ship` in companion ticket)
   - Development Workflow step 3: change `/report-drive` to `/report`

8. **Update `README.md`**:
   - Drivin commands table: remove `/report-drive` row
   - Drivin typical session: change `/report-drive` to `/report`
   - Drivin "How It Works" section: change `/report-drive` to `/report`
   - Trippin commands table: replace `/report-trip` with `/report` - "Context-aware report generation and PR creation"

9. **Update `plugins/drivin/README.md`**:
   - Remove `/report-drive` from Commands table
   - Update Workflow step 3 to reference `/report`

10. **Update `plugins/trippin/README.md`**:
    - Replace `/report-trip` with `/report` in Commands table
    - Add `branching` to Skills table

## Considerations

- The unified command lives in Trippin but invokes a Drivin subagent (`drivin:story-writer`) for drive context. This cross-plugin invocation is already an established pattern (Trippin previously referenced Drivin ship scripts before extraction). (`plugins/trippin/commands/report.md`)
- The drive report workflow includes a version bump step that is Drivin-specific. The unified command must conditionally run `check-version-bump.sh` only in drive context. This conditional logic should be expressed in the command orchestration (which context to route to), not in inline shell. (`plugins/drivin/skills/branching/sh/check-version-bump.sh`)
- The `detect-context.sh` script needs access to `list-trip-worktrees.sh` for the worktree fallback case. Since both scripts are in Trippin skills, this is a same-plugin dependency. The detect script should call list-trip-worktrees using its absolute path. (`plugins/trippin/skills/trip-protocol/sh/list-trip-worktrees.sh`)
- After removing `/report-drive` from Drivin, users who have muscle memory for the old command name will get an "unknown command" error. The Notice section in the unified `/report` should mention both old names for discoverability. (`plugins/trippin/commands/report.md`)
- The trip report workflow has worktree-aware path resolution (operating from a worktree path vs current directory). This logic from the existing `report-trip.md` must be preserved verbatim in the unified command's trip branch. (`plugins/trippin/commands/report-trip.md` lines 40-42)
- Cross-reference: The companion ticket `20260311212023-unify-ship-command-across-plugins.md` performs the same unification for `/ship`. Implement this ticket first since `/report` is the prerequisite step in both workflows. (`.workaholic/tickets/todo/20260311212023-unify-ship-command-across-plugins.md`)
