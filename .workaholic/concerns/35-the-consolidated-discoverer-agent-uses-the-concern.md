---
kind: concern
origin_pr: 35
origin_pr_url: https://github.com/qmu/workaholic/pull/35
origin_branch: work-20260404-101424-fix-trip-report-dir-path
origin_commit: cc5de17
created_at: 2026-05-19T11:48:42+09:00
status: active
resolved_by_pr:
resolved_by_commit:
paired_slug: 35-the-consolidated-discoverer-agent-uses-the
housekeeping_ticket_emitted: false
---

- The consolidated discoverer agent uses the union of tools (Bash, Read, Glob, Grep), meaning source and ticket modes gain Bash access they previously lacked. This is a minor tool scope relaxation. (from architectural analysis)
