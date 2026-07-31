---
type: Feedback
title: The Drive template is still a pilot
kind: concern
source: development
created_at: 2026-08-01T04:20:02+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: the-drive-template-is-still-a
owner: 
mission: []
tickets: [20260801030421-workaholify-provisions-the-loop-engineering-environment.md]
origin_pr: 138
origin_pr_url: https://github.com/qmu/workaholic/pull/138
origin_branch: work-20260801-033154
origin_commit: 2c2db915
last_seen: 2026-08-01T04:20:02+09:00
---

# The Drive template is still a pilot

## Description

Its name carries `(pilot)` and its prompt bounds a tick to two units. It exists for exactly one repository today.

## How to Fix

Applying it to a second repository should be a deliberate decision, not a default of "provision everything". The command offers each routine separately for this reason.
