---
type: Feedback
title: One extra tree walk per unresolved artifact, on the five-minute path
kind: concern
source: development
created_at: 2026-08-04T12:46:15+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: one-extra-tree-walk-per-unresolved
owner: 
mission: []
tickets: [20260804023100-claim-survey-reads-wrong-coordinate.md]
origin_pr: 178
origin_pr_url: https://github.com/qmu/workaholic/pull/178
origin_branch: work-20260804-105730
origin_commit: 6264039f
last_seen: 2026-08-04T12:46:15+09:00
---

# One extra tree walk per unresolved artifact, on the five-minute path

## Description

When the rename map misses, the fallback runs `git ls-tree -r` over

## How to Fix

Cache the tip's ticket listing once per claim branch rather than once
