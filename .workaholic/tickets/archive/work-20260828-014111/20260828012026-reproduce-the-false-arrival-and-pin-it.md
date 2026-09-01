---
created_at: 2026-08-28T01:20:26+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-what-the-direction-could-not-see-before-calling-it-arrived
merge_policy:
verification_handoff: 
---

# Reproduce the false arrival and pin it

## Overview

Establish the defect mechanically before anything is coded against it. A hermetic test
builds a fixture tree in which a strategy's attributed work has all landed while an
**unattributed** active mission still holds queued tickets, and asserts what
`survey-strategies.sh` answers there today: `quiescent: true`, `waiting_missions: 0`,
`waiting_count: 0`. That is a **characterization** assertion — it records the current
reading, so the later tickets in this mission have something that fails when they change
it. Ticket `refuse-an-arrival-over-a-tree-we-could-not-see` is what inverts it.

Measured on this repository at 2026-08-28 00:41 UTC on the strategy
`an-autonomous-improvement-loop-run-by-the-routines`: `quiescent: true`, `landed` 125,
while four active missions and ten queued tickets read `attributed: false` through
`strategy/scripts/mission-strategy.sh`.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/test-workflow-scripts.mjs` — the hermetic suite; the new case and its fixture builder live here
- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — the script under test (read only in this ticket)
- `plugins/workaholic/skills/strategy/scripts/mission-strategy.sh` — proves the fixture's mission really is unattributed
## Implementation Steps

1. Read `scripts/test-workflow-scripts.mjs` for how existing cases build a throwaway
   repository under the OS temp dir — the suite never touches the working tree and never
   calls `gh` or the network, and this case must not either.
2. Build the fixture: one `active` strategy citing one feedback record, a mission and a
   landed ticket citing that same record (so `landed[]` is non-empty), plus a **second**
   active mission citing a different record with two queued tickets under it. Back it with
   a real git repository, since `landed` is a `git log --since` read.
3. Assert through `mission-strategy.sh` that the second mission reads `attributed: false`
   — the fixture is only the fixture this mission needs if that holds.
4. Assert the current reading: `survey-strategies.sh` answers `quiescent: true` with
   `waiting_missions: 0` and `waiting_count: 0` for the strategy.
5. Label the assertion in the test's own name and a comment as the **characterization** of
   a defect, naming the ticket that inverts it, so a later reader does not read it as the
   behaviour we want.
## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A hermetic case exists that constructs the fixture and asserts `quiescent: true` over it.
- The case proves, in the same run, that the second mission is unattributed.
- The case is labelled as characterizing a defect and names the ticket that inverts it.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` passes with the new case present.
- The case creates nothing outside the OS temp dir and makes no network call.

**Gate** — what must pass before approval:

- The suite is green.
- Removing the fixture's unattributed mission makes the new case fail, proving it reads the
  residue rather than a constant.

## Considerations

- The assertion is deliberately inverted later in this mission. Keep the two tickets'
  wording linked so the inversion reads as the plan rather than as a regression.
- `landed` is derived from git history, so the fixture must be a real repository with
  commits inside the survey window; a bare file tree will read `landed: []` and the case
  would then assert `dormant`'s shape instead.
## Final Report

Development completed as planned.

`makeResidueFixture()` builds the git-backed tree the whole mission is read over: an
`active` strategy whose attributed work has all landed (a finished mission plus its
archived ticket, both citing the record the strategy cites) beside a **second** active
mission citing a record no strategy cites, holding two queued tickets.
`testFalseArrivalCharacterization` proves through `mission-strategy.sh` that the second
mission really is unattributed, then records what `survey-strategies.sh` answers over that
tree: `quiescent: true` with `waiting_missions: 0` and `waiting_count: 0`.

### Discovered Insights

- **Insight**: the fixture's residue mission must cite a *different* feedback record, not
  simply omit the relation — a mission citing nothing is unattributed for a reason that
  looks identical from the reader and would still be residue if the walk were fixed.
  **Context**: it keeps the fixture about the walk's LOSSINESS rather than about a
  malformed artifact, which is what the mission is answering.
- **Insight**: emptying the residue by *attributing* the second mission is not a neutral
  edit — it makes that mission this direction's work in flight, so `work_waiting` fires and
  the gate outcomes move for a reason that has nothing to do with the residue.
  **Context**: any later byte-identity assertion over this fixture must empty the residue by
  REMOVING the mission, not by attributing it.
