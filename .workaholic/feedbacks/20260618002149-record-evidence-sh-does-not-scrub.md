---
type: Feedback
title: `record-evidence.sh` does not scrub secrets from captured evidence
kind: concern
source: development
created_at: 2026-06-18T00:21:49+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: record-evidence-sh-does-not-scrub
owner: 
mission: 
tickets: []
origin_pr: 48
origin_pr_url: https://github.com/qmu/workaholic/pull/48
origin_branch: work-20260617-231848
origin_commit: 63bbb9e
last_seen: 2026-06-18T00:21:49+09:00
closed: resolved
resolved_by_pr: 49
resolved_by_commit: 8b2b58f
---

# `record-evidence.sh` does not scrub secrets from captured evidence

## Description

`record-evidence.sh` appends the confirmation result/command to the story (which becomes the public PR body) with only an inline comment warning operators not to pass credentials — there is no automatic check (see [066714b](https://github.com/qmu/workaholic/commit/066714b) in `plugins/workaholic/skills/ship/scripts/record-evidence.sh`).

## How to Fix

Add a pre-append scan for common secret patterns (API keys, bearer/basic auth, tokens) that refuses or redacts before writing, so evidence cannot leak a secret into the PR/story.
