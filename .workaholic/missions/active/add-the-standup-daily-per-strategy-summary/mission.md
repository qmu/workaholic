---
type: Mission
title: Add the standup daily per-strategy summary
slug: add-the-standup-daily-per-strategy-summary
status: active
merge_policy:
created_at: 2026-08-17T11:52:01+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260817115147-add-a-standup-daily-per-strategy-status-summary-routine.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260817-124529
---

# Add the standup daily per-strategy summary

## Goal

Issue #473 asks for `/standup`: a daily 09:00 repository-scoped routine summarising recent
development activity **per strategy**, so stakeholders get a pulse without digging through
history. The strategy artifact exists and is bounded, owned and dated — but nothing links
work to it: the `strategy:` relation was deliberately not revived, so the attribution the
summary needs has to be settled before the summary can be written.

## Experience

Each morning the repository's channel carries one digest: per strategy, what moved
yesterday and what is waiting, in a few lines. A strategy with no activity says so. With no
strategies authored, the routine says nothing at all rather than posting an empty digest.

## Acceptance

<!-- PROPOSED — a sketch for discussion. Approval replans this to drive-ready. -->

- [x] Work is attributable to a strategy by a rule written down before any summary is
  computed. (#20260817115231-resolve-strategy-to-activity-attribution.md)
- [ ] `/standup` produces the per-strategy digest as a pure read, and is a clean no-op with
  zero strategies. (#20260817115232-add-the-standup-command-and-skill.md)
- [ ] The routine ships repository-scoped on an unambiguous daily schedule, posting only a
  shape its own prompt names. (#20260817115233-ship-the-standup-routine-template.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->

- 2026-08-17 — Proposed from issue #473.
- 2026-08-17 — ticket archived — 20260817115231-resolve-strategy-to-activity-attribution.md
