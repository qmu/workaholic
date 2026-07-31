---
type: Feedback
title: Sibling sessions still cannot see each other
kind: concern
source: development
created_at: 2026-08-01T04:46:31+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: sibling-sessions-still-cannot-see-each
owner: 
mission: []
tickets: [20260801042354-merged-pr-routine-announces-every-recent-merge.md]
origin_pr: 143
origin_pr_url: https://github.com/qmu/workaholic/pull/143
origin_branch: work-20260801-042633
origin_commit: 42fafffd
last_seen: 2026-08-01T04:46:31+09:00
---

# Sibling sessions still cannot see each other

## Description

Rule 3 asks the session to check recent channel history before posting, which is a mitigation rather than a guarantee: two sessions running concurrently can both check, both see nothing, and both post.

## How to Fix

Only the platform can serialise this. The primary defence is rule 1 (one message, one PR, identified by trigger), which makes the duplicate impossible without needing coordination; rule 3 is the backstop.
