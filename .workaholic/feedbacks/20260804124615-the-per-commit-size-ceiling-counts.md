---
type: Feedback
title: The per-commit size ceiling counts a catch-up merge as authored work
kind: concern
source: development
created_at: 2026-08-04T12:46:15+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-per-commit-size-ceiling-counts
owner: 
mission: []
tickets: [20260804023100-claim-survey-reads-wrong-coordinate.md]
origin_pr: 178
origin_pr_url: https://github.com/qmu/workaholic/pull/178
origin_branch: work-20260804-105730
origin_commit: 6264039f
last_seen: 2026-08-04T12:46:15+09:00
---

# The per-commit size ceiling counts a catch-up merge as authored work

## Description

Every one of the four branches shipped after the first hit

## How to Fix

Exempt a merge commit whose second parent is an ancestor of the base, or
