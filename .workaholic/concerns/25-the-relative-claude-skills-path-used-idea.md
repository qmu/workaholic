---
kind: idea
origin_pr: 25
origin_pr_url: https://github.com/qmu/workaholic/pull/25
origin_branch: drive-20260212-122906
origin_commit: cc5de17
created_at: 2026-05-19T11:48:40+09:00
status: resolved
resolved_by_pr: 
resolved_by_commit: 
paired_slug:
housekeeping_ticket_emitted: false
---

- The relative `.claude/skills/` path used in skill documentation does not resolve at runtime; the actual installed path is the full absolute path under `~/.claude/plugins/` (see [a6dd86e](https://github.com/qmu/workaholic/commit/a6dd86e) in `plugins/core/skills/write-final-report/SKILL.md`)
