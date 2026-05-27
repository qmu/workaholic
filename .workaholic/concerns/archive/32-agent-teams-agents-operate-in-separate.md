---
origin_pr: 32
origin_pr_url: https://github.com/qmu/workaholic/pull/32
origin_branch: drive-20260326-183949
origin_commit: cc5de17
created_at: 2026-05-19T11:48:41+09:00
status: resolved
resolved_by_pr: 
resolved_by_commit: 
---
- Agent Teams agents operate in separate context windows and may not reliably inherit plugin rules from the `rules/` directory; the three-layer redundancy (rule file + agent definitions + team lead instructions) is a mitigation, not a guarantee (see [bc9f189](https://github.com/qmu/workaholic/commit/bc9f189) in `plugins/trippin/rules/i18n.md`)
