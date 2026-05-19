---
kind: idea
origin_pr: 29
origin_pr_url: https://github.com/qmu/workaholic/pull/29
origin_branch: drive-20260311-125319
origin_commit: cc5de17
created_at: 2026-05-19T11:48:41+09:00
status: active
resolved_by_pr:
resolved_by_commit:
paired_slug:
housekeeping_ticket_emitted: false
---

- The rollback mechanism has no cooldown or maximum attempt limit; a determined agent could theoretically spam rollback proposals (see [aa037ce](https://github.com/qmu/workaholic/commit/aa037ce) in `plugins/trippin/skills/trip-protocol/SKILL.md`)
