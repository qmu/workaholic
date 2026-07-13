---
origin_pr: 44
origin_pr_url: https://github.com/qmu/workaholic/pull/44
origin_branch: work-20260617-082241
origin_commit: ba49fe6
created_at: 2026-06-17T20:14:03+09:00
last_seen: 2026-06-17T20:14:03+09:00
first_seen: 2026-06-17T20:14:03+09:00
concern_id: carry-over-concern-set-has-ballooned
severity: moderate
status: resolved
resolved_by_pr: 49
resolved_by_commit: e390172
---

# Carry-over concern set has ballooned to ~14 active from ~6 unique

## Description

The still-active set carries chained duplicates (`41-*`, `42-carried-from-41-*`, `43-carried-from-41-*`, `43-carried-from-42-*`). Root causes: the `apply-carryover-verdicts.sh` silent-skip bug above (resolved items never leave the dir) and no dedup in `extract-carryover.sh` (identical concerns re-emitted every ship).

## How to Fix

Fix the apply-script bug first, then add dedup-by-canonical-identity (basename/content hash) to `extract-carryover.sh` before re-emitting, so duplicates merge rather than compound.
