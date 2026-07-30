---
type: Feedback
title: `queue-size.sh` walks both ticket areas per mission, per survey
kind: concern
source: development
created_at: 2026-07-30T19:47:51+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: queue-size-sh-walks-both-ticket
owner: 
mission: []
tickets: [20260730180248-claim-reader-loses-artifacts-on-archive.md, 20260730181500-plan-floor-counts-acceptance-not-queue.md]
origin_pr: 112
origin_pr_url: https://github.com/qmu/workaholic/pull/112
origin_branch: work-20260730-191139
origin_commit: dfaaf654
last_seen: 2026-07-30T19:47:51+09:00
---

# `queue-size.sh` walks both ticket areas per mission, per survey

## Description

The counter `find`s every `.md` under `tickets/todo/` and `tickets/archive/` and calls `read-relation.sh` once per file (see [ac4a87cc](https://github.com/qmu/workaholic/commit/ac4a87cc) in `plugins/workaholic/skills/mission/scripts/queue-size.sh`). The archive grows without bound, and the survey calls this once per approved mission — so the cost is `missions × archived tickets` on every tick, where only the `todo` half is needed for the survey's question.

## How to Fix

Let the survey ask for `todo` alone (a flag, or a second entry point) so it never walks the archive; `approve.sh` is the only caller that needs `total`, and it runs once per approval rather than every five minutes. Worth doing before the archive gets much larger.
