---
origin_pr: 69
origin_pr_url: https://github.com/qmu/workaholic/pull/69
origin_branch: work-20260701-171611
origin_commit: e3c3a4b
created_at: 2026-07-01T21:16:06+09:00
severity: moderate
status: active
resolved_by_pr:
resolved_by_commit:
---

# (carried from PR #60) Collectors sample branch stories by title at scale

## Description

`/catch` collectors sample branch stories by title, which does not scale cleanly as story counts grow; this branch changed ref scanning, not story sampling, so the indexing gap remains (deferred concern `.workaholic/concerns/60-collectors-sample-branch-stories-by-title.md`).

## How to Fix

Introduce a story index/identifier so sampling does not rely on title matching at scale.
