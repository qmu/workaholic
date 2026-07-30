---
type: Feedback
title: The scan cost grew by one diff per claim, on the five-minute path
kind: concern
source: development
created_at: 2026-07-30T19:47:51+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: the-scan-cost-grew-by-one
owner: 
mission: []
tickets: [20260730180248-claim-reader-loses-artifacts-on-archive.md, 20260730181500-plan-floor-counts-acceptance-not-queue.md]
origin_pr: 112
origin_pr_url: https://github.com/qmu/workaholic/pull/112
origin_branch: work-20260730-191139
origin_commit: dfaaf654
last_seen: 2026-07-30T19:47:51+09:00
---

# The scan cost grew by one diff per claim, on the five-minute path

## Description

`claims_scan` now runs `git diff --find-renames` between each claim commit and its branch tip (see [bba6f0dc](https://github.com/qmu/workaholic/commit/bba6f0dc)). It was chosen over a per-file `git log --follow` precisely because it is one call per claim rather than per artifact, but it is still new work on a path the routine executes every five minutes, and its cost grows with a claim branch's diff size rather than its artifact count.

## How to Fix

If a tick's survey latency becomes noticeable, bound it by restricting the diff to `.workaholic/` (`git diff --find-renames <sha> <ref> -- .workaholic/`), which is the only tree claims can name. Measure before changing — the current form is correct and the optimisation narrows what the reader can see.
