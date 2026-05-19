---
kind: idea
origin_pr: 22
origin_pr_url: https://github.com/qmu/workaholic/pull/22
origin_branch: drive-20260205-195920
origin_commit: cc5de17
created_at: 2026-05-19T11:48:40+09:00
status: active
resolved_by_pr:
resolved_by_commit:
paired_slug:
housekeeping_ticket_emitted: false
---

- The 17-agent parallel invocation from scanner is the highest parallelism attempted in this codebase; runtime behavior at this scale has not been verified (see [12d9509](https://github.com/qmu/workaholic/commit/12d9509) in `plugins/core/agents/scanner.md`)
