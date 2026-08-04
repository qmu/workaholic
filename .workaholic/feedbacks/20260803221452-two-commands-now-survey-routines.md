---
type: Feedback
title: Two commands now survey routines
kind: concern
source: development
created_at: 2026-08-03T22:14:52+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: two-commands-now-survey-routines
owner: 
mission: [make-scheduled-routines-a-configurable-inspectable-part-of-a-repository]
tickets: [20260801185501-decide-where-routine-config-lives.md, 20260801185502-list-a-repositorys-routines.md, 20260801185503-add-remove-and-refresh-a-routine.md]
origin_pr: 172
origin_pr_url: https://github.com/qmu/workaholic/pull/172
origin_branch: work-20260803-212331
origin_commit: 4387c655
last_seen: 2026-08-03T22:14:52+09:00
---

# Two commands now survey routines

## Description

`/workaholify` step 4 and `/setup-routines` steps 1-5 both fetch the live list and report it. They share every script, so the logic cannot drift, but the *prose* describing the flow exists twice and can (`plugins/workaholic/commands/workaholify.md`, `plugins/workaholic/commands/setup-routines.md`).

## How to Fix

If it drifts once, cut `/workaholify`'s routine step down to a pointer at `/setup-routines`. It is left duplicated for now because `/workaholify` is a setup sweep that should not require a second command to complete.
