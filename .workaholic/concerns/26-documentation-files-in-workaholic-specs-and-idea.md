---
kind: idea
origin_pr: 26
origin_pr_url: https://github.com/qmu/workaholic/pull/26
origin_branch: drive-20260213-131416
origin_commit: cc5de17
created_at: 2026-05-19T11:48:40+09:00
status: active
resolved_by_pr:
resolved_by_commit:
paired_slug:
housekeeping_ticket_emitted: false
---

- Documentation files in `.workaholic/specs/` and `.workaholic/policies/` were fixed manually but will be overwritten by the next `/scan` run; the scan agents must also generate correct absolute paths to avoid reintroducing the problem (see [f494b8e](https://github.com/qmu/workaholic/commit/f494b8e) in `.workaholic/policies/delivery.md`)
