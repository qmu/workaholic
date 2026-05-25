---
origin_pr: 23
origin_pr_url: https://github.com/qmu/workaholic/pull/23
origin_branch: drive-20260208-131649
origin_commit: cc5de17
created_at: 2026-05-19T11:48:40+09:00
status: resolved
resolved_by_pr: d4352d5
resolved_by_commit: 
---
- The `run_in_background: false` constraint is a documentation-level safeguard, not a runtime enforcement mechanism; its effectiveness depends on Claude Code respecting the instruction (see [d627919](https://github.com/qmu/workaholic/commit/d627919) in `plugins/core/commands/scan.md`)
