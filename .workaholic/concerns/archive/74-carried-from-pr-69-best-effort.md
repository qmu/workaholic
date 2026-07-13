---
type: Concern
origin_pr: 74
origin_pr_url: https://github.com/qmu/workaholic/pull/74
origin_branch: work-20260701-221800
origin_commit: f25dffa
created_at: 2026-07-06T11:31:52+09:00
superseded_by: best-effort-fetch-adds-a-per
last_seen: 2026-07-06T11:31:52+09:00
first_seen: 2026-07-06T11:31:52+09:00
concern_id: best-effort-fetch-adds-a-per
severity: low
status: superseded
resolved_by_pr: 
resolved_by_commit: 
---

# (carried from PR #69) Best-effort fetch adds a per-run latency and failure mode

## Description

The `scan-window.sh` script fetches the remote before querying commits, to ensure it sees recent merges; if the network is unreachable or slow, the fetch adds per-run latency and can fail the entire catch/report flow (see `plugins/workaholic/skills/catch/scripts/scan-window.sh`).

## How to Fix

Add a `--skip-fetch` or `--no-network` flag and document that it trades freshness for speed (safe for same-day reruns), or make fetch failures non-fatal (fetch-or-die is too strict; log and proceed).
