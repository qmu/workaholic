---
kind: concern
origin_pr: 38
origin_pr_url: https://github.com/qmu/workaholic/pull/38
origin_branch: work-20260415-163724
origin_commit: cc5de17
created_at: 2026-05-19T11:48:42+09:00
status: resolved
resolved_by_pr: d4352d5
resolved_by_commit: 
paired_slug: 38-the-scan-command-s-policy-validation
housekeeping_ticket_emitted: false
---

- The scan command's policy validation list was updated to remove `observability.md` and `delivery.md` but still references `recovery.md` which was removed in a previous branch -- this may cause validation warnings (see [10b1249](https://github.com/qmu/workaholic/commit/10b1249) in `plugins/core/commands/scan.md`)
