---
type: Feedback
title: The append-shape scope is bounded by path, deliberately
kind: concern
source: development
created_at: 2026-08-05T04:47:12+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: the-append-shape-scope-is-bounded
owner: 
mission: []
tickets: [20260804214500-merge-pr-sh-reports-the-branch-head.md, 20260804214600-catchup-main-sh-classes-an-append-only-conflict.md]
origin_pr: 219
origin_pr_url: https://github.com/qmu/workaholic/pull/219
origin_branch: work-20260804-185735
origin_commit: fc54c9d8
last_seen: 2026-08-05T04:47:12+09:00
---

# The append-shape scope is bounded by path, deliberately

## Description

The shape test proves both sides only appended, but it is applied only to

## How to Fix

Nothing, unless such a file appears. If one does, widen the path bound to
