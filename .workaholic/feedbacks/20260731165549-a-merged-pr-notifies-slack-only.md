---
type: Feedback
title: A merged PR notifies Slack only if something watches for the merge
kind: concern
source: development
created_at: 2026-07-31T16:55:49+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: a-merged-pr-notifies-slack-only
owner: 
mission: []
tickets: []
origin_pr: 119
origin_pr_url: https://github.com/qmu/workaholic/pull/119
origin_branch: work-20260731-163054
origin_commit: d8e713c1
last_seen: 2026-07-31T16:55:49+09:00
---

# A merged PR notifies Slack only if something watches for the merge

## Description

`notify-slack.sh` announces when it is called, and nothing calls it when a human merges in the GitHub UI. The standard's stated benefit — the merge event notifies Slack — has no implementation yet.

## How to Fix

Add a GitHub Action on `pull_request: closed` with `merged == true`, or route every merge through `/ship`, which can call the notifier itself.
