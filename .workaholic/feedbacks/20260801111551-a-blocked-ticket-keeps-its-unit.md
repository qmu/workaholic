---
type: Feedback
title: A blocked ticket keeps its unit permanently resumable
kind: concern
source: development
created_at: 2026-08-01T11:15:51+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: a-blocked-ticket-keeps-its-unit
owner: 
mission: 
tickets: [20260801110246-a-reported-unit-is-resumed-forever.md]
origin_pr: 157
origin_pr_url: https://github.com/qmu/workaholic/pull/157
origin_branch: work-20260801-110823
origin_commit: 327a89e1
last_seen: 2026-08-01T11:15:51+09:00
---

# A blocked ticket keeps its unit permanently resumable

## Description

The new condition asks whether anything is left to drive, and a ticket that is *blocked* is still undriven — so a unit holding one never drains and stays resumable forever. That is correct as far as this rule goes, but it means a blocked ticket produces a loop that looks like the one just fixed while having a different cause (`plugins/workaholic/skills/drive/scripts/lib/claims.sh`).

## How to Fix

The answer to a blocked ticket is the icebox, which is a developer act by design. Keep the two causes distinguishable in the runbook so a cron log is not misread; if it recurs, consider whether a ticket whose last drive recorded `blocked` should be excluded from the drivable count.
