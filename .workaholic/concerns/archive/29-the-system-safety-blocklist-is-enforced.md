---
origin_pr: 29
origin_pr_url: https://github.com/qmu/workaholic/pull/29
origin_branch: drive-20260311-125319
origin_commit: cc5de17
created_at: 2026-05-19T11:48:41+09:00
last_seen: 2026-05-19T11:48:41+09:00
first_seen: 2026-05-19T11:48:41+09:00
concern_id: the-system-safety-blocklist-is-enforced
status: resolved
resolved_by_pr: 
resolved_by_commit: 
---
- The system-safety blocklist is enforced through agent instructions rather than a technical sandbox; agents in separate context windows could bypass the restriction if the constraint text is not retained in context (see [e48d523](https://github.com/qmu/workaholic/commit/e48d523) in `plugins/drivin/skills/system-safety/SKILL.md`)
