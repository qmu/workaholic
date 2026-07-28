---
type: Feedback
title: the-ticket-update-first-enforcement-has
kind: concern
source: development
created_at: 2026-05-19T11:48:40+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-ticket-update-first-enforcement-has
owner: 
mission: 
tickets: []
origin_pr: 24
origin_pr_url: https://github.com/qmu/workaholic/pull/24
origin_branch: drive-20260210-121635
origin_commit: cc5de17
last_seen: 2026-05-19T11:48:40+09:00
closed: resolved
resolved_by_pr: a0949ae
---

- The ticket-update-first enforcement has been strengthened multiple times across branches; if CRITICAL markers prove insufficient, a structural approach (shell script gate checking ticket modification time) may be needed (see [b237279](https://github.com/qmu/workaholic/commit/b237279) in `plugins/core/skills/drive-approval/SKILL.md`)
