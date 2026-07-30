---
type: Feedback
title: Re-entry through an env-var guard is invisible in a stack trace
kind: concern
source: development
created_at: 2026-07-30T19:54:39+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: re-entry-through-an-env-var
owner: 
mission: []
tickets: [20260730190856-merge-pr-breaks-in-a-claim-worktree.md]
origin_pr: 113
origin_pr_url: https://github.com/qmu/workaholic/pull/113
origin_branch: work-20260730-193046
origin_commit: 921d0cbc
last_seen: 2026-07-30T19:54:39+09:00
---

# Re-entry through an env-var guard is invisible in a stack trace

## Description

The off-base path re-runs the same script inside the publish tree, guarded by `WH_EDC_IN_PUBLISH_TREE` so it cannot recurse (see [7642ebaa](https://github.com/qmu/workaholic/commit/7642ebaa)). It kept the change small — the Python half is cwd-relative, so running it *in* the publish tree redirects both its dedup scan and its writes for free — but a reader debugging a failure sees one script name and two very different executions, and the inner run's JSON is rewritten by `sed` on the way out.

## How to Fix

If this needs touching again, split the extractor into "write the records into `<root>`" and "publish `<root>`", so the two executions become two named functions instead of one script twice. Not worth doing pre-emptively; worth doing the moment a third caller appears.
