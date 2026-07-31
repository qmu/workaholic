---
type: Mission
title: Give missions a ceiling so they stay closeable
slug: give-missions-a-ceiling-so-they-stay-closeable
status: draft
merge_policy:
created_at: 2026-07-31T17:03:42+00:00
author: noreply@anthropic.com
assignees: []
assignee:
predicted_hours:
actual_hours:
feedback: [20260731162946-missions-must-be-lightweight-enough-to-close.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
---

# Give missions a ceiling so they stay closeable

## Goal

Missions have a floor (an owner, a non-comment `## Experience`, one `## Acceptance` item) and no
ceiling, so the scaffold's empty sections get filled and the formality keeps missions open. The
four archived missions carried 3, 3, 4 and 9 acceptance items and all reached `N/N`; the five
active ones carry 7-9 and every one sits at `0/N`. Give the artifact a ceiling — in the scaffolds
that produce it, not in the gates that admit it.

## Experience

A mission written by `/mission` or by `/propose` arrives short enough to read in one screen and to
finish: no `## Scope` section offered at all, at most three acceptance criteria, and a whole
`mission.md` around 60 lines. The approved floor is unchanged — nothing that passes today starts
failing.

## Acceptance

<!-- PROPOSED criteria - a sketch for discussion, not a plan. -->

- [ ] `## Scope` is gone from both mission scaffolds (`mission/scripts/create.sh` and
      `propose/scripts/scaffold-draft.sh`), not merely marked optional
- [ ] Both scaffolds and the skills' authoring prose state the ceiling — at most 3 acceptance
      items, ~60 lines / 2KB for the whole `mission.md` — and `/propose` drafts are held to it
- [ ] A newly written mission and a newly proposed draft both come in under the ceiling, with the
      existing floor still enforced by `validate-mission.sh` and `approve.sh` unchanged

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->

- 2026-07-31: Proposed from `20260731162946-missions-must-be-lightweight-enough-to-close.md`
