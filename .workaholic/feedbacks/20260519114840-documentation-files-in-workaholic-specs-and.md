---
type: Feedback
title: documentation-files-in-workaholic-specs-and
kind: concern
source: development
created_at: 2026-05-19T11:48:40+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: documentation-files-in-workaholic-specs-and
owner: 
mission: 
tickets: []
origin_pr: 26
origin_pr_url: https://github.com/qmu/workaholic/pull/26
origin_branch: drive-20260213-131416
origin_commit: cc5de17
last_seen: 2026-05-19T11:48:40+09:00
closed: resolved
---

- Documentation files in `.workaholic/specs/` and `.workaholic/policies/` were fixed manually but will be overwritten by the next `/scan` run; the scan agents must also generate correct absolute paths to avoid reintroducing the problem (see [f494b8e](https://github.com/qmu/workaholic/commit/f494b8e) in `.workaholic/policies/delivery.md`)
