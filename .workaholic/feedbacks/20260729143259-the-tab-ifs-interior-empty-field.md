---
type: Feedback
title: The tab-IFS interior-empty-field hazard recurs across the skill scripts, untested
kind: concern
source: development
created_at: 2026-07-29T14:32:59+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: the-tab-ifs-interior-empty-field
owner: a@qmu.jp
mission: [loop-engineering-unified-drive]
tickets: [20260728221801-unify-mission-status-and-merge-policy.md, 20260728221802-add-claim-protocol-scripts.md, 20260728221803-unify-drive-executor.md, 20260728221804-retire-monitor-trip-carry.md]
origin_pr: 100
origin_pr_url: https://github.com/qmu/workaholic/pull/100
origin_branch: work-20260728-221717
origin_commit: 2aca03e3
last_seen: 2026-07-29T14:32:59+09:00
---

# The tab-IFS interior-empty-field hazard recurs across the skill scripts, untested

## Description

`apply-deferred-concern-verdicts.sh` shifted a commit hash into the `resolved_by_pr` column whenever that field was absent, because tab is IFS *whitespace*: `read` collapses consecutive tabs into one delimiter, so an **interior** empty field shifts every later column left (fixed in [c8f23204](https://github.com/qmu/workaholic/commit/c8f23204) with an absent-field sentinel and four regression tests). The idiom recurs seven more times in the same script family — `doc-drift.sh:78` (`IFS="${TAB}" read -r st p1 p2`) and six loops in `release-scan/scripts/scan-branch-safety.sh`. None is a live bug: `doc-drift.sh`'s optional `p2` is a **trailing** field, which `read` handles correctly and which is additionally guarded (`[ -n "${p2:-}" ]` with a `p1` fallback), and the scan's columns are always populated. The distinction between a harmless trailing empty and a corrupting interior one is exactly what makes this class hard to spot, and no regression test pins any of those guards the way the four new tests pin the fixed script — which matters most for `scan-branch-safety.sh`, since it is a merge gate.

## How to Fix

Extract the tab-split-with-sentinel primitive the fix introduced so every consumer shares one hardened implementation rather than repeating the guard; failing that, add a regression case pinning `doc-drift.sh`'s non-rename (`A`/`D`/`M`) parsing beside its rename (`R`) parsing, and treat "does any column here become empty while a later one is populated?" as a review question whenever a tab-delimited `read` loop is added or touched.
