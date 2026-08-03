---
type: Mission
title: Make scheduled routines a configurable, inspectable part of a repository
slug: make-scheduled-routines-a-configurable-inspectable-part-of-a-repository
status: active
merge_policy:
created_at: 2026-07-31T16:05:30+00:00
author: noreply@anthropic.com
assignees: []
assignee:
predicted_hours:
actual_hours: 0.56
feedback: [20260731160449-support-a-setup-routines-skill-that-manages-a-repository-s-scheduled-routines.md, 20260731160517-routine-configuration-has-no-source-of-truth-in-the-repository.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260803-212331
---

# Make scheduled routines a configurable, inspectable part of a repository

## Goal

Routines are how this project runs — filing feedback issues, announcing merges, driving the queue
— yet nothing in the repository records a routine's schedule, prompt, target repository, or
channel. The configuration lives in one person's Claude Code Web account, so "what runs against
this repo" can only be answered by asking them.

Issue #120 asks for `/setup-routines [repository name]`: list what is configured, pull the latest
template, add/remove/refresh a routine — shaped so each developer can later configure their own.

Two decisions come first and are this mission's substance: **where routine configuration lives**
(`.workaholic/` is a closed layout, so a new area is a registered amendment, not a mkdir) and
**what an agent may apply unattended** (both loop runbooks say "do not install the crontab from an
agent session" — the very capability the issue asks for).

## Experience

A developer who just joined runs `/setup-routines workaholic` and sees what runs against that
repository, on what schedule, and from which template version — without asking the person who set
it up.

## Acceptance

PROPOSED sketch, not a plan. `/mission approve` replans this to drive-ready.

- [ ] Where routine configuration lives, and what an agent may apply unattended, are decided and
      written down with the rejected alternatives named
- [ ] `/setup-routines [repository name]` lists the routines configured for that repository
- [ ] A routine can be added, removed, or refreshed from its template within the decided boundary

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-03 — ticket archived — 20260801185501-decide-where-routine-config-lives.md
- 2026-08-03 — ticket archived — 20260801185502-list-a-repositorys-routines.md
- 2026-08-03 — ticket archived — 20260801185503-add-remove-and-refresh-a-routine.md
- 2026-08-03 — story reported — work-20260803-212331.md
- 2026-08-03 — run recorded (+0.56h) — work-20260803-212331
