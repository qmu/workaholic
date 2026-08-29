---
created_at: 2026-08-29T02:19:46+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: warn-a-direction-before-its-date-silences-the-loop
merge_policy:
verification_handoff: 
---

# Reproduce the silent expiry and pin it

## Overview

PROPOSED. The first ticket of the mission reproduces the defect before anything
is built for it, so every later ticket is measured against a failing test rather
than against a description. The defect: a live, in-date, `on_course` direction
one day from its `target_date` produces **no reading and no question anywhere in
the layer** — `survey-strategies.sh` emits `pace: on_course`, `overdue: false`,
`dormant: false`, and `direction-state.sh` answers `live`, so
`step-direction-health.sh` has no non-`live` reading to ask about. The day after,
`past_target_date` refuses the proposal and the only signal is
`direction-overdue`, asked in arrears.

Measured on `an-autonomous-improvement-loop-run-by-the-routines` at the hour the
ask was written: `days_to_target: 2`, `pace: on_course`, `overdue: false`,
`dormant: false`, `quiescent: true` — every reading healthy, two days from
silence.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/testable-domain-logic.md` — the reading is proved over a fixture, not asserted

## Key Files

- `scripts/test-workflow-scripts.mjs` — where the hermetic pin lives; it already
  walks the direction layer's readings over git-backed fixtures.
- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — the row the
  test reads; `WINDOW_DAYS` (the `$window_days` term) and `days_to_target` are
  both already on it.
- `plugins/workaholic/skills/strategy/scripts/direction-state.sh` — the
  lifecycle reading the test asserts answers `live` today.
- `plugins/workaholic/skills/moderate/scripts/step-direction-health.sh` — the
  step the test asserts asks nothing today.

## Implementation Steps

1. Read the three scripts above end to end before writing anything — in
   particular `survey-strategies.sh`'s `overdue`/`dormant`/`quiescent` blocks,
   which are the shape `expiring` will follow, and the fixed precedence comment
   in `direction-state.sh`.
2. Build a **git-backed** fixture (the shape `verify-arrival` and
   `verify-residue` already use, because landed work is a `git log --since`
   read): one `active` strategy assigned to the running identity, cited by a
   feedback record with landed work, `target_date` one day out.
3. Assert the defect as it stands today: the survey row carries no term naming
   the approaching date, `direction-state.sh` answers `live`, and
   `step-direction-health.sh` produces **no** subject for that slug.
4. Assert the second half — a fixture one day past its date reads `overdue` and
   the proposal is refused `past_target_date`, so the only signal arrives after
   the silence has begun.
5. Leave the test **failing on the first assertion** (the missing reading) and
   passing on the arrears assertion, so ticket 2 turns it green. Name it so a
   later reader sees which half is the defect.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A hermetic test exists that fails today for exactly one reason: no reading in
  the layer names a direction one day from its date.
- The same test asserts, and passes on, the arrears behaviour: past the date the
  reading is `overdue` and the proposal is refused `past_target_date`.
- No network call, no `gh`, no Slack post anywhere in the fixture.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the new case fails with the stated
  reason before ticket 2, and no other case changes.

**Gate** — what must pass before approval:

- The failure message names the missing reading rather than a generic mismatch,
  so a reader who has not read this ticket can tell what is absent.

## Considerations

- The fixture must be git-backed rather than a bare tree: `landed[]` is derived
  from `git log --since`, and a non-git fixture would make the direction read
  `unknown` and pass the assertion for the wrong reason.
- Resist asserting the *future* field name here. This ticket pins the **absence**
  of any warning; ticket 2 chooses the name.
