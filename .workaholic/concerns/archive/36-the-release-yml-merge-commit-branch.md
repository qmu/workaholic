---
origin_pr: 36
origin_pr_url: https://github.com/qmu/workaholic/pull/36
origin_branch: work-20260406-193458
origin_commit: cc5de17
created_at: 2026-05-19T11:48:42+09:00
last_seen: 2026-05-19T11:48:42+09:00
first_seen: 2026-05-19T11:48:42+09:00
concern_id: the-release-yml-merge-commit-branch
status: resolved
resolved_by_pr: 
resolved_by_commit: 
---
- The `release.yml` merge-commit branch name extraction depends on GitHub's merge commit message format, which varies by merge strategy; a lexicographic sort fallback mitigates this but could select the wrong file if branch naming conventions change (see [f6ea316](https://github.com/qmu/workaholic/commit/f6ea316) in `.github/workflows/release.yml`)
