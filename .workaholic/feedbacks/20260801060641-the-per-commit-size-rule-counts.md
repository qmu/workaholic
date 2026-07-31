---
type: Feedback
title: The per-commit size rule counts a catch-up merge commit as authored work
kind: concern
source: development
created_at: 2026-08-01T06:06:41+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-per-commit-size-rule-counts
owner: 
mission: 
tickets: []
origin_pr: 152
origin_pr_url: https://github.com/qmu/workaholic/pull/152
origin_branch: work-20260801-051756
origin_commit: e8fedf7f
last_seen: 2026-08-01T06:06:41+09:00
---

# The per-commit size rule counts a catch-up merge commit as authored work

## Description

This branch changes ten lines of one ticket body, yet the branch-safety scan returns `block`. The finding is `too-large-commit` on `e129488f` — the *catch-up merge* that `/ship` itself performs to reconcile with `main`. A merge commit's changed lines against its first parent are the whole of what it merges, so any branch that catches up with a busy `main` inherits a size block for work it did not author, and the noisier `main` is the likelier it fires (`plugins/workaholic/skills/release-scan/scripts/scan-branch-safety.sh`).

## How to Fix

Exempt commits with more than one parent from the `too-large-commit` rule, the way the rule already exempts generated and lockfile rows. A merge commit authors nothing; its content is measured on the commits it brings in, where the ceiling already applies. The active mission *Make the per-commit changed-lines ceiling a rule that holds* is the right home for the change.
