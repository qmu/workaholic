---
origin_pr: 69
origin_pr_url: https://github.com/qmu/workaholic/pull/69
origin_branch: work-20260701-171611
origin_commit: e3c3a4b
created_at: 2026-07-01T21:16:06+09:00
last_seen: 2026-07-06T11:31:52+09:00
first_seen: 2026-07-01T21:16:06+09:00
concern_id: best-effort-fetch-adds-a-per
severity: moderate
status: accepted
resolved_by_pr: 
resolved_by_commit: 
closed_reason: Promoted to ticket 20260716163002-catch-scan-window-blind-spots.md (2026-07-16 triage-to-zero): bound the /catch fetch with a timeout or opt-out. Risk now tracked in the queue.
closed_at: 2026-07-16T17:09:32+09:00
---

# Best-effort fetch adds a per-run network round-trip to /catch

## Description

`scan-window.sh` now runs `git fetch --all` on every `/catch` invocation, adding a network round-trip and measurable latency on large remotes; it is `--quiet` and best-effort, but the cost is paid on every report run (see [ad4ea8d](https://github.com/qmu/workaholic/commit/ad4ea8d) in `plugins/workaholic/skills/catch/scripts/scan-window.sh`; ticket Considerations "Performance").

## How to Fix

Consider a bounded fetch timeout or an opt-out flag for large remotes so a slow or unresponsive remote cannot stall the report.
