---
type: Mission
title: Ask for the one act a declared handoff is waiting on
slug: ask-for-the-one-act-a-declared-handoff-is-waiting-on
status: active
merge_policy:
created_at: 2026-08-27T20:19:53+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260827201719-ask-for-the-one-act-a-declared-handoff-is-waiting-on.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260827-204109
---

# Ask for the one act a declared handoff is waiting on

## Goal

The handoff axis is complete on the routing side and empty on the asking side. A unit
declaring `verification_handoff:` is routed, its pull request left open and its claim
standing, and then nothing addresses anybody again: no `/moderate` step reads
`awaiting_verification`, and once the tip goes stale `stalled-units` asks the wrong
question about it.

## Experience

A unit the loop declared it cannot verify stops being invisible. The person holding the
account gets one Slack question, inside the hour's moderation root, naming the unit, its
open pull request, and the declared reason **in the words the ticket wrote** — not "a
claimed unit has not moved for a day or more". They are asked once, through the ledger
that already guarantees once, and no second, differently-worded question about the same
unit arrives from `stalled-units` beside it. The tick log counts standing handoffs
separately from stale claims. The loop still clears nothing itself: no claim touched, no
gate lifted, no handoff declared or withdrawn by any run.

## Acceptance

- [x] Every `awaiting_verification` claim reaches its holder as one question naming the
      declared reason and the pull request, asked exactly once (#20260827202118-add-the-moderate-step-handoff-units.md)
- [x] `stalled-units` asks nothing about a declared handoff, counting it as a finding (#20260827202118-stop-stalled-units-asking-about-a-declared-handoff.md)
- [x] The consumer is pinned report-and-ask only, drilled offline, and documented (#20260827202119-pin-the-new-consumer-as-report-and-ask-only.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-27 — ticket archived — 20260827202118-read-a-claim-s-declared-handoff-and-its-pull-request.md
- 2026-08-27 — ticket archived — 20260827202118-add-the-moderate-step-handoff-units.md
- 2026-08-27 — ticket archived — 20260827202118-render-the-standing-handoff-as-a-moderation-event.md
- 2026-08-27 — ticket archived — 20260827202118-stop-stalled-units-asking-about-a-declared-handoff.md
- 2026-08-27 — ticket archived — 20260827202119-name-claimed-awaiting-verification-in-the-run-report.md
- 2026-08-27 — ticket archived — 20260827202119-pin-the-new-consumer-as-report-and-ask-only.md
