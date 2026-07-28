---
type: Feedback
title: generated-documentation-under-workaholic-specs-and
kind: concern
source: development
created_at: 2026-05-19T11:48:40+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: generated-documentation-under-workaholic-specs-and
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

- Generated documentation under `.workaholic/specs/` and `.workaholic/policies/` still contains `plugins/core` references that will persist until the next `/scan` run (see [54b0146](https://github.com/qmu/workaholic/commit/54b0146) in `plugins/drivin/skills/*/SKILL.md`)
