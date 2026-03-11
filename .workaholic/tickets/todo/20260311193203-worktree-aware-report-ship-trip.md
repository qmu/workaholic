---
created_at: 2026-03-11T19:32:03+09:00
author: a@qmu.jp
type: enhancement
layer: [UX, Config]
effort:
commit_hash:
category:
---

# Worktree-Aware Branch Detection for report-trip and ship-trip

## Overview

When `/report-trip` or `/ship-trip` is run from a non-trip branch (e.g. a `drive-*` branch or `main`), both commands currently fail immediately with a message that the branch must start with `trip/`. However, the user may have active trip worktrees available. Instead of failing, the commands should detect existing trip worktrees via `git worktree list`, present them to the user, and offer to operate on the selected worktree. If only one unreported trip worktree exists, the command should offer to use it directly.

The fix involves creating a new shell script in the trip-protocol skill that lists active trip worktrees with their metadata, then updating both commands to call this script as a fallback when the current branch is not a trip branch.

## Key Files

- `plugins/trippin/commands/report-trip.md` - Report command; Step 1 currently fails if branch is not `trip/`
- `plugins/trippin/commands/ship-trip.md` - Ship command; Step 1 currently fails if branch is not `trip/` and no argument provided
- `plugins/trippin/skills/trip-protocol/SKILL.md` - Worktree isolation conventions; worktrees live at `.worktrees/<trip-name>/` with branches `trip/<trip-name>`
- `plugins/trippin/skills/trip-protocol/sh/ensure-worktree.sh` - Creates worktrees; reference for path and branch naming conventions
- `plugins/trippin/skills/trip-protocol/sh/cleanup-worktree.sh` - Removes worktrees; reference for worktree discovery patterns
- `plugins/trippin/skills/ship/sh/pre-check.sh` - PR pre-check script; used by ship-trip to detect if a PR exists (useful for filtering unreported worktrees)

## Related History

The report-trip and ship-trip commands were recently created as part of the Trippin plugin buildout. Both commands assume they are run from a trip branch, which is the natural flow when working inside a worktree. However, worktree-based workflows often involve the user being in the main repository while trip worktrees exist in `.worktrees/`. This gap between the worktree-based architecture and the branch-detection logic creates a usability issue.

Past tickets that touched similar areas:

- [20260311103508-add-report-trip-command.md](.workaholic/tickets/archive/drive-20260310-220224/20260311103508-add-report-trip-command.md) - Created report-trip with branch-based trip detection (same command being enhanced)
- [20260311105614-add-ship-trip-command.md](.workaholic/tickets/archive/drive-20260310-220224/20260311105614-add-ship-trip-command.md) - Created ship-trip with branch-based trip detection (same command being enhanced)
- [20260311011813-dev-environment-readiness-in-trip-worktree.md](.workaholic/tickets/archive/drive-20260310-220224/20260311011813-dev-environment-readiness-in-trip-worktree.md) - Added worktree validation infrastructure to trip-protocol (same skill being extended)
- [20260311121300-extract-shared-ship-scripts.md](.workaholic/tickets/archive/drive-20260310-220224/20260311121300-extract-shared-ship-scripts.md) - Established Trippin's own ship skill with pre-check.sh (used for PR status detection)

## Implementation Steps

1. **Create `list-trip-worktrees.sh` script** at `plugins/trippin/skills/trip-protocol/sh/list-trip-worktrees.sh`:
   - Run `git worktree list --porcelain` and filter for worktrees whose branch matches `refs/heads/trip/`
   - For each trip worktree, extract the trip name from the branch, the worktree path, and the HEAD commit
   - Check if each trip branch has an existing PR (call `gh pr list --head "trip/<name>" --state open --json number,url --jq '.[0]'` for each)
   - Output structured JSON:
     ```json
     {
       "count": 2,
       "worktrees": [
         {
           "trip_name": "auth-flow",
           "branch": "trip/auth-flow",
           "worktree_path": "/path/to/.worktrees/auth-flow",
           "has_pr": false
         },
         {
           "trip_name": "dashboard",
           "branch": "trip/dashboard",
           "worktree_path": "/path/to/.worktrees/dashboard",
           "has_pr": true,
           "pr_number": 42,
           "pr_url": "https://github.com/owner/repo/pull/42"
         }
       ]
     }
     ```
   - If no trip worktrees found, output `{"count": 0, "worktrees": []}`

2. **Update `report-trip.md` Step 1** to add worktree fallback:
   - Keep the existing flow: if on a `trip/` branch, use it directly
   - If not on a `trip/` branch and no `$ARGUMENT` provided, run `list-trip-worktrees.sh` instead of failing
   - Filter the worktree list to those without a PR (`has_pr: false`) since those are the ones that need reporting
   - If zero trip worktrees found: inform the user and stop (no trips to report on)
   - If exactly one unreported trip worktree found: offer to use it directly ("Found trip worktree '<name>'. Generate report for this trip?")
   - If multiple unreported trip worktrees found: list them and ask the user which one to report on
   - Once the user selects a trip, use its `trip_name` and `branch` to proceed with the existing Step 2 workflow
   - The trip directory lookup (`.workaholic/.trips/<trip-name>/`) should check inside the worktree path, not the current working directory, since artifacts live in the worktree

