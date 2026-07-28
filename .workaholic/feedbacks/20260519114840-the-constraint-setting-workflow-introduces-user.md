---
type: Feedback
title: the-constraint-setting-workflow-introduces-user
kind: concern
source: development
created_at: 2026-05-19T11:48:40+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-constraint-setting-workflow-introduces-user
owner: 
mission: 
tickets: []
origin_pr: 24
origin_pr_url: https://github.com/qmu/workaholic/pull/24
origin_branch: drive-20260210-121635
origin_commit: cc5de17
last_seen: 2026-05-19T11:48:40+09:00
closed: resolved
resolved_by_pr: d4352d5
---

- The constraint-setting workflow introduces user interaction (the "Ask" phase) into what was previously a non-interactive analysis pipeline; during /scan managers run as sub-agents that may not have direct user interaction capability (see [f7f779f](https://github.com/qmu/workaholic/commit/f7f779f) in `plugins/core/skills/managers-policy/SKILL.md`)
