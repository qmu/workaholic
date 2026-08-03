---
type: Feedback
title: 21 acceptance items across four other active missions are still unlinked
kind: concern
source: development
created_at: 2026-08-03T22:19:06+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: 21-acceptance-items-across-four-other
owner: 
mission: [make-acceptance-ticking-measure-satisfaction-not-marker-shape]
tickets: [20260801185301-decide-the-acceptance-to-artifact-link.md, 20260801185302-establish-the-link-when-tickets-are-emitted.md, 20260801185303-make-the-ticker-measure-satisfaction.md]
origin_pr: 173
origin_pr_url: https://github.com/qmu/workaholic/pull/173
origin_branch: work-20260803-212324
origin_commit: be2a3beb
last_seen: 2026-08-03T22:19:06+09:00
---

# 21 acceptance items across four other active missions are still unlinked

## Description

The repair path exists and was exercised on this mission's own board, but the other four active missions (`adopt-a-git-flow-branching-model-with-durable-ship-records` 8, `make-the-per-commit-changed-lines-ceiling-a-rule-that-holds` 7, `make-scheduled-routines-a-configurable-inspectable-part-of-a-repository` 3, `make-the-branch-story-concise-by-default` 3) were deliberately left unlinked. Linking them means deciding which ticket satisfies which criterion for plans this run never made — guessing at scale, which the contract forbids — and one of them is under an in-flight claim by a sibling unit right now, so editing its `mission.md` here would also conflict.

## How to Fix

Each is linked at its own replan or by the run that drives it, using `unlinked-acceptance.sh <slug>` to list the items and `link-acceptance.sh <slug> <index> <ticket>` per pair. Until then their boards are honestly reported as unlinked rather than silently stuck.
