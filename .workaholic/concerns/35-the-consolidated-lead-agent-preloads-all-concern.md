---
kind: concern
origin_pr: 35
origin_pr_url: https://github.com/qmu/workaholic/pull/35
origin_branch: work-20260404-101424-fix-trip-report-dir-path
origin_commit: cc5de17
created_at: 2026-05-19T11:48:42+09:00
status: resolved
resolved_by_pr: 10b1249
resolved_by_commit: 
paired_slug: 35-the-consolidated-lead-agent-preloads-all
housekeeping_ticket_emitted: false
---

- The consolidated lead agent preloads all 14 skills (10 domain + 4 framework), increasing context consumption per invocation. Currently acceptable (~300-400 lines) but may need revisiting if lead skills grow significantly. (from architectural analysis)
