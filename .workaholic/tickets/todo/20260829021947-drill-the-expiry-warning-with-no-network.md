---
created_at: 2026-08-29T02:19:47+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: warn-a-direction-before-its-date-silences-the-loop
merge_policy:
verification_handoff: 
---

# Drill the expiry warning with no network

## Overview

PROPOSED. `scripts/e2e/loop-drill.sh verify-expiry` — the operator-facing drill
that proves the whole chain on demand rather than by waiting for a date to
arrive: a direction inside the window reads `expiring` and draws exactly one
question over two ticks; one outside reads `live` and draws none; an
already-overdue one still reads `overdue`; no reading re-dates, closes or amends
a direction, and the writer set stays at three.

It carries a **breaker row** — a deliberately broken wiring that must make the
drill fail — because a drill that cannot fail proves nothing. The breaker here
fires the moment the window is wired to a **new constant** instead of the
survey's own `$window_days`, which is the one shortcut ticket 2's design exists
to refuse.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/testable-domain-logic.md` — the chain is drilled end to end, offline

## Key Files

- `scripts/e2e/loop-drill.sh` — the drill. `verify-arrival` and `verify-residue`
  are the closest precedents: git-backed fixtures, the open-proposal read
  **supplied** through `--open-proposals` rather than stubbed, and a labelled
  breaker row.
- `docs/loop-drill-runbook.md` — the operator procedure and the
  failure-reason→file blame table this case must be added to.
- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh`,
  `plugins/workaholic/skills/strategy/scripts/direction-state.sh`,
  `plugins/workaholic/skills/moderate/scripts/step-direction-health.sh` — read
  only; the chain under drill.

## Implementation Steps

1. Read `cmd_verify_arrival` and `cmd_verify_residue` in full before writing
   anything — the fixture construction, the row extractor (which parses the row
   rather than the line, for the reason its comment records), the
   `--open-proposals` supply, and the breaker row's shape.
2. Build the git-backed fixture set: one direction inside the window, one
   outside, one already past its date, each `active`, `mine`, cited, with landed
   work.
3. Drill the readings: `expiring` inside the window, `live` outside,
   `overdue` past the date — and the precedence pairs ticket 3 fixed.
4. Drill the question: `direction-expiring:<slug>` asked once over **two** ticks,
   addressed to the assignee, with the leaving named; and no question for the
   direction outside the window.
5. Drill the negative space: no reading re-dates, closes or amends a direction;
   the strategy artifact's writer set is still exactly
   `amend.sh`/`close.sh`/`create.sh`; no gate moved.
6. Add the breaker row and **prove it fails**: rewire the window to a fresh
   constant and confirm the drill goes red. Label it as the intentional failure,
   as the neighbouring drills label theirs.
7. Register the new case in the usage string, the dispatch, and the runbook's
   blame table.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-expiry` passes with **no network**, no
  `gh` call and no Slack post.
- All three readings and the two-tick asked-once gate are asserted.
- The breaker row is present, labelled, and demonstrated to fail.
- The case appears in the drill's usage string and in the runbook's blame table.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-expiry` — green.
- The same with the breaker wired — red, for the stated reason.

**Gate** — what must pass before approval:

- The drill runs offline end to end; a case that silently needs the network is
  the failure this whole family of drills was built against.

## Considerations

- The drill is **operator tooling outside the plugin** and assumes the server's
  full `gh` and `qfs`. It ships to no other agent, so nothing in
  `plugins/` may come to depend on it.
- Time-dependent fixtures are the hazard here: derive the fixture dates from the
  run's own clock rather than hard-coding them, or the drill rots the moment the
  dates pass.
