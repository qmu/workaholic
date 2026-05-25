---
origin_pr: 26
origin_pr_url: https://github.com/qmu/workaholic/pull/26
origin_branch: drive-20260213-131416
origin_commit: cc5de17
created_at: 2026-05-19T11:48:40+09:00
status: resolved
resolved_by_pr: 
resolved_by_commit: 
---
- The `archive.sh` script uses `git add -A` which stages everything including unrelated changes; while this is intentional for catching both deletion and addition paths, it could inadvertently stage work-in-progress files (see [9e54500](https://github.com/qmu/workaholic/commit/9e54500) in `plugins/core/skills/archive-ticket/SKILL.md`)
