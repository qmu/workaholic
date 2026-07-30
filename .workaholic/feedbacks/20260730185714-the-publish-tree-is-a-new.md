---
type: Feedback
title: The publish tree is a new recoverable-state location nothing garbage-collects
kind: concern
source: development
created_at: 2026-07-30T18:57:14+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: the-publish-tree-is-a-new
owner: 
mission: []
tickets: [20260729183606-publish-tree-primitive.md, 20260729183607-ticket-publishes-to-main.md, 20260729183608-mission-publishes-to-main.md, 20260729183609-drive-surveys-current-main.md]
origin_pr: 108
origin_pr_url: https://github.com/qmu/workaholic/pull/108
origin_branch: work-20260730-171125
origin_commit: 39b52709
last_seen: 2026-07-30T18:57:14+09:00
---

# The publish tree is a new recoverable-state location nothing garbage-collects

## Description

A failed publish deliberately leaves the commit intact on `publish-main` inside `.publish/`, and both `open` and `close` refuse to destroy it (`dirty_publish_tree`, `unpublished_commits`) — see [1179d916](https://github.com/qmu/workaholic/commit/1179d916) in `plugins/workaholic/skills/branching/scripts/close-publish-tree.sh`. That is the right default, but it means a `diverged` publish leaves a tidy-looking directory holding the only copy of an artifact, and nothing surfaces it later: the claim reader reports claims, not publish trees, and `.publish/` is git-ignored so `git status` says nothing.

## How to Fix

Add a one-line publish-tree check to the same surfaces that already report in-flight claims — `/mission`'s bare view or `/drive`'s survey report — stating "a publish tree holds N unpublished commits" when `publish-main` is not an ancestor of the base. A refusal that nobody is told about is a refusal that ages into a lost artifact.
