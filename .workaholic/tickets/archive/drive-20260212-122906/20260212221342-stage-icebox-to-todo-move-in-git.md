---
created_at: 2026-02-12T22:13:42+08:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.1h
commit_hash: c28027e
category: Changed
---

# Stage icebox-to-todo ticket move in git immediately after filesystem move

## Overview

When the drive-navigator moves a ticket from icebox to todo, it uses a bare `mv` without staging the change in git. This creates an unstaged deletion in the icebox directory that persists through the entire implementation and archive cycle. Although the archive script (`archive.sh` line 51) runs `git add -A` which theoretically stages all changes, this occurs much later in the workflow -- after implementation, approval, and final report writing. If any step between the move and the archive fails, restarts, or takes a different code path, the icebox deletion remains as a dangling unstaged change. The fix is to add `git add` immediately after the `mv` in the drive-navigator's icebox mode, so the move is tracked in git as soon as it happens.

## Key Files

- `plugins/core/agents/drive-navigator.md` - The subagent that performs the icebox-to-todo move at lines 27-29; the `mv` command has no corresponding `git add`

## Related History

The icebox-to-todo move was introduced when the todo subdirectory was created (20260127). A later ticket enforced developer approval before any icebox moves (20260125). The drive-navigator's icebox mode section has not been modified since its introduction and has always lacked the git staging step.

Past tickets that touched similar areas:

- [20260127103311-move-tickets-to-todo.md](.workaholic/tickets/archive/feat-20260126-214833/20260127103311-move-tickets-to-todo.md) - Introduced the todo/ subdirectory and updated drive.md icebox retrieval to move to todo/ (same workflow)
- [20260125114643-require-approval-for-icebox-moves.md](.workaholic/tickets/archive/feat-20260124-200439/20260125114643-require-approval-for-icebox-moves.md) - Added developer approval requirement before icebox moves (same domain: ticket movement controls)
- [20260131125946-intelligent-drive-prioritization.md](.workaholic/tickets/archive/feat-20260131-125844/20260131125946-intelligent-drive-prioritization.md) - Added icebox fallback when todo queue is empty (same icebox-to-todo flow)

## Implementation Steps

1. **Add `git add` after `mv` in drive-navigator icebox mode** (`plugins/core/agents/drive-navigator.md`): In the "Icebox Mode" section (step 4), add a `git add` command immediately after the `mv` command. The `git add` must stage both the old path (to record the deletion) and the new path (to record the addition). This makes the move a tracked operation in git from the moment it happens.

## Patches

### `plugins/core/agents/drive-navigator.md`

```diff
--- a/plugins/core/agents/drive-navigator.md
+++ b/plugins/core/agents/drive-navigator.md
@@ -27,6 +27,7 @@
 4. Move selected ticket to `.workaholic/tickets/todo/`:
    ```bash
    mv .workaholic/tickets/icebox/<selected>.md .workaholic/tickets/todo/
+   git add .workaholic/tickets/icebox/<selected>.md .workaholic/tickets/todo/<selected>.md
    ```
 5. Return the moved ticket for implementation
```

## Considerations

- The `archive.sh` script at line 51 runs `git add -A` which would eventually stage the icebox deletion, but relying on a downstream step to clean up an upstream omission is fragile -- if the archive step is skipped (e.g., abandonment path) or the agent takes a manual approach, the deletion remains unstaged (`plugins/core/skills/archive-ticket/sh/archive.sh` lines 49-51)
- The `git add` stages a deletion (the icebox path) and an addition (the todo path), which git recognizes as a rename when the content is identical. This is the correct git behavior for file moves and produces clean `git status` output
- The drive-approval abandonment flow (`plugins/core/skills/drive-approval/SKILL.md` lines 87-141) uses `git restore` to discard changes and then commits the ticket to abandoned/. If the icebox deletion was never staged, the restore step would not touch it, leaving it as a persistent unstaged change even after abandonment
- This is a single-line addition to a markdown instruction file. The change does not affect any shell scripts, so no script-level testing is needed -- the agent simply follows the updated instruction to run both commands in sequence

## Final Report

Development completed as planned.
