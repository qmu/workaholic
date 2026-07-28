---
type: Feedback
title: (carried from PR #41) Script rename requires stale artifact cleanup
kind: concern
source: development
created_at: 2026-06-16T08:57:05+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: script-rename-requires-stale-artifact-cleanup
owner: 
mission: 
tickets: []
origin_pr: 42
origin_pr_url: https://github.com/qmu/workaholic/pull/42
origin_branch: work-20260528-122941
origin_commit: 0915802
last_seen: 2026-06-16T08:57:05+09:00
closed: resolved
---

# (carried from PR #41) Script rename requires stale artifact cleanup

## Description

A proposed orphan-cleanup pass in `build.mjs` to remove old-named script artifacts after cross-skill reference renaming did not land; only `lookupVersion` and `PUBLIC_SUBSTITUTIONS` additions shipped.

## How to Fix

Defer orphan cleanup to a follow-up ticket after confirming the current rename strategy won't create orphaned copies in `dist/`. Low urgency.
