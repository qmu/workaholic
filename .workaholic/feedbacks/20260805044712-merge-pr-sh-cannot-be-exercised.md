---
type: Feedback
title: merge-pr.sh cannot be exercised end to end hermetically
kind: concern
source: development
created_at: 2026-08-05T04:47:12+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: merge-pr-sh-cannot-be-exercised
owner: 
mission: []
tickets: [20260804214500-merge-pr-sh-reports-the-branch-head.md, 20260804214600-catchup-main-sh-classes-an-append-only-conflict.md]
origin_pr: 219
origin_pr_url: https://github.com/qmu/workaholic/pull/219
origin_branch: work-20260804-185735
origin_commit: fc54c9d8
last_seen: 2026-08-05T04:47:12+09:00
---

# merge-pr.sh cannot be exercised end to end hermetically

## Description

The script requires `gh` and a real pull request, so the tests assert on

## How to Fix

The next real ship through this path is the end-to-end test — read
