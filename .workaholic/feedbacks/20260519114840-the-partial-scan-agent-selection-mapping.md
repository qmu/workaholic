---
type: Feedback
title: the-partial-scan-agent-selection-mapping
kind: concern
source: development
created_at: 2026-05-19T11:48:40+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-partial-scan-agent-selection-mapping
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

- The partial-scan agent selection mapping is heuristic and may miss cross-cutting changes that affect viewpoints not triggered by the diff path rules (see [6b86f7d](https://github.com/qmu/workaholic/commit/6b86f7d) in `plugins/core/skills/select-scan-agents/sh/select.sh`)
