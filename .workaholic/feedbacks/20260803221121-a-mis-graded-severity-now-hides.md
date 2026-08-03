---
type: Feedback
title: A mis-graded severity now hides a concern from review, not just from a sort order
kind: concern
source: development
created_at: 2026-08-03T22:11:21+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: a-mis-graded-severity-now-hides
owner: 
mission: [make-the-branch-story-concise-by-default]
tickets: [20260801185701-decide-the-fate-of-low-severity-concerns.md, 20260801185702-make-the-story-short-by-default.md]
origin_pr: 171
origin_pr_url: https://github.com/qmu/workaholic/pull/171
origin_branch: work-20260803-212338
origin_commit: 9084360e
last_seen: 2026-08-03T22:11:21+09:00
---

# A mis-graded severity now hides a concern from review, not just from a sort order

## Description

Severity used to be an honest signal that rode on the extracted record. It now also decides whether the reviewer sees the block at all, so a concern graded `low` when it is really `moderate` is recorded correctly and reviewed by nobody (`plugins/workaholic/skills/report/scripts/filter-low-concerns.sh`). The grading is a model judgment with no machine check, which is exactly the class of thing that drifts quietly.

## How to Fix

Both mirrors now say to grade honestly in both directions and name this consequence. If the drift shows up in practice, the measurable version is a periodic read of the stream's `low` records asking how many were later re-raised at a higher severity.
