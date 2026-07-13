---
origin_pr: 33
origin_pr_url: https://github.com/qmu/workaholic/pull/33
origin_branch: drive-20260329-173608
origin_commit: cc5de17
created_at: 2026-05-19T11:48:41+09:00
last_seen: 2026-05-19T11:48:41+09:00
first_seen: 2026-05-19T11:48:41+09:00
concern_id: the-consolidated-drive-skill-in-drivin
status: resolved
resolved_by_pr: 
resolved_by_commit: 
---
- The consolidated `drive` skill in drivin is approximately 400+ lines, exceeding the design principle guideline of 50-150 lines per skill, though the alternative of 5 separate directories was deemed worse for navigability (see [e1b8696](https://github.com/qmu/workaholic/commit/e1b8696) in `plugins/drivin/skills/drive/SKILL.md`)
- The `dependencies` field in plugin.json is currently a documentation convention; future marketplace releases could enforce it by refusing to load plugins with unsatisfied dependencies
