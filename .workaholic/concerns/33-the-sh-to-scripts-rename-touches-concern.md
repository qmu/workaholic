---
kind: concern
origin_pr: 33
origin_pr_url: https://github.com/qmu/workaholic/pull/33
origin_branch: drive-20260329-173608
origin_commit: cc5de17
created_at: 2026-05-19T11:48:41+09:00
status: resolved
resolved_by_pr: 7b965c0
resolved_by_commit: 
paired_slug: 33-the-sh-to-scripts-rename-touches
housekeeping_ticket_emitted: false
---

- The `sh/` to `scripts/` rename touches every shell script path reference across all plugins; any path that was missed will cause exit code 127 failures at runtime (see [7b965c0](https://github.com/qmu/workaholic/commit/7b965c0) across all `plugins/*/skills/*/`)
