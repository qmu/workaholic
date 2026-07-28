---
type: Feedback
title: the-workaholic-specs-files-that-reference
kind: concern
source: development
created_at: 2026-05-19T11:48:40+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-workaholic-specs-files-that-reference
owner: 
mission: 
tickets: []
origin_pr: 23
origin_pr_url: https://github.com/qmu/workaholic/pull/23
origin_branch: drive-20260208-131649
origin_commit: cc5de17
last_seen: 2026-05-19T11:48:40+09:00
closed: resolved
---

- The `.workaholic/specs/` files that reference old analyst names (e.g., `accessibility-policy-analyst`, `stakeholder-analyst`) will show stale references until the next `/scan` run regenerates them (see [998285d](https://github.com/qmu/workaholic/commit/998285d) in `plugins/core/agents/a11y-lead.md`)
