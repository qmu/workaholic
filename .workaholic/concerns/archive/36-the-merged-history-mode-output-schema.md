---
origin_pr: 36
origin_pr_url: https://github.com/qmu/workaholic/pull/36
origin_branch: work-20260406-193458
origin_commit: cc5de17
created_at: 2026-05-19T11:48:42+09:00
last_seen: 2026-05-19T11:48:42+09:00
first_seen: 2026-05-19T11:48:42+09:00
concern_id: the-merged-history-mode-output-schema
status: resolved
resolved_by_pr: 
resolved_by_commit: 
---
- The merged History mode output schema is more complex, combining historical context fields with ticket moderation fields; the ticket-organizer must correctly parse the `moderation` field from a single response instead of a separate discoverer call (see [c0e4447](https://github.com/qmu/workaholic/commit/c0e4447) in `plugins/work/agents/ticket-organizer.md`)
- Add automated validation that `search.sh` results include todo and icebox tickets in integration tests
