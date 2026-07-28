---
type: Feedback
title: the-rollback-mechanism-has-no-cooldown
kind: concern
source: development
created_at: 2026-05-19T11:48:41+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-rollback-mechanism-has-no-cooldown
owner: 
mission: 
tickets: []
origin_pr: 29
origin_pr_url: https://github.com/qmu/workaholic/pull/29
origin_branch: drive-20260311-125319
origin_commit: cc5de17
last_seen: 2026-05-19T11:48:41+09:00
closed: resolved
---

- The rollback mechanism has no cooldown or maximum attempt limit; a determined agent could theoretically spam rollback proposals (see [aa037ce](https://github.com/qmu/workaholic/commit/aa037ce) in `plugins/trippin/skills/trip-protocol/SKILL.md`)
