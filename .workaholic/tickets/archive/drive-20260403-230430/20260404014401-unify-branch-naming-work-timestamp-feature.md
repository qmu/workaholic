---
created_at: 2026-04-04T01:44:01+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 0.5h
commit_hash: 19dcfc3
category: Changed
---

# Unify branch naming to work-timestamp-feature format

## Context

Currently, two distinct branch naming patterns exist:
- **Drive**: `drive-YYYYMMDD-HHMMSS` (no feature suffix)
- **Trip**: `trip/<trip-name>` (slash-separated, no timestamp)

With the merge of drivin and trippin into the work plugin, we need a single unified branch naming convention:

**New format**: `work-YYYYMMDD-HHMMSS-concise-feature-name`

Examples:
- `work-20260404-014400-dark-mode-toggle`
- `work-20260404-014500-notification-system`

This eliminates the drive-vs-trip distinction in branch names, simplifies context detection, and adds a human-readable feature suffix for better git log readability.

## Plan

### Step 1: Update `create.sh` in core branching skill

Current (`plugins/core/skills/branching/scripts/create.sh`):
```bash
PREFIX="${1:-drive}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BRANCH="${PREFIX}-${TIMESTAMP}"
```

New:
```bash
# Usage: create.sh <feature-name>
# Output: JSON with branch name in format work-YYYYMMDD-HHMMSS-<feature>
FEATURE="${1:-work}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BRANCH="work-${TIMESTAMP}-${FEATURE}"
```

The feature name parameter is required (or defaults to generic "work"). The caller sanitizes the name (lowercase, hyphens, no special chars).

### Step 2: Update `detect-context.sh`

Current detection logic:
- `drive-*` -> drive context
- `trip/*` -> trip context (with ticket check for hybrid)

New detection logic:
- `work-*` -> work context (unified). The context JSON can include a `mode` field to distinguish drive-style (has tickets) vs trip-style (has .trips/ artifacts) when needed by report/ship.

Update the script to:
1. Match `work-*` instead of `drive-*` and `trip/*`
2. Determine mode by checking:
   - If `.workaholic/.trips/` has artifacts for this branch -> trip mode
   - If `.workaholic/tickets/todo/` has tickets -> drive mode (or hybrid)
   - Default: generic work mode
3. Output: `{"context": "work", "branch": "<branch>", "mode": "drive|trip|hybrid"}`

Keep backward compatibility for existing `drive-*` and `trip/*` branches (map them to work context with appropriate mode) so in-progress branches still work.

### Step 3: Update `check-worktrees.sh`

Replace `trip/*` and `drive-*` pattern matching with `work-*`:
- `trip_count` -> remove or rename to reflect unified naming
- `drive_count` -> remove or rename
- Just track `work_count` (all non-main worktrees are work worktrees)

### Step 4: Update `list-all-worktrees.sh`

Replace type detection logic:
- `trip/*` branch -> type "trip" : remove
- `drive-*` branch -> type "drive" : remove
- `work-*` branch -> type "work"
- Other -> type "other"

### Step 5: Update `ensure-worktree.sh`

Currently creates `trip/<trip-name>` branch and `.worktrees/<trip-name>/` directory.

Update to:
- Accept a work branch name (already in `work-YYYYMMDD-HHMMSS-feature` format)
- Create worktree at `.worktrees/<branch-name>/`
- Branch is the work branch name itself (no `trip/` prefix)

### Step 6: Update `create-trip-branch.sh`

This script creates `trip/<name>` branches without worktrees. Either:
- Remove this script entirely (use `create.sh` for all branches)
- Or rename/update to create `work-*` branches without worktrees

Preferred: remove `create-trip-branch.sh` and use `create.sh <feature>` universally.

### Step 7: Update `cleanup-worktree.sh`

Currently assumes `trip/<trip-name>` branch naming. Update to accept work branch names directly.

### Step 8: Update `list-trip-worktrees.sh`

Rename to `list-worktrees.sh` or update to detect `work-*` branches. Remove trip-specific naming assumptions.

### Step 9: Update `branching/SKILL.md`

Rewrite context detection table:
- Remove `drive`, `trip`, `trip_drive`, `trip_worktree` contexts
- Add `work` context with mode detection
- Update all script documentation

### Step 10: Update trip.md command

The trip command currently calls `create-trip-branch.sh` and `ensure-worktree.sh` with trip-specific naming. Update to use the new `create.sh <feature>` for branch creation.

### Step 11: Update ticket.md command

The ticket command's branch creation (via ticket-organizer) should use `work-*` format instead of `drive-*`.

## Verification

- `bash create.sh my-feature` creates branch `work-YYYYMMDD-HHMMSS-my-feature`
- `bash detect-context.sh` on a `work-*` branch returns `{"context": "work", ...}`
- Existing `drive-*` and `trip/*` branches still detected correctly (backward compat)
- Worktree management scripts work with `work-*` branch names
- All SKILL.md documentation matches new behavior
