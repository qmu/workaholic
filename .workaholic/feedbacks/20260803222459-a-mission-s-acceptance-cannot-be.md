---
type: Feedback
title: A mission's acceptance cannot be ticked when its items carry no artifact marker
kind: concern
source: development
created_at: 2026-08-03T22:24:59+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: a-mission-s-acceptance-cannot-be
owner: a@qmu.jp
mission: [adopt-a-git-flow-branching-model-with-durable-ship-records]
tickets: [20260801184801-survey-ship-and-record-the-release-tier-decision.md, 20260801184802-cut-and-promote-a-release-branch.md, 20260801184803-record-what-a-release-branch-shipped.md]
origin_pr: 175
origin_pr_url: https://github.com/qmu/workaholic/pull/175
origin_branch: work-20260803-212310
origin_commit: d5207a8e
last_seen: 2026-08-03T22:24:59+09:00
---

# A mission's acceptance cannot be ticked when its items carry no artifact marker

## Description

`tick-acceptance.sh` flips an item only when it carries a trailing `(#<artifact-filename>)` marker. This mission's acceptance items are prose criteria written at proposal time and carry none, so every archive seam reported `no_unchecked_match` and the mission reads `0/8` although all eight criteria are satisfied by this branch. The derived progress therefore understates completed work, and the mission lens will keep surfacing it (`plugins/workaholic/skills/mission/scripts/tick-acceptance.sh`).

## How to Fix

This is precisely the subject of the active mission `make-acceptance-ticking-measure-satisfaction-not-marker-shape`; no separate fix belongs here. Until it lands, a mission whose criteria are prose has to be closed on judgment rather than on a computed count.
