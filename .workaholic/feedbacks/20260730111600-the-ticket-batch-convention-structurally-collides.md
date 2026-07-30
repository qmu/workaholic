---
type: Feedback
title: The ticket-batch convention structurally collides with the per-commit size ceiling
kind: concern
source: development
created_at: 2026-07-30T11:16:00+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: the-ticket-batch-convention-structurally-collides
owner: 
mission: []
tickets: []
origin_pr: 103
origin_pr_url: https://github.com/qmu/workaholic/pull/103
origin_branch: work-20260729-193859
origin_commit: 2e7f1b00
last_seen: 2026-07-30T11:16:00+09:00
---

# The ticket-batch convention structurally collides with the per-commit size ceiling

## Description

The release scan flagged [fa8033d3](https://github.com/qmu/workaholic/commit/fa8033d3) as `too-large-commit` at 502 non-generated changed lines against a 500 ceiling (`override` tier). The entire 502 is four ticket markdown files, with no executable line among them. This is not a one-off: `create-ticket` caps a split at 2–4 tickets and a ticket written to this repository's density runs 110–140 lines, so any full batch reliably breaches the ceiling. `MAX_COMMIT_CHANGED_LINES` exists to make commit count a comparable throughput unit, which is a claim about implementation commits, not specification ones.

## How to Fix

Decide the rule deliberately rather than overriding it each time: either commit a ticket batch one file per commit, or add an explicit spec-commit exemption in `release-scan/scripts/lib/` with the reason recorded. A rule that is always overridden stops measuring anything.
