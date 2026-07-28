---
type: Feedback
title: the-consolidated-lead-agent-preloads-all
kind: concern
source: development
created_at: 2026-05-19T11:48:42+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-consolidated-lead-agent-preloads-all
owner: 
mission: 
tickets: []
origin_pr: 35
origin_pr_url: https://github.com/qmu/workaholic/pull/35
origin_branch: work-20260404-101424-fix-trip-report-dir-path
origin_commit: cc5de17
last_seen: 2026-05-19T11:48:42+09:00
closed: resolved
resolved_by_pr: 10b1249
---

- The consolidated lead agent preloads all 14 skills (10 domain + 4 framework), increasing context consumption per invocation. Currently acceptable (~300-400 lines) but may need revisiting if lead skills grow significantly. (from architectural analysis)
- Consolidate the 3 manager agents (project-manager, architecture-manager, quality-manager) using the same parameterized pattern -- they follow a similar dispatcher structure
