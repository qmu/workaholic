---
origin_pr: 38
origin_pr_url: https://github.com/qmu/workaholic/pull/38
origin_branch: work-20260415-163724
origin_commit: cc5de17
created_at: 2026-05-19T11:48:42+09:00
last_seen: 2026-05-19T11:48:42+09:00
first_seen: 2026-05-19T11:48:42+09:00
concern_id: six-lead-skill-files-were-deleted
status: resolved
resolved_by_pr: 86a048c
resolved_by_commit: 
---
- Six lead skill files were deleted (lead-db, lead-delivery, lead-observability, lead-quality, lead-reliability, lead-ux); any external tooling or documentation referencing these filenames by path will need updating (see [10b1249](https://github.com/qmu/workaholic/commit/10b1249) in `plugins/standards/skills/`)
- Consider whether the viewpoint/policy distinction still warrants two separate analysis frameworks now that only one domain (accessibility) uses the viewpoint path -- merging or simplifying the analysis skills could reduce complexity
