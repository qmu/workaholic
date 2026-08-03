---
type: Feedback
title: The Motivation fold is a prose contract with no machine check
kind: concern
source: development
created_at: 2026-08-03T22:11:21+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: the-motivation-fold-is-a-prose
owner: 
mission: [make-the-branch-story-concise-by-default]
tickets: [20260801185701-decide-the-fate-of-low-severity-concerns.md, 20260801185702-make-the-story-short-by-default.md]
origin_pr: 171
origin_pr_url: https://github.com/qmu/workaholic/pull/171
origin_branch: work-20260803-212338
origin_commit: 9084360e
last_seen: 2026-08-03T22:11:21+09:00
---

# The Motivation fold is a prose contract with no machine check

## Description

`historical_context` reaches the story only if the report orchestration appends it to Motivation, which is instruction text in `report/SKILL.md` rather than code. A worker that returns the field into a story that never renders it loses the paragraph silently — the same shape of failure the section-number coupling had, minus a consumer to test.

## How to Fix

Nothing now; the field is optional and empty on most branches, so the blast radius is one paragraph. If stories start losing past context, the fix is to have the story writer emit Motivation from both fields explicitly rather than by instruction.
