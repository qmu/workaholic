---
type: Feedback
title: six-lead-skill-files-were-deleted
kind: concern
source: development
created_at: 2026-05-19T11:48:42+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: six-lead-skill-files-were-deleted
owner: 
mission: 
tickets: []
origin_pr: 38
origin_pr_url: https://github.com/qmu/workaholic/pull/38
origin_branch: work-20260415-163724
origin_commit: cc5de17
last_seen: 2026-05-19T11:48:42+09:00
closed: resolved
resolved_by_pr: 86a048c
---

- Six lead skill files were deleted (lead-db, lead-delivery, lead-observability, lead-quality, lead-reliability, lead-ux); any external tooling or documentation referencing these filenames by path will need updating (see [10b1249](https://github.com/qmu/workaholic/commit/10b1249) in `plugins/standards/skills/`)
- Consider whether the viewpoint/policy distinction still warrants two separate analysis frameworks now that only one domain (accessibility) uses the viewpoint path -- merging or simplifying the analysis skills could reduce complexity
