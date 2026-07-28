---
type: Feedback
title: the-system-safety-blocklist-is-enforced
kind: concern
source: development
created_at: 2026-05-19T11:48:41+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-system-safety-blocklist-is-enforced
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

- The system-safety blocklist is enforced through agent instructions rather than a technical sandbox; agents in separate context windows could bypass the restriction if the constraint text is not retained in context (see [e48d523](https://github.com/qmu/workaholic/commit/e48d523) in `plugins/drivin/skills/system-safety/SKILL.md`)
