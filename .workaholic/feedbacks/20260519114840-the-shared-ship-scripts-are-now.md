---
type: Feedback
title: the-shared-ship-scripts-are-now
kind: concern
source: development
created_at: 2026-05-19T11:48:40+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-shared-ship-scripts-are-now
owner: 
mission: 
tickets: []
origin_pr: 28
origin_pr_url: https://github.com/qmu/workaholic/pull/28
origin_branch: drive-20260310-220224
origin_commit: cc5de17
last_seen: 2026-05-19T11:48:40+09:00
closed: resolved
resolved_by_pr: 9e779ee
---

- The shared ship scripts are now duplicated between Drivin and Trippin plugins (77 lines across 3 files each); future changes must be synchronized manually across both copies (see [b3e7db0](https://github.com/qmu/workaholic/commit/b3e7db0) in `plugins/trippin/skills/ship/`)
