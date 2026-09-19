---
type: Feedback
title: The moderation planner stops answering at the 35th step
kind: concern
source: development
subject: observer_ai:a@qmu.jp
created_at: 2026-09-19T14:59:24+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-moderation-planner-stops-answering-at
owner: 
mission: []
tickets: [20260919133719-pin-the-moderation-registry-by-name-not-by-count.md]
origin_pr: --base
origin_pr_url: main
origin_branch: work-20260919-135359
origin_commit: 0751b1b9a
last_seen: 2026-09-19T14:59:24+09:00
---

# The moderation planner stops answering at the 35th step

## Description

Under the add probe, `polling-cost.test.mjs`'s row still fails — not at the derived assertion, which passed with `35 === 35`, but at the pre-existing second-tick assertion (line 97). Measured directly: with a 35th step, `plan-steps.sh` emits empty stdout and `jq: error … Cannot index string with string "seconds"`, while the same sequence is green at the tree's real 34 steps. Both scripts involved (`runtime-plan.sh`, `plan-steps.sh`) are untouched by this branch (see [72683bce0](https://github.com/qmu/workaholic/commit/72683bce0)), so this is a latent property the next step addition will expose, not a regression here.

## How to Fix

Ticket `20260919141500` records the reproduction and both observed signals — a 1024-byte cut in one run and a shape error in another — without asserting a cause, and requires the repair's story to name which one it was.
