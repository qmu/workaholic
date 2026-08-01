---
type: Feedback
title: The legacy subject branch has no expiry
kind: concern
source: development
created_at: 2026-08-01T21:04:18+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: the-legacy-subject-branch-has-no
owner: 
mission: 
tickets: [20260801205101-a-long-mission-slug-cannot-be-claimed.md]
origin_pr: 166
origin_pr_url: https://github.com/qmu/workaholic/pull/166
origin_branch: work-20260801-205224
origin_commit: 22220a7b
last_seen: 2026-08-01T21:04:18+09:00
---

# The legacy subject branch has no expiry

## Description

`lib/claims.sh` reads both the `Unit:` trailer and the legacy `Claim <unit-id>` subject. The legacy branch is needed only while claims pushed before this change are still unmerged, but nothing records when that stops being true, so it will simply live forever (`plugins/workaholic/skills/drive/scripts/lib/claims.sh`).

## How to Fix

Drop the legacy branch once no unmerged remote branch carries a pre-change claim — checkable with one `git log --all --grep`. Cheap to keep, so this is housekeeping rather than debt.
