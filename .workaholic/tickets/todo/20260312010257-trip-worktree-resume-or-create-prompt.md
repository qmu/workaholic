---
created_at: 2026-03-12T01:02:57+09:00
author: a@qmu.jp
type: enhancement
layer: [UX, Domain]
effort:
commit_hash:
category:
---

# Prompt to Resume or Create Worktree When Starting Trip

## Overview

When a user runs `/trip` and trip worktrees already exist in the repository, the command currently creates a new worktree unconditionally. This ignores potentially active trip sessions the user may want to resume. The enhancement adds a detection step before worktree creation: if existing trip worktrees are found, present the user with a choice to either resume one of the existing worktrees or create a new one. This prevents worktree proliferation and makes it easy to return to an interrupted trip session.

## Key Files

- `plugins/trippin/commands/trip.md` - Trip command orchestration; Step 1 currently creates a new worktree without checking for existing ones
- `plugins/trippin/skills/trip-protocol/sh/list-trip-worktrees.sh` - Already lists active trip worktrees with metadata (branch, path, PR status); can be reused directly
- `plugins/trippin/skills/trip-protocol/sh/ensure-worktree.sh` - Creates new worktrees; called by trip.md Step 1; will remain the path for new worktree creation
- `plugins/trippin/skills/trip-protocol/SKILL.md` - Protocol skill documenting worktree isolation; should mention the resume-or-create flow

## Related History

The trip command's worktree management has been incrementally enhanced since its initial implementation. The `list-trip-worktrees.sh` script was added for `report-trip` and `ship-trip` commands to discover worktrees when not on a trip branch. The same script can be leveraged here. Dev environment validation was also added as a step between worktree creation and Agent Teams launch. The resume-or-create prompt fits naturally into the existing Step 1 flow before worktree creation.

Past tickets that touched similar areas:

- [20260311193203-worktree-aware-report-ship-trip.md](.workaholic/tickets/archive/drive-20260311-125319/20260311193203-worktree-aware-report-ship-trip.md) - Added worktree discovery fallback to report-trip and ship-trip; created list-trip-worktrees.sh (same script reused here)
- [20260311011813-dev-environment-readiness-in-trip-worktree.md](.workaholic/tickets/archive/drive-20260310-220224/20260311011813-dev-environment-readiness-in-trip-worktree.md) - Added dev environment validation step to trip command (same command being modified; Step 3 was inserted between init and Agent Teams)
- [20260309214650-implement-trip-command.md](.workaholic/tickets/archive/drive-20260302-213941/20260309214650-implement-trip-command.md) - Initial implementation of trip command with ensure-worktree.sh (direct predecessor; established the worktree creation flow being enhanced)

## Implementation Steps

1. **Modify `plugins/trippin/commands/trip.md` Step 1** to add worktree detection before creation:
   - Before generating the trip name and calling `ensure-worktree.sh`, run `list-trip-worktrees.sh` to check for existing trip worktrees
   - If zero worktrees found (`count` is 0): proceed with the existing flow (generate trip name, create worktree) without any prompt
   - If one or more worktrees found: present the user with a choice using AskUserQuestion:
     - List each existing worktree with its trip name and branch
     - Include an option to create a new trip session
     - If the user chooses an existing worktree: use its `worktree_path`, `branch`, and `trip_name` from the JSON output; skip the `ensure-worktree.sh` call and proceed to Step 2 (Initialize Trip Artifacts) only if the trip artifacts directory does not already exist, otherwise skip directly to Step 3 (Validate and Prepare Dev Environment)
     - If the user chooses to create a new trip: continue with the existing flow (generate trip name, call `ensure-worktree.sh`)

2. **Update the Step 2 (Initialize Trip Artifacts) conditional logic** in `plugins/trippin/commands/trip.md`:
   - When resuming an existing worktree, check if `.workaholic/.trips/<trip-name>/` already exists inside the worktree
   - If it exists: skip initialization and proceed to Step 3
   - If it does not exist (worktree was created but artifacts were never initialized): run `init-trip.sh` as usual

