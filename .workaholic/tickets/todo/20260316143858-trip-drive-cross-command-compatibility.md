---
created_at: 2026-03-16T14:38:58+09:00
author: a@qmu.jp
type: enhancement
layer: [UX, Domain, Config]
effort:
commit_hash:
category:
---

# Design Trip-Drive Cross-Command Compatibility

## Overview

When a trip session completes its Coding Phase (walk 3), the resulting branch contains working code in an isolated worktree on a `trip/<name>` branch. Currently, there is no supported path to continue developing this branch using `/ticket` and `/drive` commands. The drive workflow assumes `drive-*` branch patterns, the context detection script routes `trip/*` branches exclusively to trip workflows, and the archive script creates archive directories named after the current branch which would create nested paths like `archive/trip/<name>/`. This ticket designs the compatibility layer so that trip-originated branches can seamlessly transition into drive-style iterative development.

## Key Files

- `plugins/core/skills/branching/sh/detect-context.sh` - Routes context by branch pattern; `trip/*` always maps to trip context, blocking drive commands from operating naturally
- `plugins/drivin/commands/drive.md` - Drive command orchestration; no awareness of trip branches or worktrees
- `plugins/drivin/commands/ticket.md` - Ticket command; invokes ticket-organizer which checks branch via drivin branching skill
- `plugins/drivin/agents/ticket-organizer.md` - Creates branches on main; has no logic for operating on an existing trip branch
- `plugins/drivin/skills/branching/sh/check.sh` - Returns `on_main: true/false` only; treats `trip/*` as a generic topic branch (not main), but drive commands may not recognize it as a valid work branch
- `plugins/drivin/skills/archive-ticket/sh/archive.sh` - Uses `git branch --show-current` for archive directory naming; a `trip/trip-20260316` branch creates `archive/trip/trip-20260316/` (nested subdirectory due to slash in branch name)
- `plugins/trippin/commands/trip.md` - Trip command orchestration; Step 5 presents results and shows the branch for merging or inspection, but does not mention transitioning to drive
- `plugins/trippin/skills/trip-protocol/SKILL.md` - Worktree isolation protocol; worktrees live at `.worktrees/<name>/` with branches `trip/<name>`
- `plugins/trippin/skills/trip-protocol/sh/ensure-worktree.sh` - Creates worktrees; branch naming: `trip/<trip-name>`
- `plugins/core/commands/report.md` - Unified report; routes `trip/*` branches to trip report workflow, not story-writer
- `plugins/core/commands/ship.md` - Unified ship; routes `trip/*` branches to trip shipping with worktree cleanup

## Related History

The trip and drive plugins were developed as independent workflows with their own branch naming conventions, commit formats, and lifecycle management. The unification of `/report` and `/ship` into the core plugin established branch-pattern-based context detection, but this detection is rigid -- a branch is either drive or trip, never both. The trip command's worktree resume-or-create prompt and the worktree detection guard ticket (currently in todo) address worktree awareness from the outside, but neither addresses the scenario of continuing drive-style development on a trip branch after the trip session concludes.

Past tickets that touched similar areas:

- [20260311212022-unify-report-command-across-plugins.md](.workaholic/tickets/archive/drive-20260311-125319/20260311212022-unify-report-command-across-plugins.md) - Created unified /report with detect-context.sh; established rigid branch-pattern routing (same routing being extended)
- [20260311212023-unify-ship-command-across-plugins.md](.workaholic/tickets/archive/drive-20260311-125319/20260311212023-unify-ship-command-across-plugins.md) - Created unified /ship with detect-context.sh; same rigid routing pattern
- [20260312010257-trip-worktree-resume-or-create-prompt.md](.workaholic/tickets/archive/drive-20260312-102414/20260312010257-trip-worktree-resume-or-create-prompt.md) - Added resume-or-create to /trip; established worktree lifecycle awareness
- [20260311193203-worktree-aware-report-ship-trip.md](.workaholic/tickets/archive/drive-20260311-125319/20260311193203-worktree-aware-report-ship-trip.md) - Added worktree discovery fallback to report and ship commands
- [20260131223900-standardize-branch-naming-prefixes.md](.workaholic/tickets/archive/drive-20260131-223656/20260131223900-standardize-branch-naming-prefixes.md) - Standardized branch naming prefixes; established drive-* and feat-* patterns

## Implementation Steps

1. **Extend `detect-context.sh` to support a hybrid context** at `plugins/core/skills/branching/sh/detect-context.sh`:
   - Add a new check: when on a `trip/*` branch, also check if `.workaholic/tickets/todo/` contains ticket files
   - If trip branch AND tickets exist in todo: output `{"context": "trip_drive", "branch": "<branch>", "trip_name": "<name>"}`
   - If trip branch AND no tickets: keep existing behavior, output trip context
   - This enables downstream commands to recognize that a trip branch has transitioned into drive-style development
   - Update the core branching SKILL.md to document the new `trip_drive` context type

