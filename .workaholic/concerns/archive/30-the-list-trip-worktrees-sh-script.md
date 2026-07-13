---
origin_pr: 30
origin_pr_url: https://github.com/qmu/workaholic/pull/30
origin_branch: drive-20260312-102414
origin_commit: cc5de17
created_at: 2026-05-19T11:48:41+09:00
last_seen: 2026-05-19T11:48:41+09:00
first_seen: 2026-05-19T11:48:41+09:00
concern_id: the-list-trip-worktrees-sh-script
status: resolved
resolved_by_pr: 
resolved_by_commit: 
---
- The `list-trip-worktrees.sh` script makes one `gh pr list` API call per worktree, which could introduce latency in the resume prompt; the guard script (`check-worktrees.sh`) avoids this but the full listing is still called when the user chooses to switch (see [d78cb2d](https://github.com/qmu/workaholic/commit/d78cb2d) in `plugins/core/skills/branching/sh/check-worktrees.sh`)
