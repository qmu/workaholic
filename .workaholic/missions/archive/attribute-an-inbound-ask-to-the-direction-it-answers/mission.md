---
type: Mission
title: Attribute an inbound ask to the direction it answers
slug: attribute-an-inbound-ask-to-the-direction-it-answers
status: achieved
merge_policy:
created_at: 2026-08-26T04:18:55+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours: 0.68
feedback: [20260826041650-attribute-an-inbound-ask-to-the-direction-it-answers.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260826-043020
---

# Attribute an inbound ask to the direction it answers

## Goal

The loop has two inbound mouths and only one is attributable. `/propose` writes a
`feedback:` header line naming the strategy's refs; the **Slack sweep** and `/fb`'s
in-repo path write none, so a person's ask about a live direction produces work citing it
at nothing. Measured 2026-08-26: issue #604 became a five-ticket mission and
`attributed-work.sh` still reports `waiting_count: 0`, so `work_waiting` stood open.

## Experience

An ask filed by the sweep or by `/fb` carries the direction it answers on the same visible
`feedback:` line `/propose` writes, from one writer. `/specificate` decides the direction
for an ask naming none — explicit slug, else judged against the `active` strategies it
already reads — and reports it, `unattributed` included.

## Acceptance

<!-- PROPOSED criteria, THREE ITEMS OR FEWER - a sketch for discussion, not a
     plan. Approval replans this mission to drive-ready; only then may it be
     authorized. -->

- [x] An ask filed by the sweep or by `/fb` carries the direction it answers on the
      `feedback:` line, written in one place (#20260826042021-carry-the-direction-onto-a-swept-ask.md)
- [x] `/specificate` decides the direction for an ask that names none, and reports the
      decision — the slug or `unattributed` — on both its surfaces (#20260826042021-decide-and-report-the-direction-for-an-ask-that-names-none.md)
- [x] The chain test walks the sweep's ask, and every document the change moves states
      the extended bound and its limits (#20260826042021-walk-the-sweep-s-ask-in-the-chain-test.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-26 — ticket archived — 20260826042021-write-the-ask-s-feedback-line-in-one-place.md
- 2026-08-26 — ticket archived — 20260826042021-carry-the-direction-onto-a-swept-ask.md
- 2026-08-26 — ticket archived — 20260826042021-carry-the-direction-onto-an-fb-ask.md
- 2026-08-26 — ticket archived — 20260826042021-decide-and-report-the-direction-for-an-ask-that-names-none.md
- 2026-08-26 — ticket archived — 20260826042021-walk-the-sweep-s-ask-in-the-chain-test.md
- 2026-08-26 — mission achieved — mission.md
- 2026-08-26 — story reported — work-20260826-043020.md
- 2026-08-26 — run recorded (+0.68h) — cse_01CXYzWiNLZMLNGoaN1K9vAG
