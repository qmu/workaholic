---
origin_pr: 30
origin_pr_url: https://github.com/qmu/workaholic/pull/30
origin_branch: drive-20260312-102414
origin_commit: cc5de17
created_at: 2026-05-19T11:48:41+09:00
last_seen: 2026-05-19T11:48:41+09:00
first_seen: 2026-05-19T11:48:41+09:00
concern_id: the-detect-context-sh-change-introduces
status: resolved
resolved_by_pr: 
resolved_by_commit: 
---
- The `detect-context.sh` change introduces state-dependent context detection (checking for ticket files in `todo/`), which makes the context non-deterministic based solely on branch name -- a departure from the previous pure-pattern-based approach (see [ced9de5](https://github.com/qmu/workaholic/commit/ced9de5) in `plugins/core/skills/branching/sh/detect-context.sh`)