3. **Update `plugins/trippin/skills/trip-protocol/SKILL.md` Worktree Isolation section** to document the resume-or-create behavior:
   - Add a note that the trip command detects existing worktrees before creating a new one
   - Describe the user prompt flow: list existing worktrees, offer resume or create new

## Patches

### `plugins/trippin/commands/trip.md`

```diff
--- a/plugins/trippin/commands/trip.md
+++ b/plugins/trippin/commands/trip.md
@@ -18,7 +18,30 @@

 ### Step 1: Create Worktree

-Generate a trip name and create an isolated worktree:
+First, check for existing trip worktrees:
+
+```bash
+bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/list-trip-worktrees.sh
+```
+
+Parse the JSON output. If `count` is greater than 0, present the user with a choice:
+
+- List each existing worktree: "Active trips: <trip_name> (branch: <branch>)" for each entry
+- Offer an option to create a new trip session
+- Ask the user: "Would you like to resume an existing trip or start a new one?"
+
+**If the user chooses to resume an existing worktree:**
+- Use the selected worktree's `worktree_path`, `branch`, and `trip_name`
+- Skip the `ensure-worktree.sh` call
+- Check if `.workaholic/.trips/<trip_name>/` exists inside the worktree:
+  - If it exists: skip Step 2 (Initialize Trip Artifacts) and proceed to Step 3 (Validate and Prepare Dev Environment)
+  - If it does not exist: proceed to Step 2 to initialize artifacts
+
+**If the user chooses to create a new trip (or no worktrees exist):**
+
+Generate a trip name and create an isolated worktree:

 ```bash
 bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/ensure-worktree.sh "trip-$(date +%Y%m%d-%H%M%S)"
```

### `plugins/trippin/skills/trip-protocol/SKILL.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/skills/trip-protocol/SKILL.md
+++ b/plugins/trippin/skills/trip-protocol/SKILL.md
@@ -83,6 +83,14 @@

 All agent work happens inside the worktree directory. After completion, the user can merge the trip branch or inspect changes independently.

+### Resume or Create
+
+Before creating a new worktree, the trip command checks for existing trip worktrees using `list-trip-worktrees.sh`. If active worktrees are found, the user is prompted to either resume an existing trip or create a new one. This prevents worktree proliferation and allows returning to interrupted sessions.
+
+When resuming, the existing worktree path and branch are reused. Trip artifact initialization (Step 2) is skipped if the artifacts directory already exists inside the worktree.
+
 ### Listing Trip Worktrees

 To discover active trip worktrees with their metadata (branch, path, PR status):
```

## Considerations

- The `list-trip-worktrees.sh` script makes one `gh pr list` API call per worktree. For the resume prompt, PR status is informational (showing which trips have PRs already), but if the API call is slow it may delay the prompt. Consider whether the PR metadata is necessary for the resume prompt or if a lighter-weight version could be used. (`plugins/trippin/skills/trip-protocol/sh/list-trip-worktrees.sh` lines 25-26)
- When resuming a worktree, the user's `$ARGUMENT` (trip instruction) may differ from the original trip's purpose. The Agent Teams launch in Step 4 will use the new `$ARGUMENT`, which could cause confusion if the resumed trip's existing artifacts reflect a different instruction. The prompt should make clear that the user is continuing the existing trip's work, not starting a different task in the same worktree. (`plugins/trippin/commands/trip.md` Step 4)
- The `ensure-worktree.sh` script currently errors if a worktree already exists, which is the correct behavior since the resume path bypasses this script entirely. No changes are needed to `ensure-worktree.sh`. (`plugins/trippin/skills/trip-protocol/sh/ensure-worktree.sh` line 24)
- The worktree detection must follow the Shell Script Principle: the conditional logic (checking count, filtering worktrees) is handled by the already-existing `list-trip-worktrees.sh` script, while the trip command only parses JSON output and presents the choice. No new shell script is needed. (`CLAUDE.md` Architecture Policy)
- Step 3 (Validate and Prepare Dev Environment) should still run when resuming a worktree, as the environment may have changed since the last session (e.g., ports now in use by another worktree, dependencies updated). (`plugins/trippin/commands/trip.md` Step 3)
