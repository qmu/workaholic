---
kind: concern
origin_pr: 36
origin_pr_url: https://github.com/qmu/workaholic/pull/36
origin_branch: work-20260406-193458
origin_commit: cc5de17
created_at: 2026-05-19T11:48:42+09:00
status: active
resolved_by_pr:
resolved_by_commit:
paired_slug: 36-the-search-sh-change-uses-intentionally
housekeeping_ticket_emitted: false
---

- The `search.sh` change uses intentionally unquoted `$SEARCH_DIRS` for word splitting across multiple directories, which is a deliberate shell practice but could surprise reviewers expecting quoted variables (see [c0e4447](https://github.com/qmu/workaholic/commit/c0e4447) in `plugins/work/skills/discover/scripts/search.sh`)
