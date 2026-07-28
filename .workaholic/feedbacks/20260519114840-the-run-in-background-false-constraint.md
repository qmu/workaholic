---
type: Feedback
title: the-run-in-background-false-constraint
kind: concern
source: development
created_at: 2026-05-19T11:48:40+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-run-in-background-false-constraint
owner: 
mission: 
tickets: []
origin_pr: 23
origin_pr_url: https://github.com/qmu/workaholic/pull/23
origin_branch: drive-20260208-131649
origin_commit: cc5de17
last_seen: 2026-05-19T11:48:40+09:00
closed: resolved
resolved_by_pr: d4352d5
---

- The `run_in_background: false` constraint is a documentation-level safeguard, not a runtime enforcement mechanism; its effectiveness depends on Claude Code respecting the instruction (see [d627919](https://github.com/qmu/workaholic/commit/d627919) in `plugins/core/commands/scan.md`)
