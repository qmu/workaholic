---
type: Feedback
title: The record's confirmation is not connected to the deployment contract's method list
kind: concern
source: development
created_at: 2026-08-03T22:24:59+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: the-record-s-confirmation-is-not
owner: a@qmu.jp
mission: [adopt-a-git-flow-branching-model-with-durable-ship-records]
tickets: [20260801184801-survey-ship-and-record-the-release-tier-decision.md, 20260801184802-cut-and-promote-a-release-branch.md, 20260801184803-record-what-a-release-branch-shipped.md]
origin_pr: 175
origin_pr_url: https://github.com/qmu/workaholic/pull/175
origin_branch: work-20260803-212310
origin_commit: d5207a8e
last_seen: 2026-08-03T22:24:59+09:00
---

# The record's confirmation is not connected to the deployment contract's method list

## Description

`confirm-release.sh` accepts any `<method>` string, while `.workaholic/deployments/*.md` declares a `confirmation_method` from a fixed enum. Nothing checks that a promotion's recorded method is one the target actually declares, so a typo records a confirmation that looks executed and names a method that does not exist (`plugins/workaholic/skills/ship/scripts/confirm-release.sh`).

## How to Fix

Validate `<method>` against `read-deployments.sh`'s reported methods, refusing an unknown one — cheap, and it turns a recorded string into a recorded fact. Left out here because the promotion's caller already reads the contract to *execute* the confirmation, so the value is a copy rather than a guess.
