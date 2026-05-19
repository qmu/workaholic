---
kind: concern
origin_pr: 39
origin_pr_url: https://github.com/qmu/workaholic/pull/39
origin_branch: work-20260417-092936
origin_commit: cc5de17
created_at: 2026-05-19T11:48:42+09:00
status: active
resolved_by_pr:
resolved_by_commit:
paired_slug:
housekeeping_ticket_emitted: false
---

- Several spec files under `.workaholic/specs/` still reference legacy plugin names (`drivin`, `trippin`, `scanner subagent`) that were outside the prohibited-term grep for the documentation sweep (see [78278c2](https://github.com/qmu/workaholic/commit/78278c2) in `.workaholic/specs/`)
