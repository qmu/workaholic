---
created_at: 2026-02-19T19:59:53+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.1h
commit_hash: a22c101
category: Changed
---

# Fix unstaged ticket deletions after drive

## Overview

After `/drive` completes, `git status` shows unstaged deletions for ticket files that were moved from `todo/` to `archive/`. The root cause is that the drive command instructs agents to "Archive and commit using the preloaded archive-ticket skill" (line 57 of `drive.md`), but agents interpret this loosely and perform manual `mv` + `git add` + `git commit` instead of calling `archive.sh`. The `archive.sh` script uses `git add -A` (line 51) which correctly stages the deletion, but when agents bypass it, they may stage only the new archive path and miss the old todo path deletion.

A previous fix (ticket `20260212221342-stage-icebox-to-todo-move-in-git`) addressed unstaged deletions for icebox-to-todo moves in the drive-navigator. This ticket addresses the same class of bug for todo-to-archive moves in the drive command's archive step.

## Key Files

- `plugins/core/commands/drive.md` - Line 57 says "Archive and commit using the preloaded archive-ticket skill" without requiring the agent to call `archive.sh`
- `plugins/core/skills/archive-ticket/SKILL.md` - Provides `archive.sh` usage but agents bypass it
- `plugins/core/skills/archive-ticket/sh/archive.sh` - Line 51 uses `git add -A` which stages everything correctly

## Related History

- [20260212221342-stage-icebox-to-todo-move-in-git.md](.workaholic/tickets/archive/drive-20260212-122906/20260212221342-stage-icebox-to-todo-move-in-git.md) - Fixed the same class of bug for icebox-to-todo moves (added `git add` after `mv` in drive-navigator)
- [20260204173959-strengthen-git-safeguards-in-drive.md](.workaholic/tickets/archive/drive-20260204-160722/20260204173959-strengthen-git-safeguards-in-drive.md) - Added git safety rules to drive workflow
- [20260128224841-enforce-archive-script-usage.md](.workaholic/tickets/archive/feat-20260128-220712/20260128224841-enforce-archive-script-usage.md) - Previous attempt to enforce archive script usage

## Implementation Steps

1. **Update `plugins/core/commands/drive.md` to mandate calling `archive.sh`**. Change the approve handler (Step 2.3, "Approve" path) from the vague "Archive and commit using the preloaded archive-ticket skill" to an explicit instruction requiring the agent to call the archive.sh script with all required parameters. Include the full command template so agents have no ambiguity about what to execute.

2. **Update `plugins/core/skills/archive-ticket/SKILL.md` to add a CRITICAL prohibition against manual archiving**. Add a rule at the top of the skill that says agents must NEVER manually move tickets with `mv` + `git add` + `git commit`. The archive.sh script is the ONLY authorized way to move tickets to archive. This mirrors the pattern established in ticket 20260128224841.

## Patches

### `plugins/core/commands/drive.md`

```diff
--- a/plugins/core/commands/drive.md
+++ b/plugins/core/commands/drive.md
@@ -54,7 +54,14 @@
 **"Approve" or "Approve and stop"**:
 1. Follow **write-final-report** skill to update ticket effort and append Final Report section
 2. **Verify update succeeded**: If Edit tool fails, halt and report the error to user. DO NOT proceed to archive.
-3. Archive and commit using the preloaded **archive-ticket** skill
+3. Archive and commit by calling the archive script directly:
+   ```bash
+   bash ~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/archive-ticket/sh/archive.sh \
+     <ticket-path> "<title>" <repo-url> "<description>" "<changes>" "<test-plan>" "<release-prep>"
+   ```
+   Where `<ticket-path>` is the current ticket file path in `todo/`, `<title>` is the commit title,
+   and `<repo-url>` comes from the gather-git-context output.
+   **NEVER manually move tickets** with `mv` + `git add` -- always use the archive script.
 4. If "Approve and stop": break loop, skip Phase 3, go directly to Phase 4
 5. Otherwise: continue to next ticket
```

### `plugins/core/skills/archive-ticket/SKILL.md`

```diff
--- a/plugins/core/skills/archive-ticket/SKILL.md
+++ b/plugins/core/skills/archive-ticket/SKILL.md
@@ -12,6 +12,10 @@
 Complete commit workflow after user approves implementation. Always use this script - never manually move tickets.

+> **CRITICAL: NEVER manually archive tickets.** Do not use `mv` + `git add` + `git commit` to move
+> tickets from `todo/` to `archive/`. The `archive.sh` script is the ONLY authorized method.
+> Manual moves cause unstaged deletions because agents forget to stage the old path.
+
 ## Prerequisites
```

## Considerations

- The `archive.sh` script uses `git add -A` (line 51) which stages everything. While the commit skill prohibits `git add -A`, the archive script needs it to catch both the deletion (old path) and addition (new path). This is an intentional exception for the archive workflow.
- The previous fix (20260212221342) added `git add` after `mv` in the drive-navigator for icebox-to-todo moves. This ticket applies the same principle to todo-to-archive moves, but enforces it by mandating the archive script rather than adding inline git commands.
- Agent files that reference "Archive and commit using the preloaded archive-ticket skill" in their prompts should also be checked, though the drive command is the primary caller.

## Final Report

Both implementation steps completed:

1. **drive.md updated** — Step 2.3 now includes explicit `archive.sh` command template with all 7 parameters and a NEVER-manual-move prohibition
2. **archive-ticket SKILL.md updated** — Added CRITICAL blockquote at the top prohibiting manual `mv` + `git add` + `git commit`, explaining the unstaged deletion root cause
