---
type: Concern
mission: 
tickets: [20260713103820-mission-active-archive-split-and-close.md]
origin_pr: 82
origin_pr_url: https://github.com/qmu/workaholic/pull/82
origin_branch: work-20260713-102453
origin_commit: 5d2efad
created_at: 2026-07-13T11:56:22+09:00
severity: moderate
status: active
resolved_by_pr:
resolved_by_commit:
---

# Hermetic tests prove migration, not local use (repo has no missions)

## Description

The migration mechanism is validated only by hermetic test cases (test-workflow-scripts.mjs) that create throwaway repos with fake legacy missions. This repository has no actual missions of its own, so the migration logic cannot be proven by real usage before release.

## How to Fix

After release, run /catch and other mission scripts on a deployed consumer repo that did adopt the flat layout; verify no unexpected regressions. Consider adding a canary check to the release notes asking early adopters to report migration behavior.
