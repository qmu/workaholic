---
type: Feedback
title: A delete-only commit of any size now passes
kind: concern
source: development
created_at: 2026-08-04T12:52:52+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: a-delete-only-commit-of-any
owner: 
mission: make-the-per-commit-changed-lines-ceiling-a-rule-that-holds
tickets: [20260801185101-decide-what-too-large-commit-counts.md, 20260801185102-implement-the-chosen-commit-size-semantics.md]
origin_pr: 167
origin_pr_url: https://github.com/qmu/workaholic/pull/167
origin_branch: work-20260801-210440
origin_commit: 287bc95c
last_seen: 2026-08-04T12:52:52+09:00
---

# A delete-only commit of any size now passes

## Description

Counting additions only means a commit that removes 5,000 lines is never flagged. This is the intended reading — removing code is cheap to review and worth encouraging — but it is a genuine widening of what the gate lets through, and a very large deletion is not always trivial to review (`plugins/workaholic/skills/release-scan/scripts/lib/commit-size.sh`).

## How to Fix

Nothing now; it is pinned by a test so it cannot drift silently. If a large deletion ever does harm, the answer is a separate, much higher deletion ceiling rather than restoring added+deleted, which is what charged relocations twice.
