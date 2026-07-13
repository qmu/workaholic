---
type: Concern
concern_id: the-living-migration-commits-a-large
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

# The living migration commits a large one-time churn inside a normal /report commit

## Description

The first collapse renamed/moved ~200 concern files; those staged moves ride the Phase 4 story commit, producing a very large, hard-to-review diff bundled with the story (see [b33d64f](https://github.com/qmu/workaholic/commit/b33d64f)).

## How to Fix

Consider committing the migration collapse as its own dedicated commit (separate from the story), or gate it behind a one-time `migrate` invocation, so the healing diff is reviewable on its own.
