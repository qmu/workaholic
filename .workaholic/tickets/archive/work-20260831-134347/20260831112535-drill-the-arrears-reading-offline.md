---
created_at: 2026-08-31T11:25:35+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-when-the-check-in-queue-is-stuck-and-bound-the-hold
merge_policy:
verification_handoff: 
---

# Drill the arrears reading offline

## Overview

`verify-checkin-delivery` already walks gate → ordering → step → event → root over a
tick-log fixture, which is exactly the path this mission changes. Extend it rather than
adding a drill: a second drill over the same path is how two fixtures start disagreeing
about one mechanism.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — the `verify-checkin-delivery` arm and its fixture.
- `docs/loop-drill-runbook.md` §9 — the drill register, which classifies each drill and
  is read by `drive/scripts/drill-register.sh`.


## Implementation Steps

1. Add rows to `verify-checkin-delivery` over its existing fixture: an `all_held` tick
   whose oldest hold predates the working-day boundary supplies an event naming depth and
   age; one inside the window supplies none; a degraded read supplies none and reports
   null counts; every held entry carries the gate's own refusal word.
2. Add a row proving two consecutive ticks with the same reading render **one** root
   line, so the diff rule is exercised rather than assumed.
3. Add a **breaker** row written against the **behaviour**, not the return shape: wire the
   boundary at a fresh constant instead of the gate's three variables, and the row must
   fire. A breaker a refactor can satisfy by keeping the JSON shape proves nothing.
4. Keep the drill hermetic — no network, no `gh`, no Slack post — so it stays in the set
   `.github/workflows/loop-drills.yml` runs on every push.
5. Confirm the register still classifies the drill hermetic and that its `bearing:
   "breaker"` row keeps it out of `unproved`.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-checkin-delivery` passes on the change and its
  breaker row fires on the pre-change composition.
- The drill makes no network call and needs no credential.
- `docs/loop-drill-runbook.md` §9 still classifies it, and it is not `unproved`.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-checkin-delivery`
- `sh scripts/e2e/loop-drill.sh verify-all`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The breaker row is proved able to fail, on the real script's source rather than a copy
  wired to fail by construction.


## Considerations

- Extending an existing drill grows its runtime; the alternative (a new drill) costs a
  second fixture for one mechanism, which the register's own rule about one reader per
  reading argues against.


## Final Report

Development completed as planned.

`verify-checkin-delivery` gained a section 6b over its existing fixture: the arrears' depth
and age, the gate's own refusal word per held entry, an `all_held` tick past the working-day
boundary earning its line, one inside the boundary staying silent, a degraded read reporting
null counts and no event, and the root's diff rule exercised (same reading → one line,
changed reading → a second). Section 7b adds a **second breaker** written against the
behaviour: the real script's source with the boundary wired at a fresh constant, over the
same fixture, changing no field and no key — the outlived line simply stops being earned.

The drill stays hermetic (no network, no `gh`, no Slack, no touch of the working tree, which
`checkin_writes_nothing` still pins). `docs/loop-drill-runbook.md` §5s gained a blame row per
new row and §9 still classifies the drill `hermetic` with a breaker, so it is not `unproved`.

Verification: `verify-checkin-delivery` → pass, 18 load-bearing rows, 2 breakers;
`verify-all` → 37 total, 26 proved, 0 failed; the hermetic suite 5455 passed.

### Discovered Insights

- **Insight**: the second breaker changes no JSON field, key or shape at all.
  **Context**: `verify-checkin-delivery`'s own first breaker records the lesson — a breaker
  written against the return shape is satisfied by any refactor that keeps the shape. Wiring
  the boundary at a constant leaves every field present and correctly typed; only the
  `event` string stops being earned, which is the behaviour under test.
