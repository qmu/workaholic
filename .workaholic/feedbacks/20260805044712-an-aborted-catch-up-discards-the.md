---
type: Feedback
title: An aborted catch-up discards the append resolutions it computed
kind: concern
source: development
created_at: 2026-08-05T04:47:12+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: an-aborted-catch-up-discards-the
owner: 
mission: []
tickets: [20260804214500-merge-pr-sh-reports-the-branch-head.md, 20260804214600-catchup-main-sh-classes-an-append-only-conflict.md]
origin_pr: 219
origin_pr_url: https://github.com/qmu/workaholic/pull/219
origin_branch: work-20260804-185735
origin_commit: fc54c9d8
last_seen: 2026-08-05T04:47:12+09:00
---

# An aborted catch-up discards the append resolutions it computed

## Description

When manifest or content conflicts remain, the merge is aborted so the

## How to Fix

Acceptable as is. Leaving the merge in progress would break the "caller acts
