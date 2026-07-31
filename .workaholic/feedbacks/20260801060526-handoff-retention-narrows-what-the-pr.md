---
type: Feedback
title: Handoff retention narrows what the PR-body bounder can shed
kind: concern
source: development
created_at: 2026-08-01T06:05:26+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: handoff-retention-narrows-what-the-pr
owner: 
mission: 
tickets: [20260801031302-announce-a-claim-the-moment-it-is-pushed.md, 20260801031301-resume-a-claimed-but-unfinished-unit.md, 20260801031304-handoff-is-a-first-class-terminal-state.md]
origin_pr: 151
origin_pr_url: https://github.com/qmu/workaholic/pull/151
origin_branch: work-20260801-051742
origin_commit: 6c625c7b
last_seen: 2026-08-01T06:05:26+09:00
---

# Handoff retention narrows what the PR-body bounder can shed

## Description

With the Handoff block exempt from shedding, a body carrying both a very large concern corpus and a handoff falls back to plain truncation. That terminates and stays under the limit, but the shedding order is worth re-checking if a third protected section is ever added (`plugins/workaholic/skills/report/scripts/shrink-pr-body.sh`).

## How to Fix

If a third protected section appears, replace the lift-bound-restore with an explicit priority list rather than layering another special case.
