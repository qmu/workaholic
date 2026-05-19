---
kind: concern
origin_pr: 37
origin_pr_url: https://github.com/qmu/workaholic/pull/37
origin_branch: work-20260408-001129
origin_commit: cc5de17
created_at: 2026-05-19T11:48:42+09:00
status: active
resolved_by_pr:
resolved_by_commit:
paired_slug: 37-topological-sort-in-the-drive-navigator
housekeeping_ticket_emitted: false
---

- Topological sort in the drive-navigator is described in prose rather than extracted to a shell script; if the sorting logic grows more complex, it should be extracted to follow the shell script principle (see [bf57f48](https://github.com/qmu/workaholic/commit/bf57f48) in `plugins/work/agents/drive-navigator.md`)
