---
type: Feedback
title: The full unattended chain (claim → drive → auto-ship → teardown) has never run end to end
kind: concern
source: development
created_at: 2026-07-29T14:32:59+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-full-unattended-chain-claim-drive
owner: a@qmu.jp
mission: [loop-engineering-unified-drive]
tickets: [20260728221801-unify-mission-status-and-merge-policy.md, 20260728221802-add-claim-protocol-scripts.md, 20260728221803-unify-drive-executor.md, 20260728221804-retire-monitor-trip-carry.md]
origin_pr: 100
origin_pr_url: https://github.com/qmu/workaholic/pull/100
origin_branch: work-20260728-221717
origin_commit: 2aca03e3
last_seen: 2026-07-29T14:32:59+09:00
---

# The full unattended chain (claim → drive → auto-ship → teardown) has never run end to end

## Description

Every piece of the Unified Run is hermetically tested in isolation — claim/release multi-clone scenarios ([1079af03](https://github.com/qmu/workaholic/commit/1079af03)), `plan-units.sh`/`effective-policy.sh` and the truth-table rows ([e19f381d](https://github.com/qmu/workaholic/commit/e19f381d)) — but the composed loop (a real `merge_policy: auto` unit surviving claim → drive → the full evidence-gated `/ship` doctrine → worktree teardown, unattended, on the 5-minute cron) has not yet executed in production. The first live run is where interactions between these otherwise-isolated pieces (a claim going stale mid-ship, or a demote-on-size decision racing a merge) will actually surface.

## How to Fix

Before enabling the cron entry in `docs/drive-loop-runbook.md` broadly, run one supervised end-to-end cycle against a real `merge_policy: auto` unit and confirm the terminal token, PR, and teardown all land as designed; capture any surprise as a feedback record rather than assuming the hermetic coverage generalizes.
