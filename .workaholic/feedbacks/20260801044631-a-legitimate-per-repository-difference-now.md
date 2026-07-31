---
type: Feedback
title: A legitimate per-repository difference now reads as drift forever
kind: concern
source: development
created_at: 2026-08-01T04:46:31+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: a-legitimate-per-repository-difference-now
owner: 
mission: []
tickets: [20260801042354-merged-pr-routine-announces-every-recent-merge.md]
origin_pr: 143
origin_pr_url: https://github.com/qmu/workaholic/pull/143
origin_branch: work-20260801-042633
origin_commit: 42fafffd
last_seen: 2026-08-01T04:46:31+09:00
---

# A legitimate per-repository difference now reads as drift forever

## Description

`[FB] data-platform` carries `- Speak/Write Japanese`. It was deliberately **kept** — a project's output language is a property of that project, not a deviation — so `compare-routines.sh` will report that routine as drifted on every future survey (`plugins/workaholic/skills/workaholify/scripts/compare-routines.sh`).

## How to Fix

The comparison cannot decide this by itself; it reports, and a human says which differences are drift and which are configuration. If such cases multiply, the template format needs a way to declare a per-repository addendum — but one instance is not yet evidence for that.
