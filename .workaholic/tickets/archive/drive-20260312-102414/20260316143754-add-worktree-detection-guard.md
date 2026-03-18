---
created_at: 2026-03-16T14:37:54+09:00
author: a@qmu.jp
type: enhancement
layer: [UX, Domain]
effort: 0.5h
commit_hash: 5d0700a
category: Added
---

# Add Worktree Detection Guard to /trip and /drive Commands

## Overview

When trip worktrees exist in the repository, the `/drive` and `/ticket` commands currently proceed without awareness of them, risking accidental development on the main/master branch or a drive branch when the user may intend to work inside an existing trip worktree. This enhancement adds a worktree detection guard that runs before these commands execute their primary process. If worktrees are found, the commands ask the user where to work first -- preventing accidental development in the wrong context.

The `/trip` command already has worktree resume-or-create logic (added in ticket 20260312010257). The `/report` and `/ship` commands already handle worktree context via `detect-context.sh`. The gap is in `/drive`, `/ticket`, and their underlying orchestration -- they have no worktree awareness at all.

## Key Files

- `plugins/drivin/commands/drive.md` - Drive command orchestration; no worktree detection before Phase 1
- `plugins/drivin/commands/ticket.md` - Ticket command orchestration; no worktree detection before invoking ticket-organizer
- `plugins/drivin/agents/ticket-organizer.md` - Ticket organizer subagent; Step 1 checks branch via drivin branching skill but has no worktree awareness
- `plugins/drivin/skills/branching/sh/check.sh` - Drivin branching check; only detects main/master vs topic branch, no worktree detection
- `plugins/core/skills/branching/sh/detect-context.sh` - Core branching detection; already detects `trip_worktree` context when trip worktrees exist
- `plugins/trippin/skills/trip-protocol/sh/list-trip-worktrees.sh` - Lists active trip worktrees with metadata; already used by /report, /ship, and /trip commands

## Related History

The worktree detection pattern has been progressively added across the codebase. The `list-trip-worktrees.sh` script was created for report-trip and ship-trip commands to discover worktrees when not on a trip branch. The core `detect-context.sh` was later added to unify context detection across the `/report` and `/ship` commands, including a `trip_worktree` context type. The `/trip` command received its own resume-or-create guard. However, the drivin plugin commands (`/drive` and `/ticket`) were never updated with worktree awareness, creating an asymmetry where some commands protect against accidental main-branch work and others do not.

Past tickets that touched similar areas:

- [20260312010257-trip-worktree-resume-or-create-prompt.md](.workaholic/tickets/archive/drive-20260312-102414/20260312010257-trip-worktree-resume-or-create-prompt.md) - Added resume-or-create prompt to /trip command using list-trip-worktrees.sh (same worktree detection pattern being extended here)
- [20260311193203-worktree-aware-report-ship-trip.md](.workaholic/tickets/archive/drive-20260311-125319/20260311193203-worktree-aware-report-ship-trip.md) - Added worktree discovery fallback to report-trip and ship-trip; created list-trip-worktrees.sh (same script reused here)
- [20260311212022-unify-report-command-across-plugins.md](.workaholic/tickets/archive/drive-20260311-125319/20260311212022-unify-report-command-across-plugins.md) - Created unified /report with detect-context.sh routing including trip_worktree context (established the context detection pattern)
- [20260311212023-unify-ship-command-across-plugins.md](.workaholic/tickets/archive/drive-20260311-125319/20260311212023-unify-ship-command-across-plugins.md) - Created unified /ship with detect-context.sh routing including trip_worktree context (same pattern)

## Implementation Steps

1. **Create a worktree guard shell script** at `plugins/core/skills/branching/sh/check-worktrees.sh`:
   - Run `git worktree list --porcelain` and count worktrees with branches matching `refs/heads/trip/`
   - Output JSON: `{"has_worktrees": true, "count": N}` or `{"has_worktrees": false, "count": 0}`
   - This is a lightweight version of `list-trip-worktrees.sh` that skips the `gh pr list` API calls (not needed for the guard -- we just need to know if worktrees exist, not their PR status)

2. **Add worktree guard step to `plugins/drivin/commands/drive.md`** before Phase 1:
   - Add a new "Phase 0: Worktree Guard" step that runs `check-worktrees.sh`
   - If `has_worktrees` is true: use `AskUserQuestion` with options:
     - "Continue here" - Proceed with drive on the current branch
     - "Switch to worktree" - Show worktree list (run `list-trip-worktrees.sh`) and let user pick one, then inform user to run `/drive` from the selected worktree
   - If `has_worktrees` is false: proceed silently to Phase 1

3. **Add worktree guard step to `plugins/drivin/commands/ticket.md`** before Step 1:
   - Add a "Step 0: Worktree Guard" that runs `check-worktrees.sh`
   - Same prompt pattern as drive: if worktrees exist, ask user whether to continue here or switch
   - If user chooses to continue: proceed to Step 1 (invoke ticket-organizer)
   - If user chooses to switch: show worktrees and inform user to run `/ticket` from the selected worktree

4. **Update `plugins/core/skills/branching/SKILL.md`** to document the new `check-worktrees.sh` script:
   - Add a "Worktree Guard" section describing the script, its output format, and intended usage by commands

## Patches

### `plugins/core/skills/branching/SKILL.md`

