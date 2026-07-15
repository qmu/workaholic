---
type: Concern
mission: 
tickets: [20260707104117-fix-installed-script-helper-resolution.md, 20260707220735-guard-hook-scripts-executable.md, 20260709023255-catch-scan-mission-join.md, 20260709023256-catch-report-missions-section.md]
origin_pr: 80
origin_pr_url: https://github.com/qmu/workaholic/pull/80
origin_branch: work-20260707-104047
origin_commit: cf6a1d8
created_at: 2026-07-09T03:28:39+09:00
last_seen: 2026-07-09T03:28:39+09:00
first_seen: 2026-07-09T03:28:39+09:00
concern_id: commit-can-emit-off-policy-subjects
severity: low
status: superseded
resolved_by_pr: 
resolved_by_commit: 
superseded_by: commit-subject-rule-binds-on-no-path
---

# (carried from PR #59) /commit can emit off-policy subjects if invoked directly

## Description

`/commit` accepts a freeform subject without validating it against the subject rule.

## How to Fix

Call `check-subject.sh` inside `/commit` and reject/re-prompt on an off-policy subject.
