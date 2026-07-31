---
type: Feedback
title: The publish tree exists to protect a dirty checkout
kind: concern
source: development
created_at: 2026-07-31T16:55:49+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-publish-tree-exists-to-protect
owner: 
mission: []
tickets: []
origin_pr: 119
origin_pr_url: https://github.com/qmu/workaholic/pull/119
origin_branch: work-20260731-163054
origin_commit: d8e713c1
last_seen: 2026-07-31T16:55:49+09:00
---

# The publish tree exists to protect a dirty checkout

## Description

`create.sh` switches the current checkout's branch, which is what the publish tree was built to avoid for a developer running `/ticket` mid-work.

## How to Fix

The artifact writers need a worktree or a publish-tree-like staging area on the `work-*` path, not a bare `checkout -b` in the caller's tree.
