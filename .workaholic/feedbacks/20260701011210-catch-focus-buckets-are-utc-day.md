---
type: Feedback
title: `/catch` focus buckets are UTC-day based
kind: concern
source: development
created_at: 2026-07-01T01:12:10+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: catch-focus-buckets-are-utc-day
owner: 
mission: 
tickets: []
origin_pr: 63
origin_pr_url: https://github.com/qmu/workaholic/pull/63
origin_branch: work-20260630-050446
origin_commit: 4ee61c5
last_seen: 2026-07-01T21:16:06+09:00
closed: accepted
---

# `/catch` focus buckets are UTC-day based

## Description

Time-bucket boundaries use `epoch - epoch % 86400` to avoid non-POSIX `date -d` arithmetic (see [d9a695b](https://github.com/qmu/workaholic/commit/d9a695b) in `plugins/workaholic/skills/catch/scripts/scan-window.sh`); precise for a focus narrative but shifted by the local-UTC offset.

## How to Fix

The UTC-day assumption is documented in the script; if local-timezone bucketing is ever required, compute boundaries with explicit offset math.
