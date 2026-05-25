---
origin_pr: 28
origin_pr_url: https://github.com/qmu/workaholic/pull/28
origin_branch: drive-20260310-220224
origin_commit: cc5de17
created_at: 2026-05-19T11:48:40+09:00
status: resolved
resolved_by_pr: 
resolved_by_commit: 
---
- The `/ship-drive` and `/ship-trip` commands execute arbitrary deployment instructions from user-provided `cloud.md` files; while a confirmation step was added, the deploy step ultimately executes whatever the user has documented (see [d764af2](https://github.com/qmu/workaholic/commit/d764af2) in `plugins/drivin/commands/ship-drive.md`)