2. **Update `plugins/core/commands/report.md`** to handle `trip_drive` context:
   - Add a `trip_drive` route that follows the drive report workflow (version bump + story-writer) rather than trip report workflow
   - The key difference: when on a `trip_drive` context, the branch has both trip artifacts AND drive tickets/archives, so the story-writer should capture the full narrative including the trip origin
   - Alternatively, offer the user a choice: "This branch started as a trip and has drive tickets. Generate a drive story or trip journey report?" via AskUserQuestion

3. **Update `plugins/core/commands/ship.md`** to handle `trip_drive` context:
   - Add a `trip_drive` route that follows the drive shipping workflow but also includes worktree cleanup
   - After PR merge, clean up the trip worktree if one exists for this branch

4. **Update `plugins/drivin/commands/drive.md`** to operate on trip branches:
   - In the instructions preamble or a new Phase 0, detect the branch pattern
   - If on a `trip/*` branch: proceed normally with ticket navigation and implementation (the drive workflow does not actually depend on branch naming -- it just reads from `.workaholic/tickets/todo/`)
   - The drive command already works on any topic branch (non-main); the `trip/*` pattern passes the branching check as a non-main branch
   - Add a note in the command that drive is compatible with trip branches

5. **Update `plugins/drivin/commands/ticket.md` and `plugins/drivin/agents/ticket-organizer.md`** for trip branch awareness:
   - The ticket-organizer's Step 1 (Check Branch) uses the branching skill which returns `on_main: false` for trip branches -- this is correct, it would not try to create a new branch
   - Add documentation noting that ticket creation works on trip branches (tickets go to `.workaholic/tickets/todo/` regardless of branch type)
   - If running inside a trip worktree, tickets should be created in the worktree's `.workaholic/tickets/todo/`, not the main repo's

6. **Handle archive directory naming for trip branches** in `plugins/drivin/skills/archive-ticket/sh/archive.sh`:
   - The current script uses `BRANCH=$(git branch --show-current)` which for `trip/my-feature` creates `archive/trip/my-feature/` (a nested directory due to the `/` in the branch name)
   - Option A: Sanitize the branch name by replacing `/` with `-`, creating `archive/trip-my-feature/`
   - Option B: Accept the nested directory as-is (it works with `mkdir -p` which is already used)
   - Recommend Option A for consistency with existing `archive/drive-*` flat naming convention

7. **Update trip command's Step 5 (Present Results)** in `plugins/trippin/commands/trip.md`:
   - After presenting results, add guidance: "To continue developing this branch with drive-style tickets, create tickets with `/ticket` and implement them with `/drive` from this worktree."
   - This makes the transition path discoverable

8. **Update README.md and CLAUDE.md** to document the cross-command workflow:
   - Add a section or note explaining that trip branches can transition to drive-style development
   - Example workflow: `/trip` -> coding phase completes -> `/ticket` to add refinements -> `/drive` to implement -> `/report` -> `/ship`

## Considerations

- The slash in `trip/<name>` branch names creates nested directories when used as archive paths. The `mkdir -p` in `archive.sh` handles this, but it breaks the flat `archive/<branch>/` convention that exists for all `drive-*` branches. Sanitizing to `trip-<name>` is cleaner but means the archive directory name no longer matches the actual branch name, which could confuse the `discover-history` search. (`plugins/drivin/skills/archive-ticket/sh/archive.sh` lines 25-34)
- The `detect-context.sh` change introduces state-dependent context detection (checking for ticket files). This makes the context non-deterministic based solely on branch name, which is a departure from the current pure-pattern-based approach. An alternative is to let the user explicitly specify context via a flag or prompt, but this adds friction. (`plugins/core/skills/branching/sh/detect-context.sh`)
- When running `/drive` inside a trip worktree, the worktree has its own `.workaholic/tickets/` directory (created by trip initialization). Tickets created and archived here stay within the worktree's git history, which is correct since the worktree is a full git checkout on its own branch. After shipping, the trip branch merges into main and the tickets become part of main's history. (`plugins/trippin/skills/trip-protocol/SKILL.md`)
- The trip report workflow gathers agent artifacts from `.workaholic/.trips/<name>/`. The drive story-writer generates stories from ticket archives. A `trip_drive` hybrid report might want to include both: the trip's planning artifacts AND the drive's ticket implementation history. This is a UX design decision that warrants user input. (`plugins/core/commands/report.md`)
- The todo ticket `20260316143754-add-worktree-detection-guard.md` adds a guard to `/drive` and `/ticket` that warns when worktrees exist. This guard complements the cross-command compatibility: the guard asks "are you sure you want to work here?", while this ticket ensures "working here actually works correctly". Both tickets can be implemented independently. (`.workaholic/tickets/todo/20260316143754-add-worktree-detection-guard.md`)
- The `/trip` command's Coding Phase produces commits via `trip-commit.sh` with `[Agent]` prefixed messages. After transitioning to `/drive`, commits use the standard `commit.sh` format. This mix of commit styles on the same branch is acceptable -- the story-writer already reads commit messages generically, and the trip artifacts provide their own narrative. (`plugins/drivin/skills/commit/sh/commit.sh`, `plugins/trippin/skills/trip-protocol/sh/trip-commit.sh`)
