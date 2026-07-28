---
type: Feedback
title: workaholic-specs-stakeholder-md-is-owned
kind: concern
source: development
created_at: 2026-05-19T11:48:42+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: workaholic-specs-stakeholder-md-is-owned
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

- `.workaholic/specs/stakeholder.md` is owned by `analyze-viewpoint` but has no agent that calls it now that `/scan` is retired; it must be treated as hand-maintained (see [174b988](https://github.com/qmu/workaholic/commit/174b988) in `.workaholic/specs/stakeholder.md`)
