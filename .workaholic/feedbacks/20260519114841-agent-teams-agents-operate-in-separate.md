---
type: Feedback
title: agent-teams-agents-operate-in-separate
kind: concern
source: development
created_at: 2026-05-19T11:48:41+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: agent-teams-agents-operate-in-separate
owner: 
mission: 
tickets: []
origin_pr: 32
origin_pr_url: https://github.com/qmu/workaholic/pull/32
origin_branch: drive-20260326-183949
origin_commit: cc5de17
last_seen: 2026-05-19T11:48:41+09:00
closed: resolved
---

- Agent Teams agents operate in separate context windows and may not reliably inherit plugin rules from the `rules/` directory; the three-layer redundancy (rule file + agent definitions + team lead instructions) is a mitigation, not a guarantee (see [bc9f189](https://github.com/qmu/workaholic/commit/bc9f189) in `plugins/trippin/rules/i18n.md`)
