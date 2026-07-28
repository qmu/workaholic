---
type: Feedback
title: Triage threshold and compound detection are prose-driven, not enforced
kind: concern
source: development
created_at: 2026-07-13T23:39:50+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: triage-threshold-and-compound-detection-are
owner: 
mission: 
tickets: [20260713144839-worktree-copies-root-env.md, 20260713203444-concern-identity-update-in-place.md, 20260713203445-report-concern-triage-and-compound-merge.md]
origin_pr: 83
origin_pr_url: https://github.com/qmu/workaholic/pull/83
origin_branch: work-20260713-144839
origin_commit: fbceaaa
last_seen: 2026-07-16T12:06:03+09:00
closed: accepted
---

# Triage threshold and compound detection are prose-driven, not enforced

## Description

The count threshold (20) and the compound trigger live in `report/SKILL.md` prose; `list-active-deferred-concerns.sh` emits neither an active count nor a `should_triage` flag, so the gate is skippable. It fired on PR #83's branch only because a human ran the triage — and it fired again on this branch the same way, with 29 active concerns well past the threshold.

## How to Fix

Emit an envelope with `active_count` and `should_triage` so `/report` branches mechanically.
