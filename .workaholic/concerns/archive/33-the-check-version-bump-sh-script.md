---
origin_pr: 33
origin_pr_url: https://github.com/qmu/workaholic/pull/33
origin_branch: drive-20260329-173608
origin_commit: cc5de17
created_at: 2026-05-19T11:48:41+09:00
last_seen: 2026-05-19T11:48:41+09:00
first_seen: 2026-05-19T11:48:41+09:00
concern_id: the-check-version-bump-sh-script
status: resolved
resolved_by_pr: 
resolved_by_commit: 
---
- The `check-version-bump.sh` script hardcodes `main` as the base branch, which may need parameterization if the default branch ever changes (see [b8659cb](https://github.com/qmu/workaholic/commit/b8659cb) in `plugins/core/skills/branching/scripts/check-version-bump.sh`)