3. **Update `ship-trip.md` Step 1** to add worktree fallback:
   - Keep the existing flow: if on a `trip/` branch or `$ARGUMENT` provided, use it directly
   - If not on a `trip/` branch and no argument, run `list-trip-worktrees.sh` instead of failing
   - Filter to worktrees that have a PR (`has_pr: true`) since those are ready to ship
   - Apply the same selection logic: zero found = stop, one found = offer directly, multiple = ask user
   - Once selected, use the trip name to proceed with the existing Step 2 workflow

4. **Update `trip-protocol/SKILL.md`** to document the list-trip-worktrees script:
   - Add a subsection under Worktree Isolation describing the script and its output format
   - Reference: `bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/list-trip-worktrees.sh`

## Patches

### `plugins/trippin/commands/report-trip.md`

```diff
--- a/plugins/trippin/commands/report-trip.md
+++ b/plugins/trippin/commands/report-trip.md
@@ -22,7 +22,24 @@
 branch=$(git branch --show-current)
 ```

-If the branch does not start with `trip/`, inform the user and stop. The report-trip command must run from a trip branch.
+If the branch does not start with `trip/` and no argument was provided, check for available trip worktrees:
+
+```bash
+bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/list-trip-worktrees.sh
+```
+
+Parse the JSON output and filter to worktrees where `has_pr` is `false` (unreported trips):
+
+- If no trip worktrees found: inform the user "No active trip worktrees found. Run `/trip` to start a new trip session." and stop.
+- If exactly one unreported trip worktree found: ask the user "Found trip '<trip_name>'. Generate report for this trip?" using AskUserQuestion. If confirmed, use its `trip_name` and `branch`.
+- If multiple unreported trip worktrees found: list them and ask the user which one to report on using AskUserQuestion.
+
+When operating on a worktree trip (not the current branch), locate the trip directory at `<worktree_path>/.workaholic/.trips/<trip-name>/` rather than the current working directory.

 Locate the trip directory at `.workaholic/.trips/<trip-name>/`. If it does not exist, inform the user and stop.
```

### `plugins/trippin/commands/ship-trip.md`

```diff
--- a/plugins/trippin/commands/ship-trip.md
+++ b/plugins/trippin/commands/ship-trip.md
@@ -24,7 +24,22 @@
 git branch --show-current
 ```

-If the branch does not start with `trip/` and no argument was provided, inform the user and stop. The ship-trip command requires a trip name.
+If the branch does not start with `trip/` and no argument was provided, check for available trip worktrees:
+
+```bash
+bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/list-trip-worktrees.sh
+```
+
+Parse the JSON output and filter to worktrees where `has_pr` is `true` (trips with PRs ready to ship):
+
+- If no shippable trip worktrees found: inform the user "No trip worktrees with open PRs found. Run `/report-trip` first to create a PR." and stop.
+- If exactly one shippable trip worktree found: ask the user "Found trip '<trip_name>' with PR #<number>. Ship this trip?" using AskUserQuestion. If confirmed, use its `trip_name`.
+- If multiple shippable trip worktrees found: list them with PR numbers and ask the user which one to ship using AskUserQuestion.

 ### Step 2: Pre-check
```

## Considerations

- The `list-trip-worktrees.sh` script must follow the Shell Script Principle: all conditional logic and `git worktree list` parsing resides in the script, not inline in the command markdown files. The commands only call the script and parse JSON output. (`CLAUDE.md` Architecture Policy)
- The `gh pr list` calls inside `list-trip-worktrees.sh` will make one API call per trip worktree. If many worktrees exist, this could be slow. Consider batching or accepting the latency since users typically have 1-3 concurrent trips. (`plugins/trippin/skills/trip-protocol/sh/list-trip-worktrees.sh`)
- When operating on a trip from a non-trip branch, the report-trip command must locate artifacts inside the worktree path (`<worktree_path>/.workaholic/.trips/<trip-name>/`), not in the current working directory. The `gather-artifacts.sh` script currently uses a relative path for `trip_path`, so it must be run from within the worktree or the path must be adjusted. (`plugins/trippin/skills/write-trip-report/sh/gather-artifacts.sh` line 16)
- The report-trip command needs to generate the report file and commit it on the trip branch, not the current branch. When operating from a non-trip branch, git operations (add, commit, push) should target the trip worktree. This may require `cd <worktree_path>` before running git commands. (`plugins/trippin/commands/report-trip.md` lines 55-59)
- The ship-trip command's worktree cleanup step already handles the worktree path correctly via `cleanup-worktree.sh`, so operating from a non-trip branch should not affect Steps 3-7. (`plugins/trippin/skills/trip-protocol/sh/cleanup-worktree.sh`)
- Both commands already accept `$ARGUMENT` as an explicit trip name. The worktree discovery is only the fallback when no argument is provided and the current branch is not a trip branch. This preserves backward compatibility. (`plugins/trippin/commands/report-trip.md` line 19, `plugins/trippin/commands/ship-trip.md` line 20)
