---
origin_pr: 22
origin_pr_url: https://github.com/qmu/workaholic/pull/22
origin_branch: drive-20260205-195920
origin_commit: cc5de17
created_at: 2026-05-19T11:48:40+09:00
status: resolved
resolved_by_pr: d4352d5
resolved_by_commit: 
---
- The effort validation uses a hardcoded allowlist in `update.sh`; if new effort values are added, both the script and the hook must be updated in sync (see [ae47bf6](https://github.com/qmu/workaholic/commit/ae47bf6) in `plugins/core/skills/update-ticket-frontmatter/sh/update.sh`)
