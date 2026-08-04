---
type: Feedback
title: Nothing here has been run against the live account
kind: concern
source: development
created_at: 2026-08-03T22:14:52+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: nothing-here-has-been-run-against
owner: 
mission: [make-scheduled-routines-a-configurable-inspectable-part-of-a-repository]
tickets: [20260801185501-decide-where-routine-config-lives.md, 20260801185502-list-a-repositorys-routines.md, 20260801185503-add-remove-and-refresh-a-routine.md]
origin_pr: 172
origin_pr_url: https://github.com/qmu/workaholic/pull/172
origin_branch: work-20260803-212331
origin_commit: 4387c655
last_seen: 2026-08-03T22:14:52+09:00
---

# Nothing here has been run against the live account

## Description

This run had no reachable routines API, so every path — listing, planning, authorizing — is verified only against fixtures built from the real routine shapes. Ticket 20260801185502's second verification method ("run it against this repository and read the output as if new to the project") was not performed, and the fixtures encode this author's belief about the response shape (`plugins/workaholic/skills/workaholify/scripts/lib/list_routines.py`).

## How to Fix

Run `/setup-routines` once interactively against the account and compare the real `RemoteTrigger list` response to the fixture. The shape assumption most worth checking is `data` as the item list, since an unexpected envelope now reports `unrecognised_live_shape` rather than lying — a safe failure, but a failure.
