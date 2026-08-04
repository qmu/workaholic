---
type: Feedback
title: The hermetic suite is flaky in CI, and it failed a merge gate
kind: concern
source: development
created_at: 2026-08-04T12:46:15+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-hermetic-suite-is-flaky-in
owner: 
mission: []
tickets: [20260804023100-claim-survey-reads-wrong-coordinate.md]
origin_pr: 178
origin_pr_url: https://github.com/qmu/workaholic/pull/178
origin_branch: work-20260804-105730
origin_commit: 6264039f
last_seen: 2026-08-04T12:46:15+09:00
---

# The hermetic suite is flaky in CI, and it failed a merge gate

## Description

This branch's `validate` job failed on

## How to Fix

Make the harness's teardown tolerate a busy `.git/objects` — retry the
