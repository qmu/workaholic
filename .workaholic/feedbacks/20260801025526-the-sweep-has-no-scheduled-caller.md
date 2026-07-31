---
type: Feedback
title: The sweep has no scheduled caller
kind: concern
source: development
created_at: 2026-08-01T02:55:26+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-sweep-has-no-scheduled-caller
owner: 
mission: []
tickets: [20260801003034-worktrees-are-never-reclaimed.md]
origin_pr: 132
origin_pr_url: https://github.com/qmu/workaholic/pull/132
origin_branch: work-20260801-023444
origin_commit: d29e07bf
last_seen: 2026-08-01T02:55:26+09:00
---

# The sweep has no scheduled caller

## Description

The ticket asked for teardown that "does not depend on one caller surviving", and the sweep delivers the mechanism — but nothing invokes it yet. A developer must run it by hand (`plugins/workaholic/skills/branching/scripts/reap-worktrees.sh`).

## How to Fix

Call the dry-run survey from `/drive`'s tick and report the reclaimable total, so growth is visible every run; the `--apply` decision stays a human one. The open mission *Make scheduled routines a configurable, inspectable part of a repository* is the natural home for wiring it to a schedule.
