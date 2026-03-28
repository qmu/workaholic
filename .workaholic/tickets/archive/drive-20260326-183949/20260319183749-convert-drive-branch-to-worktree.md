---
created_at: 2026-03-19T18:37:49+09:00
author: a@qmu.jp
type: enhancement
layer: [UX, Domain, Config]
effort: 1h
commit_hash: 19f98e8
category: Added
---

# Convert Drive Branch to Worktree and Back

## Overview

When a user is on a `drive-*` branch and wants to isolate it into a git worktree (for example, to run a `/trip` session on top of it, or to work on a separate task in parallel while preserving the drive branch's state), there is no supported mechanism to do so. The existing worktree infrastructure is exclusively tied to the `/trip` command -- `ensure-worktree.sh` creates fresh worktrees with `trip/<name>` branches, and there is no path to adopt an existing branch into a worktree.

This ticket adds a worktree lifecycle skill with two operations: (1) **adopt** -- take an existing branch (e.g., `drive-20260320-xxx`) and create a worktree for it at `.worktrees/<name>/`, handling the case where the user is currently on that branch; and (2) **eject** -- from inside a worktree, collapse it back to a regular branch in the main working tree. The skill integrates with the existing worktree detection in `/drive`, `/ticket`, and `/report`/`/ship` commands so that adopted worktrees are discoverable alongside trip worktrees.

## Key Files

- `plugins/trippin/skills/trip-protocol/sh/ensure-worktree.sh` - Creates trip worktrees with new `trip/<name>` branches; the adopt operation differs because it uses an existing branch rather than creating a new one
- `plugins/trippin/skills/trip-protocol/sh/cleanup-worktree.sh` - Removes trip worktrees and their branches; the eject operation differs because it preserves the branch while removing the worktree
- `plugins/trippin/skills/trip-protocol/sh/list-trip-worktrees.sh` - Lists worktrees filtered to `trip/*` branches; needs extension or a sibling script to also discover non-trip worktrees (e.g., `drive-*` branches in worktrees)
- `plugins/core/skills/branching/sh/check-worktrees.sh` - Lightweight worktree existence check filtered to `trip/*` branches; needs extension to detect any project worktrees
- `plugins/core/skills/branching/sh/detect-context.sh` - Context detection routing; currently recognizes `drive`, `trip`, `trip_drive`, and `trip_worktree` contexts but has no awareness of drive branches in worktrees
- `plugins/drivin/commands/drive.md` - Drive command with Phase 0 worktree guard; currently only checks for trip worktrees
- `plugins/drivin/commands/ticket.md` - Ticket command with Step 0 worktree guard; same trip-only limitation
- `plugins/drivin/skills/branching/sh/check.sh` - Returns `on_main` boolean; no worktree awareness
- `plugins/drivin/skills/branching/sh/create.sh` - Creates timestamped topic branches; relevant because the adopt operation is the inverse (take an existing branch and move it to a worktree)
- `plugins/trippin/skills/trip-protocol/SKILL.md` - Worktree isolation protocol; documents the worktree lifecycle for trips
- `plugins/core/skills/branching/SKILL.md` - Core branching skill; documents context detection and worktree guard

## Related History

The worktree infrastructure was built incrementally for the trip workflow: worktree creation, cleanup, listing, dev environment validation, resume-or-create prompts, and worktree detection guards. The trip-drive cross-command compatibility ticket extended context detection so trip branches can transition to drive-style development. However, all worktree operations assume the worktree starts as a trip (new branch created by `ensure-worktree.sh`). The reverse scenario -- an existing drive branch being adopted into a worktree -- has no precedent in the codebase.

Past tickets that touched similar areas:

- [20260316143858-trip-drive-cross-command-compatibility.md](.workaholic/tickets/archive/drive-20260312-102414/20260316143858-trip-drive-cross-command-compatibility.md) - Added `trip_drive` hybrid context and cross-command compatibility (established the pattern of bridging drive and trip workflows)
- [20260316143754-add-worktree-detection-guard.md](.workaholic/tickets/archive/drive-20260312-102414/20260316143754-add-worktree-detection-guard.md) - Added worktree guards to `/drive` and `/ticket` commands with `check-worktrees.sh` (same guard scripts that need extension)
- [20260312010257-trip-worktree-resume-or-create-prompt.md](.workaholic/tickets/archive/drive-20260312-102414/20260312010257-trip-worktree-resume-or-create-prompt.md) - Added resume-or-create worktree prompt to `/trip` (established the worktree discovery UX pattern)
- [20260311193203-worktree-aware-report-ship-trip.md](.workaholic/tickets/archive/drive-20260311-125319/20260311193203-worktree-aware-report-ship-trip.md) - Created `list-trip-worktrees.sh` for worktree discovery (same listing infrastructure being extended)
- [20260311011813-dev-environment-readiness-in-trip-worktree.md](.workaholic/tickets/archive/drive-20260310-220224/20260311011813-dev-environment-readiness-in-trip-worktree.md) - Added dev environment validation for worktrees (same validation applies to adopted worktrees)

## Implementation Steps

1. **Create `adopt-worktree.sh` script** at `plugins/core/skills/branching/sh/adopt-worktree.sh`:
   - Accept one argument: the branch name to adopt (e.g., `drive-20260320-123456`)
   - Derive the worktree directory name from the branch name: `.worktrees/<branch-name>/`
   - Check prerequisites: verify the branch exists, verify no worktree already exists for this branch
   - Handle the "currently on this branch" case: if `git branch --show-current` matches the target branch, switch to `main` first (`git checkout main`), then create the worktree
   - Create the worktree using `git worktree add <path> <branch>` (note: no `-b` flag since the branch already exists, unlike `ensure-worktree.sh` which uses `-b` to create a new branch)
   - Output JSON: `{"worktree_path": "<absolute-path>", "branch": "<branch-name>", "switched_from": true|false}`
   - Error cases: branch not found, worktree already exists, working tree has uncommitted changes (cannot switch branches)

2. **Create `eject-worktree.sh` script** at `plugins/core/skills/branching/sh/eject-worktree.sh`:
   - Must be run from inside a worktree (not the main working tree)
   - Detect the current worktree path and branch via `git worktree list --porcelain`
   - Verify the user is inside a worktree (not the main working tree) by checking if the current directory's git common dir differs from its git dir
   - Switch the main working tree to the worktree's branch: from the main repo root, run `git checkout <branch>`
   - Remove the worktree: `git worktree remove <worktree-path>`
   - Prune stale entries: `git worktree prune`
   - Output JSON: `{"ejected": true, "branch": "<branch>", "main_repo": "<main-repo-path>"}`
   - Important: unlike `cleanup-worktree.sh`, this does NOT delete the branch -- it preserves it and checks it out in the main working tree

3. **Create `list-all-worktrees.sh` script** at `plugins/core/skills/branching/sh/list-all-worktrees.sh`:
   - Parse `git worktree list --porcelain` for all worktrees (not just `trip/*` branches)
   - For each non-main worktree, extract the branch name, path, and detect the type (`trip` if branch matches `trip/*`, `drive` if branch matches `drive-*`, `other` otherwise)
   - Output JSON with same structure as `list-trip-worktrees.sh` but including all worktree types:
     ```json
     {
       "count": 2,
       "worktrees": [
         {"name": "drive-20260320-123456", "branch": "drive-20260320-123456", "worktree_path": "/path/.worktrees/drive-20260320-123456", "type": "drive"},
         {"name": "trip-20260319-040153", "branch": "trip/trip-20260319-040153", "worktree_path": "/path/.worktrees/trip-20260319-040153", "type": "trip"}
       ]
     }
     ```
   - Skip the `gh pr list` API calls to keep it fast (like `check-worktrees.sh`); PR status can be queried separately when needed

4. **Update `check-worktrees.sh`** at `plugins/core/skills/branching/sh/check-worktrees.sh`:
   - Extend the branch filter from only `trip/*` to also include `drive-*` and other non-main branches in worktrees
   - Add a `types` field to the output: `{"has_worktrees": true, "count": 2, "trip_count": 1, "drive_count": 1}`
   - This allows the guard in `/drive` and `/ticket` to show more specific information

5. **Add worktree management section to core branching skill** at `plugins/core/skills/branching/SKILL.md`:
   - Document `adopt-worktree.sh`: usage, arguments, output format, error cases
   - Document `eject-worktree.sh`: usage, prerequisites (must be in a worktree), output format
   - Document `list-all-worktrees.sh`: usage, output format, comparison with `list-trip-worktrees.sh`
   - Explain when to use each: adopt for isolating existing branches, eject for returning to single-worktree workflow

6. **Update worktree guard in `/drive` and `/ticket`** to use the expanded worktree information:
   - The Phase 0 / Step 0 guards currently only check for trip worktrees
   - Update to use the extended `check-worktrees.sh` output so that drive worktrees are also shown
   - When the user selects "Switch to worktree", use `list-all-worktrees.sh` instead of `list-trip-worktrees.sh` to show all worktree types

7. **Decide on the user-facing mechanism**: The adopt and eject operations need a user-facing entry point. Options:
   - **Option A**: A new command `/worktree` that accepts subcommands (`/worktree adopt`, `/worktree eject`, `/worktree list`)
   - **Option B**: Extend the `/trip` command to accept a branch argument (`/trip drive-20260320-xxx` adopts the branch into a worktree and optionally launches a trip session)
   - **Option C**: A skill that other commands can invoke, with no dedicated command (users invoke via natural language: "convert this branch to a worktree")
   - Recommend **Option A** as the most explicit and discoverable approach. The command belongs in the core plugin since worktree management is not specific to either drivin or trippin

## Considerations

- When adopting a drive branch into a worktree, the user may be on that branch with uncommitted changes. The `adopt-worktree.sh` script must check for a clean working tree before switching to main. If there are uncommitted changes, it should abort with a clear error message rather than stashing (stashing is a destructive operation the user should control). (`plugins/core/skills/branching/sh/adopt-worktree.sh`)
- The `eject-worktree.sh` script must handle the case where the main working tree already has a different branch checked out. Switching to the ejected branch in the main tree may conflict with uncommitted changes there. The script should verify the main working tree is clean before proceeding. (`plugins/core/skills/branching/sh/eject-worktree.sh`)
- Git worktrees share the same `.git` directory. Two worktrees cannot have the same branch checked out simultaneously. The adopt script exploits this by first switching the main tree off the target branch, then creating a worktree on it. The eject script reverses this by removing the worktree first, then checking out the branch in the main tree. The ordering matters. (`plugins/core/skills/branching/sh/adopt-worktree.sh`, `plugins/core/skills/branching/sh/eject-worktree.sh`)
- The existing `list-trip-worktrees.sh` in the trippin plugin makes `gh pr list` API calls per worktree. The new `list-all-worktrees.sh` in the core plugin intentionally skips these calls for speed. If PR status is needed, callers can query it separately. This avoids coupling the core plugin to GitHub CLI availability. (`plugins/core/skills/branching/sh/list-all-worktrees.sh`)
- The `.worktrees/` directory is already in `.gitignore` (used by trip worktrees). Drive worktrees placed here follow the same convention. The naming uses the branch name directly (e.g., `.worktrees/drive-20260320-123456/`) rather than stripping the prefix, keeping it consistent and unambiguous. (`plugins/trippin/skills/trip-protocol/sh/ensure-worktree.sh` line 22)
- The `detect-context.sh` script does not currently account for being run from inside a worktree where the branch is `drive-*`. This already works correctly because it checks `git branch --show-current` which returns the worktree's branch regardless of whether it is a worktree or the main tree. No change needed to detect-context for basic operation. (`plugins/core/skills/branching/sh/detect-context.sh`)
- The reverse direction (eject) is primarily useful when a user no longer needs isolation and wants to return to working in the main repository directory. This is a convenience operation -- the user could also just `cd` to the main repo and checkout the branch manually after removing the worktree. Providing a script makes it safe and atomic. (`plugins/core/skills/branching/sh/eject-worktree.sh`)
- Dev environment validation (`validate-dev-env.sh`) should be recommended after adopting a branch into a worktree, similar to how it runs during trip worktree creation. The adopt script itself should not run validation (separation of concerns), but the calling command or skill should document this as a follow-up step. (`plugins/trippin/skills/trip-protocol/sh/validate-dev-env.sh`)

## Final Report

Development completed as planned.
