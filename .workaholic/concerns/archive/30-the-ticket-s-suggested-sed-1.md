---
origin_pr: 30
origin_pr_url: https://github.com/qmu/workaholic/pull/30
origin_branch: drive-20260312-102414
origin_commit: cc5de17
created_at: 2026-05-19T11:48:41+09:00
status: resolved
resolved_by_pr: 
resolved_by_commit: 
---
- The ticket's suggested `sed '1{/^---$/,/^---$/d}'` pattern for frontmatter stripping was discovered to be incorrect at implementation time; the actual implementation uses an awk one-liner instead (see [9cab3fd](https://github.com/qmu/workaholic/commit/9cab3fd) in `plugins/drivin/skills/create-pr/sh/strip-frontmatter.sh`)
