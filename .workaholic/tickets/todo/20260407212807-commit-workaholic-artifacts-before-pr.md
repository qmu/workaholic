---
created_at: 2026-04-07T21:28:07+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category:
---

# Commit uncommitted .workaholic/ artifacts before PR creation in trip/report workflow

## Overview

When a trip session finishes and the developer runs `/report`, the story-writer agent commits only `.workaholic/stories/` and `.workaholic/release-notes/`, leaving other `.workaholic/` artifacts (trips directory with directions, models, designs, reviews, plan.md, event-log.md, and potentially tickets in archive/) uncommitted. These uncommitted files are excluded from the PR diff, making the branch history incomplete. The report command or story-writer should stage and commit all uncommitted `.workaholic/` artifacts before creating the story and PR.

## Key Files

- `plugins/work/agents/story-writer.md` - Story-writer agent that commits stories and release notes in Phases 3 and 5, but does not commit other `.workaholic/` artifacts
- `plugins/core/commands/report.md` - Report command that orchestrates the version bump and story-writer invocation; the most natural place to add a pre-flight commit step
- `plugins/core/commands/ship.md` - Ship command with existing workspace guard (Step 0) and ticket guard (Step 0.5); could also serve as a fallback location for the commit step
- `plugins/core/skills/branching/scripts/check-workspace.sh` - Existing script that detects uncommitted changes; already used by report and ship as a guard
- `plugins/work/skills/trip-protocol/scripts/trip-commit.sh` - Trip commit script that uses `git add -A` to stage all changes; each trip workflow step produces a commit, but the final state may still have uncommitted artifacts if the trip completes without a final commit
- `plugins/work/skills/drive/scripts/archive.sh` - Drive archive script that uses `git add -A` before committing, which naturally catches all `.workaholic/` artifacts (drive workflow does not have this problem)

## Related History

The report and ship workflows have been progressively unified and hardened with pre-flight guards (workspace guard, ticket guard, gitignored file sync). This ticket adds the missing guard for uncommitted `.workaholic/` artifacts that fall through the cracks when trip sessions complete without a comprehensive final commit.

Past tickets that touched similar areas:

- [20260404014405-block-ship-when-todo-tickets-remain.md](.workaholic/tickets/archive/drive-20260403-230430/20260404014405-block-ship-when-todo-tickets-remain.md) - Added ticket guard to /ship preventing merge with unfinished tickets (same pattern: pre-flight guard in ship workflow)
- [20260406002124-prompt-gitignored-file-sync-before-worktree-erase.md](.workaholic/tickets/archive/work-20260404-101424-fix-trip-report-dir-path/20260406002124-prompt-gitignored-file-sync-before-worktree-erase.md) - Added gitignored file sync before worktree cleanup in /ship (same pattern: preventing data loss at workflow boundaries)
- [20260403230427-unify-trip-report-to-drive-format.md](.workaholic/tickets/archive/drive-20260403-230430/20260403230427-unify-trip-report-to-drive-format.md) - Unified trip report format to match drive structure (same area: trip/report workflow unification)
- [20260406193700-remove-write-trip-report-skill.md](.workaholic/tickets/archive/work-20260406-193458/20260406193700-remove-write-trip-report-skill.md) - Removed redundant write-trip-report skill after report unification (same flow: trip reporting)

## Implementation Steps

1. **Create a new script `plugins/core/skills/branching/scripts/check-workaholic-artifacts.sh`** that:
   - Detects uncommitted `.workaholic/` files (untracked and modified) using `git status --porcelain`
   - Filters to only `.workaholic/` paths (trips/, tickets/, and other subdirectories)
   - Excludes `.workaholic/stories/` and `.workaholic/release-notes/` since the story-writer handles those
   - Returns JSON: `{"has_uncommitted": true/false, "count": N, "files": ["path1", "path2"]}`

2. **Add a new step in `plugins/core/commands/report.md`** between the Workspace Guard (Step 0) and Context Detection (Step 1):
   - **Step 0.5: Artifact Guard** - Run the new check script
   - If `has_uncommitted` is `true`: display the file list to the user, then stage all `.workaholic/` files (excluding stories/ and release-notes/) and commit with message "Commit trip session artifacts"
   - If `has_uncommitted` is `false`: proceed silently
   - This runs before the version bump and story-writer, ensuring all artifacts are in the branch history before the PR is created

3. **Update `plugins/core/skills/branching/SKILL.md`** to document the new `check-workaholic-artifacts.sh` script with usage and output format, following the same pattern as the existing `check-workspace.sh` documentation

## Patches

### `plugins/core/commands/report.md`

> **Note**: This patch is speculative - verify before applying.

```diff
--- a/plugins/core/commands/report.md
+++ b/plugins/core/commands/report.md
@@ -28,6 +28,22 @@
 
 If the user selects "Stop", end the command immediately.
 
+### Step 0.5: Artifact Guard
+
+```bash
+bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check-workaholic-artifacts.sh
+```
+
+Parse the JSON output. If `has_uncommitted` is `false`, proceed silently to Step 1.
+
+If `has_uncommitted` is `true`, display the file count and list to the user: "Found N uncommitted .workaholic/ artifact(s) from the current session:" followed by the file paths. Then stage and commit them:
+
+```bash
+git add <listed .workaholic/ files>
+git commit -m "Commit session artifacts"
+```
+
+Proceed to Step 1 after committing.
+
 ### Step 1: Detect Context
 
 ```bash
```

## Considerations

- The report command's existing Workspace Guard (Step 0) already detects uncommitted changes but treats them as a generic warning with options to "Ignore and proceed" or "Stop". The new Artifact Guard is more targeted: it specifically addresses `.workaholic/` artifacts that should always be committed before reporting, rather than leaving the decision to the user. The two guards are complementary, not redundant. (`plugins/core/commands/report.md` lines 19-29)
- The story-writer's Phase 3 commits `.workaholic/stories/` and Phase 5 commits `.workaholic/release-notes/`. The new artifact guard must exclude these paths to avoid committing empty directories or conflicting with the story-writer's own staging. (`plugins/work/agents/story-writer.md` lines 38-59)
- In the drive workflow, `archive.sh` uses `git add -A` which catches everything including `.workaholic/` artifacts. The trip workflow's `trip-commit.sh` also uses `git add -A`, but only when there are changes at each step. If the trip completes and the final commit captures all artifacts, this guard becomes a no-op (correctly). The guard serves as a safety net for the gap between trip completion and report generation. (`plugins/work/skills/drive/scripts/archive.sh` line 54, `plugins/work/skills/trip-protocol/scripts/trip-commit.sh` line 21)
- Placing the artifact commit in the report command rather than the ship command ensures the artifacts appear in the PR diff, making the branch history reviewable before merge. If placed only in ship, the artifacts would be committed after the PR is already created, requiring an additional push and PR update. (`plugins/core/commands/report.md`)
- The script should live in `plugins/core/skills/branching/scripts/` rather than `plugins/work/` because uncommitted `.workaholic/` artifacts are a concern for any workflow context, not just trips. The core plugin's branching skill already has `check-workspace.sh` as a precedent for workspace state checks. (`plugins/core/skills/branching/scripts/check-workspace.sh`)
