---
type: Feedback
title: `checked_out: false` is now normal and nothing reads it yet
kind: concern
source: development
created_at: 2026-07-30T19:54:39+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: checked-out-false-is-now-normal
owner: 
mission: []
tickets: [20260730190856-merge-pr-breaks-in-a-claim-worktree.md]
origin_pr: 113
origin_pr_url: https://github.com/qmu/workaholic/pull/113
origin_branch: work-20260730-193046
origin_commit: 921d0cbc
last_seen: 2026-07-30T19:54:39+09:00
---

# `checked_out: false` is now normal and nothing reads it yet

## Description

`merge-pr.sh` reports the field, and `ship/SKILL.md` step 9 says to surface it — but that is prose, and the `/drive` route that ships `auto` units does not yet act on it (see [7642ebaa](https://github.com/qmu/workaholic/commit/7642ebaa) in `plugins/workaholic/skills/ship/SKILL.md`). The concrete consequence: after an `auto` merge from a claim worktree, the run is still on the claim branch, and `/drive` §6's teardown must run from the primary tree because git cannot remove the worktree it is standing in. That works today because the teardown is a separate step with its own cwd, but nothing checks it.

## How to Fix

Have `/drive` §6 read `checked_out` and state the cwd it runs the teardown from, so the ordering is explicit rather than incidental. A test that ships an `auto` unit end to end would catch it, which is the composed-loop coverage the stream already tracks as an open concern.
