---
type: Feedback
title: the-search-sh-change-uses-intentionally
kind: concern
source: development
created_at: 2026-05-19T11:48:42+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-search-sh-change-uses-intentionally
owner: 
mission: 
tickets: []
origin_pr: 36
origin_pr_url: https://github.com/qmu/workaholic/pull/36
origin_branch: work-20260406-193458
origin_commit: cc5de17
last_seen: 2026-05-19T11:48:42+09:00
closed: resolved
---

- The `search.sh` change uses intentionally unquoted `$SEARCH_DIRS` for word splitting across multiple directories, which is a deliberate shell practice but could surprise reviewers expecting quoted variables (see [c0e4447](https://github.com/qmu/workaholic/commit/c0e4447) in `plugins/work/skills/discover/scripts/search.sh`)
- Extend the policy discovery mode to also examine CI/CD configurations (.github/workflows/) for deployment conventions
