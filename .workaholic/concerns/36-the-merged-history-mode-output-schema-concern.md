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
paired_slug: 36-the-merged-history-mode-output-schema
housekeeping_ticket_emitted: false
---

- The merged History mode output schema is more complex, combining historical context fields with ticket moderation fields; the ticket-organizer must correctly parse the `moderation` field from a single response instead of a separate discoverer call (see [c0e4447](https://github.com/qmu/workaholic/commit/c0e4447) in `plugins/work/agents/ticket-organizer.md`)
