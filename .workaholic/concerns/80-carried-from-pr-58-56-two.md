---
type: Concern
mission: 
tickets: [20260707104117-fix-installed-script-helper-resolution.md, 20260707220735-guard-hook-scripts-executable.md, 20260709023255-catch-scan-mission-join.md, 20260709023256-catch-report-missions-section.md]
origin_pr: 80
origin_pr_url: https://github.com/qmu/workaholic/pull/80
origin_branch: work-20260707-104047
origin_commit: cf6a1d8
created_at: 2026-07-09T03:28:39+09:00
severity: moderate
status: active
resolved_by_pr:
resolved_by_commit:
---

# (carried from PR #58 → #56) Two enforcement layers encode one rule

## Description

The commit-msg and PreToolUse hooks duplicate the subject-rule enforcement; a rule change must update both.

## How to Fix

Both already source `check-subject.sh`; add a CI test that verifies they reference the same rule version.
