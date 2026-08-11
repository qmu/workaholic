---
type: Mission
title: Give /propose and /ticket a diagnosis-first discovery pass
slug: give-propose-and-ticket-a-diagnosis-first-discovery-pass
status: active
merge_policy:
created_at: 2026-08-11T00:11:29+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [.workaholic/feedbacks/20260811001004-propose-lacks-ticket-s-epistemics-add-discovery-and-a-diagnosis-first-rule.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260811-001834
---

# Give /propose and /ticket a diagnosis-first discovery pass

## Goal

Issue qmu/workaholic#374 (feedback `20260811001004`) reports that `/propose` shipped a
ticket adopting the reporter's proposed mechanism, uninspected, and traces it to two
gaps: `/propose` has no discovery pass comparable to `/ticket`'s history/source/policy
research and §4b interrogation on unrecommendable forks, and neither command has a rule
sending a failure report at the failing mechanism before designing a fix. (That one
instance was independently hand-corrected on 2026-08-11, commits `52681f0`/`3172a65`;
this mission targets the general mechanism, not that ticket.)

## Experience

- `/propose` runs a discovery step (history at minimum) before scaffolding, and writes a
  genuinely unrecommendable fork as an explicit `open_decision` item instead of silently
  inheriting the reporter's framing.
- `/ticket` and `/propose` both apply a diagnosis-first rule: an ask reporting a failure
  of an existing mechanism yields a ticket whose step 1 is "reproduce and localize the
  failure", with the reporter's fix recorded as a hypothesis, never the design.

## Acceptance

- [x] `/propose`'s workflow runs a discovery pass before scaffolding and records
      genuinely unrecommendable forks as `open_decision` items. (#20260811001223-give-propose-a-discovery-pass-and-open-decision-items.md)
- [x] `/ticket` and `/propose` both apply a diagnosis-first rule for asks that report a
      failure of an existing mechanism. (#20260811001226-add-a-diagnosis-first-rule-to-ticket-and-propose.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-11 — ticket archived — 20260811001223-give-propose-a-discovery-pass-and-open-decision-items.md
- 2026-08-11 — ticket archived — 20260811001226-add-a-diagnosis-first-rule-to-ticket-and-propose.md
- 2026-08-11 — story published — work-20260811-001834
