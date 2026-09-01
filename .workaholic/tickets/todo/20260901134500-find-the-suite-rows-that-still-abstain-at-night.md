---
created_at: 2026-09-01T13:45:00+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-the-tick-add-to-a-standing-thread-instead-of-restating-itself
merge_policy:
verification_handoff:
feedback: 20260901122046-the-tick-can-only-behave-like-a-bot-a-per-tick-thread-key-a-banned-recency-match-and-a-string-diff-post-gate.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md
---

# Find the suite rows that still abstain at night

## Overview

**Minted mid-drive, 2026-09-01.** One row of `scripts/test-workflow-scripts.mjs` was a clock, and
it is fixed in the same publication as this ticket. What that repair did **not** establish is
whether it was the only one — and the evidence says it was not.

The fixed row: `testModerateRun` ran the whole tick with no `--hour`/`--weekday`,
`step-human-checkin.sh` reads the speaking window off the **wall clock** and reports
`skipped`/`quiet_hours` inside `WORKAHOLIC_QUIET_HOURS` (default `22-08`, `Asia/Tokyo`), and
`question-liveness.sh` answers `unknown` for `step_skipped` where the assertion wanted `settled`.
Measured on an untouched `origin/main` at 1ac1548a:

| When | Verdict |
| ---- | ------- |
| 21:44 JST | `5852 passed, 0 failed` |
| 22:1x JST | `5841 passed, 1 failed` — `a subject no step raised reads settled`, `expected "settled", got "unknown"` |

**The failure is one row; the ELEVEN missing assertions are the open question.** The count fell by
eleven across the same boundary on an unchanged tree, and only one row turned red. So roughly ten
further assertions stop running at night rather than failing — silently, which is worse than a red
row because nothing reports it. This ticket is that sweep.

## Policies

- `workaholic:implementation` / `policies/machine-checkable-domain-gaps.md` — make the gap fail early
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/test-workflow-scripts.mjs` — the suite; `testModerateRun`'s tick invocation now names its window
- `plugins/workaholic/skills/moderate/scripts/step-human-checkin.sh` — `skipped`/`quiet_hours` and `skipped`/`off_day` off the wall clock
- `plugins/workaholic/skills/moderate/scripts/lib/speaking-window.sh` — the window's one derivation and its `--hour`/`--weekday` overrides
- `plugins/workaholic/skills/moderate/scripts/question-liveness.sh` — `step_<status>` → `unknown`

## Implementation Steps

1. **Reproduce the count, not the failure.** Run the whole suite twice on one unchanged tree —
   once with the wall clock inside `WORKAHOLIC_QUIET_HOURS` and once outside — and diff the two
   lists of `ok` lines. The rows present in one and absent in the other are the subject; the
   totals alone (5852 against 5841) say there are about ten and say nothing about which.
2. **Do not fix by widening the window globally.** Setting `WORKAHOLIC_QUIET_HOURS` for the whole
   suite process would hide exactly the rows that legitimately assert the quiet-hour behaviour —
   `a tick inside the quiet window posts nothing, and says which window held it` is one, and it
   must keep passing at every hour. The repair is per-row, naming the hour the row needs.
3. For each row found, decide which of two it is: an assertion that **means** to exercise the
   window (give it an explicit `--hour`/`--weekday`, as the sibling rows already do) or one that
   merely inherits it (name the window in its fixture, as `testModerateRun` now does).
4. Prove the whole suite's verdict **and its passing count** are identical at both hours.
5. If any row cannot be made hour-independent, say so by name with the reason rather than leaving
   it in the count.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `node scripts/test-workflow-scripts.mjs` reports the same passing count and the same verdict
  inside and outside `WORKAHOLIC_QUIET_HOURS`, on an unchanged tree.
- The rows that assert quiet-hour behaviour still assert it, and still pass at both hours.
- No product script changed to make a test pass.

**Verification method** — the commands/tests/probes that prove them:

- Two full runs, one at each hour (or with the window moved to make each case reachable on
  demand), with their `ok` lists diffed and the diff empty.

**Gate** — what must pass before approval:

- The suite's passing count is a function of the tree and not of the hour.

## Considerations

- **A green suite by day is how this survived.** CI runs on push at whatever hour the push
  happens, so this has been intermittent there and reads as a flake.
- **The already-fixed row is evidence, not scope.** Do not re-derive it; it is recorded above and
  in the fixture's own comment. What is unknown is the other ten.
- **An unattended run driving at night cannot tell its own regression from this**, which is what
  makes a silently-absent assertion worse than a failing one.
