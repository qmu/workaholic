---
origin_pr: 33
origin_pr_url: https://github.com/qmu/workaholic/pull/33
origin_branch: drive-20260329-173608
origin_commit: cc5de17
created_at: 2026-05-19T11:48:41+09:00
last_seen: 2026-05-19T11:48:41+09:00
first_seen: 2026-05-19T11:48:41+09:00
concern_id: the-sh-to-scripts-rename-touches
status: resolved
resolved_by_pr: 
resolved_by_commit: 
---
- Add a link checker script that verifies all `${CLAUDE_PLUGIN_ROOT}/../` cross-plugin references resolve to files that actually exist, run as a pre-commit hook or CI step
