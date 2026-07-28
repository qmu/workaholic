---
type: Feedback
title: command-consolidation-risk-merging-branch-into
kind: concern
source: development
created_at: 2026-05-19T11:48:42+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: command-consolidation-risk-merging-branch-into
owner: 
mission: 
tickets: []
origin_pr: 12
origin_pr_url: https://github.com/qmu/workaholic/pull/12
origin_branch: feat-20260128-220712
origin_commit: cc5de17
last_seen: 2026-05-19T11:48:42+09:00
closed: resolved
---

- **Command Consolidation Risk**: Merging `/branch` into `/ticket` adds complexity to the ticket command. Users who want to create a branch without writing a ticket have lost a convenience function.
