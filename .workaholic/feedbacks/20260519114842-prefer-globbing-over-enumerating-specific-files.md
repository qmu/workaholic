---
type: Feedback
title: prefer-globbing-over-enumerating-specific-files
kind: concern
source: development
created_at: 2026-05-19T11:48:42+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: prefer-globbing-over-enumerating-specific-files
owner: 
mission: 
tickets: []
origin_pr: 39
origin_pr_url: https://github.com/qmu/workaholic/pull/39
origin_branch: work-20260417-092936
origin_commit: cc5de17
last_seen: 2026-05-19T11:48:42+09:00
closed: resolved
---

- Prefer globbing over enumerating specific files in `.claude/rules/*` `paths:` frontmatter so path-scope rules survive future agent/command restructuring without leaving stale references
