---
created_at: 2026-04-04T10:18:42+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 0.25h
commit_hash: 9535bbd
category: Changed
---

# Simplify branch naming to work-TIMESTAMP only

## Overview

Remove the feature description suffix from branch names. Currently branches are named `work-YYYYMMDD-HHMMSS-<feature>` (e.g., `work-20260404-101424-fix-trip-report-dir-path`). The new format should be `work-YYYYMMDD-HHMMSS` only (e.g., `work-20260404-101424`). The feature suffix adds no functional value since branch context is tracked in tickets and stories, and removing it simplifies branch creation by eliminating the need to derive or sanitize a feature name slug.

## Key Files

- `plugins/core/skills/branching/scripts/create.sh` - The script that constructs the branch name; appends `${FEATURE}` to the timestamp (line 12)
- `plugins/core/skills/branching/SKILL.md` - Documents the `[feature-name]` argument, output example with suffix (lines 210-221)
- `plugins/work/commands/trip.md` - Derives a feature name from `$ARGUMENT` and passes it to `create.sh` (lines 40-52)
- `plugins/work/agents/ticket-organizer.md` - Output example shows `drive-20260202-181910` (already without suffix, but the example is outdated; line 86)

## Related History

The feature suffix was introduced when drive and trip branches were unified into the `work-*` pattern. The original drive branches used `drive-YYYYMMDD-HHMMSS` (no suffix), and the suffix was added to provide human-readable context in `git log`. This ticket reverses that decision in favor of simplicity.

Past tickets that touched similar areas:

- [20260404014401-unify-branch-naming-work-timestamp-feature.md](.workaholic/tickets/archive/drive-20260403-230430/20260404014401-unify-branch-naming-work-timestamp-feature.md) - Unified branch naming to `work-YYYYMMDD-HHMMSS-feature` format (introduced the suffix being removed here)

## Implementation Steps

1. Update `plugins/core/skills/branching/scripts/create.sh`: Remove the `FEATURE` variable and the `-${FEATURE}` suffix from the `BRANCH` construction. Remove the `[feature-name]` argument from the usage comment. Update the format comment.
2. Update `plugins/core/skills/branching/SKILL.md`: Remove the `[feature-name]` argument documentation, update the output example from `work-20260404-014400-dark-mode-toggle` to `work-20260404-014400`, and update all example branch names that include feature suffixes (list-all-worktrees output, list-worktrees output).
3. Update `plugins/work/commands/trip.md`: Remove the feature name derivation instruction on line 40 ("Derive a concise feature name..."). Change both `create.sh "<feature-name>"` calls to `create.sh` with no argument.
4. Update `plugins/work/agents/ticket-organizer.md`: Change the `branch_created` example from `drive-20260202-181910` to `work-20260202-181910` to reflect the current naming convention.

## Patches

### `plugins/core/skills/branching/scripts/create.sh`

```diff
--- a/plugins/core/skills/branching/scripts/create.sh
+++ b/plugins/core/skills/branching/scripts/create.sh
@@ -1,8 +1,7 @@
 #!/bin/sh
 # Create timestamped topic branch
-# Usage: create.sh [feature-name]
-# Default feature: work
+# Usage: create.sh
 # Output: JSON with branch name
-# Format: work-YYYYMMDD-HHMMSS-<feature>
+# Format: work-YYYYMMDD-HHMMSS
 
 set -eu
 
-FEATURE="${1:-work}"
 TIMESTAMP=$(date +%Y%m%d-%H%M%S)
-BRANCH="work-${TIMESTAMP}-${FEATURE}"
+BRANCH="work-${TIMESTAMP}"
 
 git checkout -b "$BRANCH"
```

### `plugins/work/commands/trip.md`

> **Note**: This patch is speculative - verify exact line positions before applying.

```diff
--- a/plugins/work/commands/trip.md
+++ b/plugins/work/commands/trip.md
@@ -37,14 +37,14 @@
 
-**New**: Derive a concise feature name from `$ARGUMENT` (lowercase, hyphens, max 30 chars). Present a choice via AskUserQuestion:
+**New**: Present a choice via AskUserQuestion:
 - **"Create worktree"** - Isolated environment. Run:
   ```bash
-  bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/create.sh "<feature-name>"
+  bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/create.sh
   ```
   Parse JSON to get `branch`. Then create worktree from it:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/adopt-worktree.sh "<branch>"
   ```
   Set `<working_dir>` to the `worktree_path` from the output.
 - **"Branch only"** - Lightweight, no worktree. Run:
   ```bash
-  bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/create.sh "<feature-name>"
+  bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/create.sh
   ```
   Set `<working_dir>` to the repository root.
```

### `plugins/work/agents/ticket-organizer.md`

```diff
--- a/plugins/work/agents/ticket-organizer.md
+++ b/plugins/work/agents/ticket-organizer.md
@@ -83,7 +83,7 @@
 {
   "status": "success",
-  "branch_created": "drive-20260202-181910",
+  "branch_created": "work-20260202-181910",
   "tickets": [
```

## Considerations

- The SKILL.md documentation contains four example branch names with feature suffixes (`work-20260404-014400-dark-mode`, `work-20260403-230430-notifications`, `work-20260404-014400-dark-mode-toggle`) across list-all-worktrees, list-worktrees, and create-topic-branch output sections. All must be updated to timestamp-only format. (`plugins/core/skills/branching/SKILL.md` lines 137-138, 156, 221)
- The `detect-context.sh` script matches `work-*` which will continue to work with both the old suffixed format and the new timestamp-only format -- no changes needed there. (`plugins/core/skills/branching/scripts/detect-context.sh` line 47)
- Existing branches with the old suffixed format (e.g., `work-20260404-101424-fix-trip-report-dir-path`) remain valid since detection uses prefix matching (`work-*`). No migration is needed. (`plugins/core/skills/branching/scripts/detect-context.sh`)
- The `list-all-worktrees.sh` and `list-worktrees.sh` scripts match `work-*` prefix and do not parse the feature suffix, so they require no code changes. (`plugins/core/skills/branching/scripts/list-all-worktrees.sh` line 30)
- The archived ticket `20260404014401-unify-branch-naming-work-timestamp-feature.md` documents the rationale for adding the suffix. This ticket effectively reverses part of that decision. The archive is a historical record and should not be modified.

## Final Report

### Changes Made

- `plugins/core/skills/branching/scripts/create.sh` — Removed `FEATURE` variable and `-${FEATURE}` suffix; branch is now `work-${TIMESTAMP}` only
- `plugins/core/skills/branching/SKILL.md` — Removed `[feature-name]` argument docs, updated 4 example branch names to timestamp-only format
- `plugins/work/commands/trip.md` — Removed feature name derivation instruction, changed both `create.sh` calls to use no argument
- `plugins/work/agents/ticket-organizer.md` — Updated `branch_created` example from `drive-` to `work-` prefix

### Test Plan

- Verify `create.sh` produces `work-YYYYMMDD-HHMMSS` format without suffix
- Verify existing `work-*` branch detection still works (prefix matching)

### Release Preparation

None required. Branch naming is internal convention.