```diff
--- a/plugins/core/skills/branching/SKILL.md
+++ b/plugins/core/skills/branching/SKILL.md
@@ -31,3 +31,25 @@
 - **trip**: Route to Trippin workflows (artifact gathering, journey report, worktree cleanup)
 - **trip_worktree**: Not on a trip branch, but trip worktrees exist. List worktrees and let the user choose.
 - **unknown**: Cannot determine context. Ask the user which workflow to use.
+
+## Worktree Guard
+
+Lightweight check for the existence of trip worktrees. Used by commands that should warn the user before proceeding when worktrees are available.
+
+```bash
+bash ~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/branching/sh/check-worktrees.sh
+```
+
+### Output Format
+
+```json
+{
+  "has_worktrees": true,
+  "count": 2
+}
+```
+
+- `has_worktrees`: Boolean indicating if any trip worktrees exist
+- `count`: Number of trip worktrees found
+
+Unlike `list-trip-worktrees.sh`, this script does not query GitHub API for PR status. It is designed for fast, non-blocking guard checks.
```

### `plugins/drivin/commands/drive.md`

```diff
--- a/plugins/drivin/commands/drive.md
+++ b/plugins/drivin/commands/drive.md
@@ -17,6 +17,22 @@ Implement tickets from `.workaholic/tickets/todo/` using intelligent prioritizat

 ## Instructions

+### Phase 0: Worktree Guard
+
+Check if trip worktrees exist before proceeding:
+
+```bash
+bash ~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/branching/sh/check-worktrees.sh
+```
+
+If `has_worktrees` is `true`, present the user with a choice using `AskUserQuestion` with selectable options:
+- **"Continue here"** - Proceed with drive on the current branch
+- **"Switch to worktree"** - Run `bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/list-trip-worktrees.sh`, display the worktree list, and inform the user to navigate to the selected worktree to run `/drive` there
+
+If `has_worktrees` is `false`, proceed silently to Phase 1.
+
+**Rationale**: Prevents accidental development on a drive branch when trip worktrees with in-progress work may be the intended target.
+
 ### Phase 1: Navigate Tickets

 Invoke the drive-navigator subagent via Task tool:
```

### `plugins/drivin/commands/ticket.md`

```diff
--- a/plugins/drivin/commands/ticket.md
+++ b/plugins/drivin/commands/ticket.md
@@ -12,6 +12,22 @@ Thin alias for ticket-organizer subagent.

 ## Instructions

+### Step 0: Worktree Guard
+
+Check if trip worktrees exist before proceeding:
+
+```bash
+bash ~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/branching/sh/check-worktrees.sh
+```
+
+If `has_worktrees` is `true`, present the user with a choice using `AskUserQuestion` with selectable options:
+- **"Continue here"** - Proceed with ticket creation on the current branch
+- **"Switch to worktree"** - Run `bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/list-trip-worktrees.sh`, display the worktree list, and inform the user to navigate to the selected worktree to run `/ticket` there
+
+If `has_worktrees` is `false`, proceed silently to Step 1.
+
+**Rationale**: Prevents creating tickets on a drive branch when the user may intend to work within a trip worktree.
+
 ### Step 1: Invoke Ticket Organizer

 Invoke ticket-organizer subagent via Task tool:
```

## Considerations

- The `check-worktrees.sh` script should be a separate, lightweight script rather than reusing `list-trip-worktrees.sh` because the guard only needs a boolean answer and a count. The `list-trip-worktrees.sh` script makes one `gh pr list` API call per worktree, which adds latency that is unnecessary for the guard check. The full listing script is only needed if the user chooses "Switch to worktree". (`plugins/trippin/skills/trip-protocol/sh/list-trip-worktrees.sh` lines 25-26)
- The guard script belongs in `plugins/core/skills/branching/` (not `plugins/drivin/`) because it checks git worktree state, which is a core concern shared across plugins. The core branching skill already contains `detect-context.sh` which has similar worktree detection logic. (`plugins/core/skills/branching/sh/detect-context.sh` lines 34-46)
- The guard must not block the command -- it presents a choice with "Continue here" as the default-feeling option. Users who intentionally run `/drive` on a drive branch should not be slowed down significantly. The guard only fires when worktrees actually exist. (`plugins/drivin/commands/drive.md`)
- The `/ticket` command's ticket-organizer subagent also has its own branching check (Step 1 in `ticket-organizer.md`), but that check is about creating a new branch when on main/master. The worktree guard is a separate concern that runs before the subagent is invoked, at the command level. (`plugins/drivin/agents/ticket-organizer.md` lines 25-27)
- Following the Shell Script Principle from CLAUDE.md, the worktree detection logic (parsing `git worktree list --porcelain`, filtering for trip branches) must live in the shell script, not inline in the command markdown files. The commands only call the script and parse JSON. (`CLAUDE.md` Architecture Policy)
- The `/trip` command already has its own worktree detection as part of its resume-or-create flow in Step 1, so it does not need this guard. The user request mentions `/trip`, but the trip command's existing behavior already covers this scenario more comprehensively. (`plugins/trippin/commands/trip.md` lines 22-43)

## Final Report

### Changes

- Created `plugins/core/skills/branching/sh/check-worktrees.sh` - lightweight script parsing `git worktree list --porcelain` for trip branches, outputs `{has_worktrees, count}` JSON without GitHub API calls
- Added Phase 0: Worktree Guard to `plugins/drivin/commands/drive.md` before Phase 1
- Added Step 0: Worktree Guard to `plugins/drivin/commands/ticket.md` before Step 1
- Added Worktree Guard documentation section to `plugins/core/skills/branching/SKILL.md`

### Test Plan

- [x] `check-worktrees.sh` returns `{"has_worktrees": false, "count": 0}` when no trip worktrees exist
- [ ] With active trip worktrees, script returns `{"has_worktrees": true, "count": N}` with correct count
- [ ] `/drive` shows worktree prompt when trip worktrees exist, proceeds silently when none exist
- [ ] `/ticket` shows worktree prompt when trip worktrees exist, proceeds silently when none exist
