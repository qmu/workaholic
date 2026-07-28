---
type: Feedback
title: the-ship-drive-and-ship-trip
kind: concern
source: development
created_at: 2026-05-19T11:48:40+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-ship-drive-and-ship-trip
owner: 
mission: 
tickets: []
origin_pr: 28
origin_pr_url: https://github.com/qmu/workaholic/pull/28
origin_branch: drive-20260310-220224
origin_commit: cc5de17
last_seen: 2026-05-19T11:48:40+09:00
closed: resolved
---

- The `/ship-drive` and `/ship-trip` commands execute arbitrary deployment instructions from user-provided `cloud.md` files; while a confirmation step was added, the deploy step ultimately executes whatever the user has documented (see [d764af2](https://github.com/qmu/workaholic/commit/d764af2) in `plugins/drivin/commands/ship-drive.md`)
