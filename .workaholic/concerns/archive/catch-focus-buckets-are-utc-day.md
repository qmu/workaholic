---
origin_pr: 63
origin_pr_url: https://github.com/qmu/workaholic/pull/63
origin_branch: work-20260630-050446
origin_commit: 4ee61c5
created_at: 2026-07-01T01:12:10+09:00
last_seen: 2026-07-01T21:16:06+09:00
first_seen: 2026-07-01T01:12:10+09:00
concern_id: catch-focus-buckets-are-utc-day
severity: moderate
status: accepted
resolved_by_pr: 
resolved_by_commit: 
closed_reason: Filed already-accepted: the remedy asked for was documentation, and scan-window.sh:39-40 and :209 carry it. UTC-day bucketing is precise enough for a focus narrative and avoids non-POSIX date -d arithmetic.
closed_at: 2026-07-15T19:50:28+09:00
---

# `/catch` focus buckets are UTC-day based

## Description

Time-bucket boundaries use `epoch - epoch % 86400` to avoid non-POSIX `date -d` arithmetic (see [d9a695b](https://github.com/qmu/workaholic/commit/d9a695b) in `plugins/workaholic/skills/catch/scripts/scan-window.sh`); precise for a focus narrative but shifted by the local-UTC offset.

## How to Fix

The UTC-day assumption is documented in the script; if local-timezone bucketing is ever required, compute boundaries with explicit offset math.
