---
type: Mission
title: Name the steps a tick could not read
slug: name-the-steps-a-tick-could-not-read
status: achieved
merge_policy:
created_at: 2026-08-31T10:23:49+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260831101847-a-tick-that-cannot-read-its-inputs-reports-the-same-shape-as-a-healthy-one.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260831-104307
---

# Name the steps a tick could not read

## Goal

`run.sh` classifies every step `ok|filed|skipped|degraded|blocked` with a reason, and
`render-tick-post.sh` reads a row's `summary` and `event` and never its `status`. So a
tick where six steps saw nothing renders exactly like a tick where everything was read
— and with no question it posts nothing at all. Measured: 24 of 25 ticks in that state,
found four days later by asking.

## Scope

`render-tick-post.sh`, the root gate, the skill and reference wording, one drill. Not
the step statuses, the diff rule, the question ledger or any step's own reading.

## Experience

Every root the tick posts says which steps could not read and why, so an impaired tick
never reads as a quiet one; an impairment that appears or clears breaks silence on its
own. A tick whose steps all read cleanly posts exactly what it posts today.

## Acceptance

- [x] Every root names the steps that could not read, with their reasons, outside the
      diff — so a standing impairment is stated on every tick that speaks. (#20260831102424-name-the-impaired-steps-on-every-root.md)
- [x] An impairment that appeared or cleared earns a root with no question, and an
      unchanged one never restates hourly. (#20260831102424-let-a-changed-impairment-earn-a-root.md)
- [x] The rule is stated where the tick's voice is defined, and proved offline by a
      drill with a breaker row in the drill register. (#20260831102424-drill-the-impairment-reading-offline.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-31 — ticket archived — 20260831102424-read-the-impairment-off-the-tick-s-own-rows.md
- 2026-08-31 — ticket archived — 20260831102424-name-the-impaired-steps-on-every-root.md
- 2026-08-31 — ticket archived — 20260831102424-let-a-changed-impairment-earn-a-root.md
- 2026-08-31 — ticket archived — 20260831102424-state-the-impairment-rule-where-the-voice-is-defined.md
- 2026-08-31 — ticket archived — 20260831102424-drill-the-impairment-reading-offline.md
- 2026-08-31 — mission achieved — mission.md
- 2026-08-31 — story reported — work-20260831-104307.md
