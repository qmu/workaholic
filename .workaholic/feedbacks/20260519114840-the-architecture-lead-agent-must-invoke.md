---
type: Feedback
title: the-architecture-lead-agent-must-invoke
kind: concern
source: development
created_at: 2026-05-19T11:48:40+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-architecture-lead-agent-must-invoke
owner: 
mission: 
tickets: []
origin_pr: 23
origin_pr_url: https://github.com/qmu/workaholic/pull/23
origin_branch: drive-20260208-131649
origin_commit: cc5de17
last_seen: 2026-05-19T11:48:40+09:00
closed: resolved
resolved_by_pr: 24c6f16
---

- The architecture-lead agent must invoke `analyze-viewpoint/sh/gather.sh` four times (once per viewpoint slug) during a single documentation scan, which may increase execution time compared to four parallel analysts (see [8e955b8](https://github.com/qmu/workaholic/commit/8e955b8) in `plugins/core/skills/lead-architecture/SKILL.md`)
