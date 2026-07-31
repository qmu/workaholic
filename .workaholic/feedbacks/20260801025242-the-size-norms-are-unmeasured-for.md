---
type: Feedback
title: The size norms are unmeasured for human-authored missions until something calls size.sh
kind: concern
source: development
created_at: 2026-08-01T02:52:42+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-size-norms-are-unmeasured-for
owner: 
mission: []
tickets: [20260801012129-cap-mission-size-and-drop-the-scope-section.md]
origin_pr: 131
origin_pr_url: https://github.com/qmu/workaholic/pull/131
origin_branch: work-20260801-022239
origin_commit: fe0c5bcb
last_seen: 2026-08-01T02:52:42+09:00
---

# The size norms are unmeasured for human-authored missions until something calls size.sh

## Description

`size.sh` reports rather than blocks for a human author, by design — but nothing yet calls it during the `/mission` interrogation, so the norm currently relies on the author reading `mission/SKILL.md` (`plugins/workaholic/skills/mission/scripts/size.sh`).

## How to Fix

Have the Creation Interrogation and the Replan flow run `size.sh` before publishing and show the measurement. That is a `/mission` command change, deliberately not bundled here.
