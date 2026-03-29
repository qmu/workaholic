---
created_at: 2026-03-28T15:57:52+09:00
author: a@qmu.jp
type: enhancement
layer: [UX, Config]
effort: 0.5h
commit_hash: a233799
category: Added
---

# Add clean workspace guard to /report and /ship commands

## Overview

Before `/report` or `/ship` proceeds with its workflow, add a guard step that runs `git status` to detect unstaged or untracked changes. If unrelated changes exist, the command asks the user via AskUserQuestion whether to ignore them and proceed, or stop so the user can handle them first. After the command completes, there should be no surprise leftover changes -- either everything was committed as part of the command, or the user explicitly acknowledged the remaining changes before the command ran.

## Key Files

- `plugins/core/commands/report.md` - Report command; needs a new guard step before Step 1
- `plugins/core/commands/ship.md` - Ship command; needs a new guard step before Step 1
- `plugins/core/skills/branching/SKILL.md` - Core branching skill; may document the new guard script
- `plugins/core/skills/branching/sh/detect-context.sh` - Existing context detection; the guard runs before this

## Related History

Several past tickets established patterns for git safety, destructive operation guards, and pre-flight checks in the drive workflow. This ticket extends that philosophy to the report and ship commands, which currently have no workspace cleanliness checks.

Past tickets that touched similar areas:

- [20260204173959-strengthen-git-safeguards-in-drive.md](.workaholic/tickets/archive/drive-20260204-160722/20260204173959-strengthen-git-safeguards-in-drive.md) - Added pre-flight checks and prohibited destructive git operations in /drive (same philosophy: check before proceeding)
- [20260219195953-fix-unstaged-ticket-deletions-after-drive.md](.workaholic/tickets/archive/drive-20260213-131416/20260219195953-fix-unstaged-ticket-deletions-after-drive.md) - Fixed unstaged deletions left behind after /drive (same class of problem: surprise changes after command completes)
- [20260311193203-worktree-aware-report-ship-trip.md](.workaholic/tickets/archive/drive-20260311-125319/20260311193203-worktree-aware-report-ship-trip.md) - Added worktree-aware routing to report and ship commands (same commands being enhanced)
- [20260316143754-add-worktree-detection-guard.md](.workaholic/tickets/archive/drive-20260312-102414/20260316143754-add-worktree-detection-guard.md) - Added worktree detection guard to /drive (same guard pattern: check state before proceeding)

## Implementation Steps

1. **Create `plugins/core/skills/branching/sh/check-workspace.sh`** -- a shell script that runs `git status --porcelain` and outputs structured JSON describing the workspace state. The script must follow the Shell Script Principle (all conditional logic in the script, not inline in command markdown). Output format:
   ```json
   {
     "clean": true,
     "untracked_count": 0,
     "unstaged_count": 0,
     "staged_count": 0,
     "summary": ""
   }
   ```
   When the workspace is not clean, `summary` should contain a human-readable description (e.g., "3 unstaged changes, 2 untracked files"). The script should count and categorize changes from `git status --porcelain` output: `??` prefix for untracked, ` M`/` D` for unstaged modifications/deletions, `M `/`A `/`D ` for staged changes.

2. **Add "Step 0: Workspace Guard" to `plugins/core/commands/report.md`** -- before the existing Step 1 (Detect Context), add a new step that:
   - Runs `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/check-workspace.sh`
   - If `clean` is `true`: proceed silently
   - If `clean` is `false`: display the summary to the user and ask via AskUserQuestion with two selectable options:
     - **"Ignore and proceed"** -- continue with the report workflow; the changes will remain after the command completes
     - **"Stop"** -- halt the command so the user can handle the changes first
   - If the user selects "Stop", end the command immediately

3. **Add "Step 0: Workspace Guard" to `plugins/core/commands/ship.md`** -- identical guard logic as report.md, placed before the existing Step 1 (Detect Context). Same script call, same AskUserQuestion options, same behavior.

4. **Document the new script in `plugins/core/skills/branching/SKILL.md`** -- add a "Workspace Guard" subsection (similar to the existing "Worktree Guard" subsection) describing the script, its purpose, and its output format.

## Patches

### `plugins/core/skills/branching/SKILL.md`

