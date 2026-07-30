---
type: Feedback
title: The four tickets merged as one PR-unit, as an open stream concern predicted
kind: concern
source: development
created_at: 2026-07-30T18:57:14+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-four-tickets-merged-as-one
owner: 
mission: []
tickets: [20260729183606-publish-tree-primitive.md, 20260729183607-ticket-publishes-to-main.md, 20260729183608-mission-publishes-to-main.md, 20260729183609-drive-surveys-current-main.md]
origin_pr: 108
origin_pr_url: https://github.com/qmu/workaholic/pull/108
origin_branch: work-20260730-171125
origin_commit: 39b52709
last_seen: 2026-07-30T18:57:14+09:00
---

# The four tickets merged as one PR-unit, as an open stream concern predicted

## Description

The open concern `the-depends-on-chain-will-batch` predicted exactly this: the `depends_on` chain makes all four tickets one PR-unit, and `drive/SKILL.md` names `depends_on` as "the one signal strong enough to group on by itself". So this PR rewrites branching, `/ticket`, `/mission`, and `/drive` together — the shape that section warns a reviewer cannot review as one thing. Tickets 2–4 each carry a gate item reading "the dependency is merged first", which a single combined PR cannot literally satisfy (see [1179d916](https://github.com/qmu/workaholic/commit/1179d916) through [5a77dc50](https://github.com/qmu/workaholic/commit/5a77dc50)). The mitigation is ordering rather than partitioning: each commit is self-contained and the dependency precedes its callers at every commit, so the intent behind "merged first" — the primitive exists before anything uses it — holds commit-by-commit and can be reviewed that way.

## How to Fix

Review commit-by-commit rather than as one diff, and if the foundation should land separately, ask for a split: reverting to `1179d916` leaves a working repository with an unused primitive. Longer term, decide deliberately whether a `depends_on` chain longer than two should be capped at one unit — the grouping rule and the reviewable-PR rule genuinely conflict here, and one of them has to yield.
