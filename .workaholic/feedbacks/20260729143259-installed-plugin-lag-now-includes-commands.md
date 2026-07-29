---
type: Feedback
title: Installed-plugin lag now includes commands that no longer exist, not just schema drift
kind: concern
source: development
created_at: 2026-07-29T14:32:59+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: installed-plugin-lag-now-includes-commands
owner: a@qmu.jp
mission: [loop-engineering-unified-drive]
tickets: [20260728221801-unify-mission-status-and-merge-policy.md, 20260728221802-add-claim-protocol-scripts.md, 20260728221803-unify-drive-executor.md, 20260728221804-retire-monitor-trip-carry.md]
origin_pr: 100
origin_pr_url: https://github.com/qmu/workaholic/pull/100
origin_branch: work-20260728-221717
origin_commit: 2aca03e3
last_seen: 2026-07-29T14:32:59+09:00
---

# Installed-plugin lag now includes commands that no longer exist, not just schema drift

## Description

The feedback stream already tracks installed-plugin lag as a still-active, schema-focused concern (validators misjudging the new `status`/`merge_policy` fields on stale installs). This branch changes the shape of that risk: [8ad25005](https://github.com/qmu/workaholic/commit/8ad25005) deletes `commands/{monitor,trip,carry}.md` and the entire `agents/` directory outright, so a session running a pre-refresh installed plugin is not just misvalidating new schema — it can still offer or invoke `/monitor`, `/trip`, or `/carry`, which now point at nothing in the current source. The drive SKILL's Considerations note this is deferred to "the ship story's post-release instructions" rather than code.

## How to Fix

Add an explicit post-release note (or a lightweight version-mismatch check surfaced by the mission/policy lens) telling a developer whose session still lists the retired commands to refresh the plugin before relying on them, rather than leaving the gap purely documentary.