```diff
--- a/plugins/core/skills/branching/SKILL.md
+++ b/plugins/core/skills/branching/SKILL.md
@@ -58,6 +58,33 @@

 Unlike `list-trip-worktrees.sh`, this script does not query GitHub API for PR status. It is designed for fast, non-blocking guard checks.

+## Workspace Guard
+
+Check whether the working directory has unstaged, untracked, or staged changes. Used by commands that should warn the user before proceeding when the workspace is not clean.
+
+```bash
+bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/check-workspace.sh
+```
+
+### Output Format
+
+```json
+{
+  "clean": false,
+  "untracked_count": 2,
+  "unstaged_count": 3,
+  "staged_count": 0,
+  "summary": "3 unstaged changes, 2 untracked files"
+}
+```
+
+- `clean`: Boolean indicating if the workspace has no changes
+- `untracked_count`: Number of untracked files (`??` in git status)
+- `unstaged_count`: Number of unstaged modifications or deletions
+- `staged_count`: Number of staged changes
+- `summary`: Human-readable description of changes (empty string when clean)
+
+Unlike context detection, this script does not inspect branch patterns. It only reports workspace cleanliness.
+
 ## Worktree Management

 ### Adopt
```

### `plugins/core/commands/report.md`

```diff
--- a/plugins/core/commands/report.md
+++ b/plugins/core/commands/report.md
@@ -14,7 +14,21 @@ Context-aware report command that auto-detects whether you are in a drive or trip

 ## Instructions

-### Step 1: Detect Context
+### Step 0: Workspace Guard
+
+```bash
+bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/check-workspace.sh
+```
+
+Parse the JSON output. If `clean` is `true`, proceed silently to Step 1.
+
+If `clean` is `false`, display the `summary` to the user and ask via AskUserQuestion with selectable options:
+- **"Ignore and proceed"** - Continue with the report workflow. The unrelated changes will remain in the workspace after the command completes.
+- **"Stop"** - Halt the command so you can handle the changes first.
+
+If the user selects "Stop", end the command immediately.
+
+### Step 1: Detect Context (unchanged)

 ```bash
 bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/detect-context.sh
```

### `plugins/core/commands/ship.md`

```diff
--- a/plugins/core/commands/ship.md
+++ b/plugins/core/commands/ship.md
@@ -14,7 +14,21 @@ Context-aware ship command that auto-detects whether you are in a drive or trip w

 ## Instructions

-### Step 1: Detect Context
+### Step 0: Workspace Guard
+
+```bash
+bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/check-workspace.sh
+```
+
+Parse the JSON output. If `clean` is `true`, proceed silently to Step 1.
+
+If `clean` is `false`, display the `summary` to the user and ask via AskUserQuestion with selectable options:
+- **"Ignore and proceed"** - Continue with the ship workflow. The unrelated changes will remain in the workspace after the command completes.
+- **"Stop"** - Halt the command so you can handle the changes first.
+
+If the user selects "Stop", end the command immediately.
+
+### Step 1: Detect Context (unchanged)

 ```bash
 bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/detect-context.sh
```

> **Note**: The `(unchanged)` annotation on Step 1 headings is for clarity in this patch only. In the actual file, the heading should remain `### Step 1: Detect Context` without the annotation.

## Considerations

- The guard script should use `git status --porcelain` for machine-parseable output rather than the human-readable default format (`plugins/core/skills/branching/sh/check-workspace.sh`)
- Staged changes (files already added with `git add`) are included in the check because they indicate in-progress work that the user may not intend to include in the report/ship workflow (`plugins/core/skills/branching/sh/check-workspace.sh`)
- The /drive command already has a Worktree Guard (Phase 0) but not a workspace cleanliness guard. Adding one to /drive is out of scope for this ticket since /drive actively creates and commits changes, making a pre-flight workspace check less meaningful there (`plugins/drivin/commands/drive.md` lines 20-36)
- The ship command's merge-pr script checks out main and pulls after merge, which could conflict with untracked files in the working directory. The workspace guard gives the user a chance to handle this before it becomes a git error (`plugins/trippin/skills/ship/sh/merge-pr.sh`)
- The AskUserQuestion approach follows the established pattern from the worktree guard in /drive (Phase 0) and the trip worktree routing in /report and /ship (`plugins/core/commands/report.md` lines 64-70, `plugins/drivin/commands/drive.md` lines 28-31)

## Final Report

Development completed as planned.
