---
type: Feedback
title: The promotion has no entry point of its own
kind: concern
source: development
created_at: 2026-08-03T22:24:59+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-promotion-has-no-entry-point
owner: a@qmu.jp
mission: [adopt-a-git-flow-branching-model-with-durable-ship-records]
tickets: [20260801184801-survey-ship-and-record-the-release-tier-decision.md, 20260801184802-cut-and-promote-a-release-branch.md, 20260801184803-record-what-a-release-branch-shipped.md]
origin_pr: 175
origin_pr_url: https://github.com/qmu/workaholic/pull/175
origin_branch: work-20260803-212310
origin_commit: d5207a8e
last_seen: 2026-08-03T22:24:59+09:00
---

# The promotion has no entry point of its own

## Description

The flow is documented in `ship/SKILL.md` §6 and implemented in three scripts, but nothing invokes it: `/ship` runs §5 for one unit, `/drive` deliberately does not promote, and there is no `/promote` command or routine. So the tier is reachable only by an agent reading §6 and running the scripts in order. That is a correct starting point — an automatic promotion would have been the per-unit behaviour change this mission ruled out — but a capability nobody can trigger by name tends to go unused.

## How to Fix

Decide the trigger deliberately once there is operational experience: most likely a scheduled promotion routine (the `workaholify` routine templates are the natural home) or an explicit subcommand. Do not fold it into `/drive`.
