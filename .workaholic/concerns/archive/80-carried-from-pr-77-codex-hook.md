---
type: Concern
mission: 
tickets: [20260707104117-fix-installed-script-helper-resolution.md, 20260707220735-guard-hook-scripts-executable.md, 20260709023255-catch-scan-mission-join.md, 20260709023256-catch-report-missions-section.md]
origin_pr: 80
origin_pr_url: https://github.com/qmu/workaholic/pull/80
origin_branch: work-20260707-104047
origin_commit: cf6a1d8
created_at: 2026-07-09T03:28:39+09:00
superseded_by: codex-hook-runtime-behavior-remains-unproven
last_seen: 2026-07-09T03:28:39+09:00
first_seen: 2026-07-09T03:28:39+09:00
concern_id: codex-hook-runtime-behavior-remains-unproven
severity: moderate
status: superseded
resolved_by_pr: 
resolved_by_commit: 
---

# (carried from PR #77) Codex hook runtime behavior remains unproven in deployed installations

## Description

Codex plugin hooks are CI-validated for syntax but their runtime behavior (event firing, path resolution, tool interception) is untested against real Codex deployments.

## How to Fix

Add integration tests exercising a real Codex install reading the plugin manifest, or document the scope boundary and make Codex runtime validation a separate campaign.
