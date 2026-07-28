---
type: Feedback
title: the-17-agent-parallel-invocation-from
kind: concern
source: development
created_at: 2026-05-19T11:48:40+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-17-agent-parallel-invocation-from
owner: 
mission: 
tickets: []
origin_pr: 22
origin_pr_url: https://github.com/qmu/workaholic/pull/22
origin_branch: drive-20260205-195920
origin_commit: cc5de17
last_seen: 2026-05-19T11:48:40+09:00
closed: resolved
resolved_by_pr: d4352d5
---

- The 17-agent parallel invocation from scanner is the highest parallelism attempted in this codebase; runtime behavior at this scale has not been verified (see [12d9509](https://github.com/qmu/workaholic/commit/12d9509) in `plugins/core/agents/scanner.md`)
