---
kind: concern
origin_pr: 33
origin_pr_url: https://github.com/qmu/workaholic/pull/33
origin_branch: drive-20260329-173608
origin_commit: cc5de17
created_at: 2026-05-19T11:48:41+09:00
status: resolved
resolved_by_pr: 36b0835
resolved_by_commit: 
paired_slug: 33-core-commands-report-md-ship-md
housekeeping_ticket_emitted: false
---

- Core commands (`report.md`, `ship.md`) still contain soft references to trippin for trip-context routing, creating an optional reverse dependency that is not captured in core's empty `dependencies` array (see [7b50ea2](https://github.com/qmu/workaholic/commit/7b50ea2) in `plugins/core/commands/report.md`)
