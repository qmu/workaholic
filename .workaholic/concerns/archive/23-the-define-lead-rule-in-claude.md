---
origin_pr: 23
origin_pr_url: https://github.com/qmu/workaholic/pull/23
origin_branch: drive-20260208-131649
origin_commit: cc5de17
created_at: 2026-05-19T11:48:40+09:00
last_seen: 2026-05-19T11:48:40+09:00
first_seen: 2026-05-19T11:48:40+09:00
concern_id: the-define-lead-rule-in-claude
status: resolved
resolved_by_pr: 
resolved_by_commit: 
---
- The define-lead rule in `.claude/rules/` only activates when editing lead files -- it does not prevent someone from creating a non-conforming agent file with a different naming pattern that bypasses the glob (see [2a89029](https://github.com/qmu/workaholic/commit/2a89029) in `.claude/rules/define-lead.md`)
