---
origin_pr: 33
origin_pr_url: https://github.com/qmu/workaholic/pull/33
origin_branch: drive-20260329-173608
origin_commit: cc5de17
created_at: 2026-05-19T11:48:41+09:00
status: resolved
resolved_by_pr: 
resolved_by_commit: 
---
- Generated documentation in `.workaholic/` (policies, specs) still references old skill paths from before the consolidation; these will auto-update on the next `/scan` run (see [b8659cb](https://github.com/qmu/workaholic/commit/b8659cb) in `.workaholic/policies/`)
- Branch-only trips (without worktrees) are invisible in the worktree discovery list; a `git branch --list 'trip/*'` fallback could surface these as resumable sessions in `/trip`
