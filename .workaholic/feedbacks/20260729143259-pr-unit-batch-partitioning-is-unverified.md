---
type: Feedback
title: PR-unit batch partitioning is unverified model judgment
kind: concern
source: development
created_at: 2026-07-29T14:32:59+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: pr-unit-batch-partitioning-is-unverified
owner: a@qmu.jp
mission: [loop-engineering-unified-drive]
tickets: [20260728221801-unify-mission-status-and-merge-policy.md, 20260728221802-add-claim-protocol-scripts.md, 20260728221803-unify-drive-executor.md, 20260728221804-retire-monitor-trip-carry.md]
origin_pr: 100
origin_pr_url: https://github.com/qmu/workaholic/pull/100
origin_branch: work-20260728-221717
origin_commit: 2aca03e3
last_seen: 2026-07-29T14:32:59+09:00
---

# PR-unit batch partitioning is unverified model judgment

## Description

`plan-units.sh` (added in [e19f381d](https://github.com/qmu/workaholic/commit/e19f381d), `plugins/workaholic/skills/drive/scripts/plan-units.sh`) is deliberately only the deterministic half of partitioning — it emits the candidate missions and backlog tickets, but which backlog tickets group into one batch unit is left to the driving model's judgment, with no executable test. The ticket's own Considerations flag this as an accepted risk ("unrelated tickets in one PR is the failure mode reviewers pay for"), but there is currently no regression signal if a future model becomes less conservative about grouping.

## How to Fix

Add a fixture-based test that feeds `plan-units.sh`'s output through a scripted grouping heuristic (e.g. same `layer`/`depends_on` chain → one batch, otherwise one-per-unit) as a floor the model-driven grouping can be spot-checked against in CI, even though it cannot fully replace judgment.
