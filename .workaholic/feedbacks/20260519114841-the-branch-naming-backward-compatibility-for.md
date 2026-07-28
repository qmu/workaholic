---
type: Feedback
title: the-branch-naming-backward-compatibility-for
kind: concern
source: development
created_at: 2026-05-19T11:48:41+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-branch-naming-backward-compatibility-for
owner: 
mission: 
tickets: []
origin_pr: 34
origin_pr_url: https://github.com/qmu/workaholic/pull/34
origin_branch: drive-20260403-230430
origin_commit: cc5de17
last_seen: 2026-05-19T11:48:41+09:00
closed: resolved
---

- The branch naming backward compatibility for `drive-*` and `trip/*` patterns adds complexity to `detect-context.sh` that should eventually be removed once all legacy branches are merged (see [90b1e84](https://github.com/qmu/workaholic/commit/90b1e84) in `plugins/core/skills/branching/scripts/detect-context.sh`)
