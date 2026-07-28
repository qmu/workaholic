---
type: Feedback
title: the-relative-claude-skills-path-used
kind: concern
source: development
created_at: 2026-05-19T11:48:40+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-relative-claude-skills-path-used
owner: 
mission: 
tickets: []
origin_pr: 25
origin_pr_url: https://github.com/qmu/workaholic/pull/25
origin_branch: drive-20260212-122906
origin_commit: cc5de17
last_seen: 2026-05-19T11:48:40+09:00
closed: resolved
---

- The relative `.claude/skills/` path used in skill documentation does not resolve at runtime; the actual installed path is the full absolute path under `~/.claude/plugins/` (see [a6dd86e](https://github.com/qmu/workaholic/commit/a6dd86e) in `plugins/core/skills/write-final-report/SKILL.md`)
