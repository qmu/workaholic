---
type: Mission
title: Scope each user's routine to the FB issues assigned to them
slug: scope-each-user-s-routine-to-the-fb-issues-assigned-to-them
status: active
merge_policy:
created_at: 2026-08-05T13:11:15+00:00
author: a@qmu.jp
assignees: []
assignee:
predicted_hours:
actual_hours:
feedback: [20260805130926-scope-each-user-s-routine-to-the-fb-issues-assigned-to-that-user.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
---

# Scope each user's routine to the FB issues assigned to them

## Goal

`/workaholify` provisions a routine per developer, but nothing scopes which FB
issues wake whose routine. Matching a `[FB]` title would fire every user's
`[Propose]` routine on every FB issue in the repository — one report answered N
times over, each session writing its own record and opening its own proposal.
The ask is that a user's routine fire only on an FB issue assigned to them,
which makes the assignee a routing key and so demands it always be set.

## Experience

An FB issue opened in this repository wakes exactly one developer's `[Propose]`
routine — the assignee's — and no one else's. Every FB issue is opened carrying
an assignee, so the key the routing depends on is never absent.

## Acceptance

- [ ] The mechanism that scopes a routine to its assignee is decided and
      recorded, against what the routines API can actually express (#20260805131432-decide-how-a-routine-trigger-scopes-to-its-assignee.md)
- [ ] A routine created or refreshed by `/setup-routines` carries that scope,
      and drift on it is reported per field like any other (#20260805131433-carry-the-trigger-scope-through-the-routine-model.md)
- [ ] Every FB issue is opened with its assignee set (#20260805131434-open-every-fb-issue-with-its-assignee-set.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
