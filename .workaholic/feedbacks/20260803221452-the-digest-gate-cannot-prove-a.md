---
type: Feedback
title: The digest gate cannot prove a human was present
kind: concern
source: development
created_at: 2026-08-03T22:14:52+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-digest-gate-cannot-prove-a
owner: 
mission: [make-scheduled-routines-a-configurable-inspectable-part-of-a-repository]
tickets: [20260801185501-decide-where-routine-config-lives.md, 20260801185502-list-a-repositorys-routines.md, 20260801185503-add-remove-and-refresh-a-routine.md]
origin_pr: 172
origin_pr_url: https://github.com/qmu/workaholic/pull/172
origin_branch: work-20260803-212331
origin_commit: 4387c655
last_seen: 2026-08-03T22:14:52+09:00
---

# The digest gate cannot prove a human was present

## Description

`authorize-routine-change.sh` closes substitution (confirm one body, send another) and batching (one yes, many routines), but an agent that renders a plan and computes its digest without ever showing anyone passes the gate. No script the agent itself runs can prevent that, and the headers say so rather than overselling it (`plugins/workaholic/skills/workaholify/scripts/authorize-routine-change.sh`).

## How to Fix

The missing layer is a blocking `PreToolUse` hook on the `RemoteTrigger` tool that refuses a `create`/`update` whose body has no matching authorization in the session — the same shape as `guard-git-commit.sh` for commits. That is a hook, not a script, and it belongs in its own change.
