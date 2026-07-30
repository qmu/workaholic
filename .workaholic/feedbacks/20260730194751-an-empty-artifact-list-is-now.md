---
type: Feedback
title: An empty artifact list is now anomalous and still renders as `[]`
kind: concern
source: development
created_at: 2026-07-30T19:47:51+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: an-empty-artifact-list-is-now
owner: 
mission: []
tickets: [20260730180248-claim-reader-loses-artifacts-on-archive.md, 20260730181500-plan-floor-counts-acceptance-not-queue.md]
origin_pr: 112
origin_pr_url: https://github.com/qmu/workaholic/pull/112
origin_branch: work-20260730-191139
origin_commit: dfaaf654
last_seen: 2026-07-30T19:47:51+09:00
---

# An empty artifact list is now anomalous and still renders as `[]`

## Description

Before this change an empty `artifacts` array was the *normal* mid-drive state, so `list-claims.sh` rendering `[]` said nothing. After it, a claim with no artifacts means something genuinely odd — a `Claim` commit that stamped nothing, or every artifact unstamped or deleted — but the output is unchanged, so the reader cannot tell "nothing to protect" from "protecting nothing" (see [bba6f0dc](https://github.com/qmu/workaholic/commit/bba6f0dc) in `plugins/workaholic/skills/drive/scripts/lib/claims.sh`).

## How to Fix

Surface it where claims are already reported — `/drive`'s survey report and `list-claims.sh` — as a note rather than an error, since `claims.sh` deliberately tolerates a stamp-less claim commit. One line naming the unit is enough for a human to look.
