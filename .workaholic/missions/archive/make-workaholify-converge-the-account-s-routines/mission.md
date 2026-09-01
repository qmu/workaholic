---
type: Mission
title: Make /workaholify converge the account's routines
slug: make-workaholify-converge-the-account-s-routines
status: achieved
merge_policy:
created_at: 2026-08-19T10:38:22+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours: 1.2
feedback: [20260819103531-workaholify-should-converge-the-account-s-routines-not-just-render-setup-sheets.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260827-003544
---

# Make /workaholify converge the account's routines

## Goal

The 2026-08-14 ruling (issue #445) made `/workaholify` the preparation command,
not an audit. Three of its four subjects converge — §3, §3a, §4. §5 alone still
only renders sheets, so a run reported this repository prepared while 4 of 6
routines did not exist and the other 2 had been disabled for a week with stale
prompts — with a `RemoteTrigger`-family tool exposed the whole time.

## Experience

`/workaholify` §5 attempts the same list/diff/apply convergence the three setup
commands run, over **every** scope, and reports what it converged by name.
`no_transport: RemoteTrigger-family tool` is its one named refusal, with the
sheets as that refusal's recovery path — exactly the shape §3, §3a and §4 have.
Each routine's enabled state is stated, so a silently-off routine is legible.

## Acceptance

- [x] `/workaholify` §5 converges the account's routines over every scope, and
      report-only happens solely under a named `no_transport` refusal. (#20260819103847-make-workaholify-converge-the-routines-over-every-scope.md)
- [x] Every routine the run touches or skips is reported with its enabled state. (#20260819103851-report-each-routine-s-enabled-state-at-every-convergence-seam.md)
- [x] Whether convergence renames a routine in place is ruled on, and
      `renamed_from:`'s standing states the answer. (#20260819103855-rule-on-renaming-a-live-routine-in-place.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-19 — ticket archived — 20260819103847-make-workaholify-converge-the-routines-over-every-scope.md
- 2026-08-19 — ticket archived — 20260819103851-report-each-routine-s-enabled-state-at-every-convergence-seam.md
- 2026-08-19 — run recorded (+0.6h) — implement-20260819-113836
- 2026-08-21 — run recorded (+0.2h) — drive-20260820-1930-resume
- 2026-08-27 — run recorded (+0.3h) — implement-20260827-014149
- 2026-08-27 — run recorded (+0.1h) — implement-20260827-064000
- 2026-09-01 — ticket archived — 20260819103855-rule-on-renaming-a-live-routine-in-place.md
- 2026-09-01 — mission achieved — mission.md
