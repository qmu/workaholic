---
type: Concern
concern_id: triage-threshold-and-compound-detection-are
mission: 
tickets: [20260713144839-worktree-copies-root-env.md, 20260713203444-concern-identity-update-in-place.md, 20260713203445-report-concern-triage-and-compound-merge.md]
origin_pr: 83
origin_pr_url: https://github.com/qmu/workaholic/pull/83
origin_branch: work-20260713-144839
origin_commit: fbceaaa
created_at: 2026-07-13T23:39:50+09:00
first_seen: 2026-07-13T23:39:50+09:00
last_seen: 2026-07-13T23:39:50+09:00
severity: low
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# Triage threshold and compound detection are prose-driven, not enforced

## Description

The count threshold (20) and the "judge proposes compounds" step live in report SKILL prose, not a machine check (see [da318d7](https://github.com/qmu/workaholic/commit/da318d7) in `plugins/workaholic/skills/report/SKILL.md`) — matching the repo's existing prose-gate precedent, but skippable.

## How to Fix

If enforcement is wanted, have `list-active` emit the active count and a `should_triage` flag the command can branch on mechanically.
