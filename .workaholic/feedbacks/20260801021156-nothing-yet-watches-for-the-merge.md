---
type: Feedback
title: Nothing yet watches for the merge event the standard depends on
kind: concern
source: development
created_at: 2026-08-01T02:11:56+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: nothing-yet-watches-for-the-merge
owner: 
mission: []
tickets: [20260731163049-propose-surveys-repo-state-and-lands-on-a-branch.md]
origin_pr: 124
origin_pr_url: https://github.com/qmu/workaholic/pull/124
origin_branch: work-20260801-012313
origin_commit: ea3765b8
last_seen: 2026-08-01T02:11:56+09:00
---

# Nothing yet watches for the merge event the standard depends on

## Description

The whole reason for moving artifacts onto pull requests is that the merge can be announced, but `notify-slack.sh` announces only when called, and a human merging in the GitHub UI calls nothing (`plugins/workaholic/skills/propose/scripts/notify-slack.sh`). The standard's stated benefit is currently unimplemented.

## How to Fix

A GitHub Action on `pull_request: closed` with `merged == true`, or routing every merge through `/ship` so the notifier fires from a path the project controls.
