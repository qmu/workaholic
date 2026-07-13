---
type: Concern
mission: 
tickets: [20260707104117-fix-installed-script-helper-resolution.md, 20260707220735-guard-hook-scripts-executable.md, 20260709023255-catch-scan-mission-join.md, 20260709023256-catch-report-missions-section.md]
origin_pr: 80
origin_pr_url: https://github.com/qmu/workaholic/pull/80
origin_branch: work-20260707-104047
origin_commit: cf6a1d8
created_at: 2026-07-09T03:28:39+09:00
superseded_by: enforcement-reaches-consumer-repos-only-after
last_seen: 2026-07-09T03:28:39+09:00
first_seen: 2026-07-09T03:28:39+09:00
concern_id: enforcement-reaches-consumer-repos-only-after
severity: moderate
status: superseded
resolved_by_pr: 
resolved_by_commit: 
---

# (carried from PR #58 → #56) Enforcement reaches consumer repos only after landing on main

## Description

Enforcement rules reach external consumers only after this repo lands on main and they reinstall; intermediate PRs have no active enforcement in consumer installs.

## How to Fix

Publish a pre-release/canary for consumer testing, or accept that enforcement lags until release.
