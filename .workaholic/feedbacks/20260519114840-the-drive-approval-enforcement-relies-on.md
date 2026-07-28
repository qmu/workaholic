---
type: Feedback
title: the-drive-approval-enforcement-relies-on
kind: concern
source: development
created_at: 2026-05-19T11:48:40+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-drive-approval-enforcement-relies-on
owner: 
mission: 
tickets: []
origin_pr: 27
origin_pr_url: https://github.com/qmu/workaholic/pull/27
origin_branch: drive-20260302-213941
origin_commit: cc5de17
last_seen: 2026-05-19T11:48:40+09:00
closed: resolved
---

- The drive approval enforcement relies on language strength ("CRITICAL", "failure condition") rather than programmatic validation, which may still be circumvented by the agent (see [3464009](https://github.com/qmu/workaholic/commit/3464009) in `plugins/drivin/skills/drive-approval/SKILL.md`)
