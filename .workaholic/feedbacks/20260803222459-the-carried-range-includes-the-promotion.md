---
type: Feedback
title: The carried range includes the promotion's own bookkeeping commits
kind: concern
source: development
created_at: 2026-08-03T22:24:59+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: the-carried-range-includes-the-promotion
owner: a@qmu.jp
mission: [adopt-a-git-flow-branching-model-with-durable-ship-records]
tickets: [20260801184801-survey-ship-and-record-the-release-tier-decision.md, 20260801184802-cut-and-promote-a-release-branch.md, 20260801184803-record-what-a-release-branch-shipped.md]
origin_pr: 175
origin_pr_url: https://github.com/qmu/workaholic/pull/175
origin_branch: work-20260803-212310
origin_commit: d5207a8e
last_seen: 2026-08-03T22:24:59+09:00
---

# The carried range includes the promotion's own bookkeeping commits

## Description

`carried_count` and the listed commits cover every base commit in `since_ref..cut_sha`, which includes the previous promotion's `Record release cut` and `Record release confirmation` commits. A reader scanning "what did this release carry" sees two rows of bookkeeping per prior release (`plugins/workaholic/skills/ship/scripts/record-release-cut.sh`).

## How to Fix

Leave it. The count is exactly what `git log` replays, and that verifiability is the record's only real property; a filter would have to recognise bookkeeping by commit subject and would silently mis-measure the first time it guessed wrong. If the noise ever matters, mark the commits with a trailer at write time and filter on that, never on the subject.
