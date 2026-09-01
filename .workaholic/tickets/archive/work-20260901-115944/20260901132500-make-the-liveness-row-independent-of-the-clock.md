---
created_at: 2026-09-01T13:25:00+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy:
verification_handoff: 
feedback: [20260901112130-the-unmerged-branch-list-is-30-long-and-22-of-them-are-dead.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
---

# Make the liveness row independent of the clock

## Overview

Minted mid-run 2026-09-01 by an `/implement` unit on `leave-only-live-work-in-the-unmerged-branch-list`,
under the failure contract's *an observation outside the current ticket's scope becomes a ticket*.

`node scripts/test-workflow-scripts.mjs` **fails at some hours of the day and passes at others**,
on an untouched checkout. Measured 2026-09-01 ~13:20 UTC (22:20 JST) against `origin/main` with no
local modification: `5841 passed, 1 failed`, the one failure being

```
# moderate: the tick runs every step, and every step reports
  FAIL  a subject no step raised reads settled
```

**Localized.** The assertion runs `question-liveness.sh --key nothing-raised-this --step
human-checkin --run <this tick's report>` and expects `settled`. That script answers `settled`
only when the owning step **ran and reported `ok`**, and answers `unknown` when the step is
absent, degraded, blocked or skipped — a distinction its own header calls load-bearing and
correct. `step-human-checkin.sh` reports `status: skipped, reason: quiet_hours` inside
`WORKAHOLIC_QUIET_HOURS` and `off_day` outside `WORKAHOLIC_WORK_DAYS`. So the fixture tick's
`human-checkin` row is `ok` during working hours and `skipped` outside them, and the assertion
inverts with the wall clock of whoever runs the suite.

Neither script is wrong. The **test** asserts a behaviour that only holds inside the speaking
window, without pinning the window.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a check that fails for a reason unrelated
  to the change stops being read

## Key Files

- `scripts/test-workflow-scripts.mjs` — the assertion `a subject no step raised reads settled`
  and its sibling `and a subject its owning step DID raise reads live`, inside
  `moderate: the tick runs every step, and every step reports`.
- `plugins/workaholic/skills/moderate/scripts/question-liveness.sh` — read the header before
  touching it; `unknown` is deliberately not collapsible into `settled`.
- `plugins/workaholic/skills/moderate/scripts/step-human-checkin.sh` — emits `skipped`/
  `quiet_hours` and `skipped`/`off_day`; the two exits are around line 417 and 428.
- `plugins/workaholic/skills/moderate/scripts/lib/speaking-window.sh` — the one derivation of the
  window, and what the fixture would have to pin.

## Implementation Steps

Diagnosis is done above; reproduce it first, then fix the test rather than the readers.

1. **Reproduce both directions.** Run the suite once with the environment forced inside the
   window and once outside it (`WORKAHOLIC_QUIET_HOURS` / `WORKAHOLIC_WORK_DAYS` /
   `WORKAHOLIC_QUIET_TZ`), and confirm the assertion flips with nothing else changing.
2. **Pin the window in the fixture**, not in the reader: the tick under test should run with an
   explicitly-set speaking window that is open, so `human-checkin` reports `ok` whatever the
   host clock says. Set it where the fixture already builds the tick's environment.
3. **Then assert the other half deliberately**: with the window closed, the same key must read
   `unknown` — never `settled`. That is the distinction `question-liveness.sh`'s header calls
   load-bearing, and it currently has no row of its own; adding it turns a flake into two
   assertions that each say something.
4. **Sweep for siblings.** Any other assertion in the suite whose subject is a step that abstains
   on the clock has the same defect. Report what was found rather than fixing only the one that
   fired.
5. **Change neither reader.** `question-liveness.sh` answering `unknown` for a skipped step, and
   `step-human-checkin.sh` skipping inside the window, are both correct and are what the two new
   assertions pin.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The suite passes at any hour of any day, with no host-clock dependency in this test.
- Both halves are asserted: an open window reads `settled` for an unraised key, a closed window
  reads `unknown` for the same key.
- `question-liveness.sh` and `step-human-checkin.sh` are byte-identical.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` inside and outside the window (force it through the
  three environment variables), both green.
- `git diff` shows no change under `plugins/workaholic/skills/moderate/scripts/`.

**Gate** — what must pass before approval:

- The suite passes in both runs above.

## Considerations

- The obvious wrong fix is to make `question-liveness.sh` answer `settled` for a `skipped` step.
  Its header refuses that by name: a step that did not look has not established that anything
  settled, and collapsing the two re-creates the silence the reader exists to end.
- The failure is **pre-existing on `main`** and was measured there rather than inferred; it is
  not a regression from the change that was in flight when it was found.
