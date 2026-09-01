---
created_at: 2026-08-29T12:21:05+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: run-the-loop-s-own-proofs-on-every-turn
merge_policy:
verification_handoff: 
---

# Pin the drill verdict path offline

## Overview

Pin the whole path offline in `scripts/test-workflow-scripts.mjs` — runner → verdict → CI
wiring → the tick's reading — and **fail when a drill is added that the aggregate verb
cannot reach**. That last clause is what retires the eight presence assertions of the
shape `assertTrue("verify-expiry is in loop-drill.sh", /cmd_verify_expiry\(\)/.test(drill))`:
a regex proves a drill *exists* and never that it *passes*, and leaving both would be two
mechanisms claiming one job. The suite is what CI already runs, so the pin costs no new
executor.

## Policies

- `workaholic:implementation` / `policies/testing.md` — the guarantee is a fact a change can lose, not a claim in prose
- `workaholic:implementation` / `policies/coding-standards.md` — one mechanism per job

## Key Files

- `scripts/test-workflow-scripts.mjs` — holds the eight presence assertions (around
  lines 971, 2146, 2193, 26587, 27735 and their neighbours) and the two drill sub-suites
  that already execute `seed`/`reset`/`verify-specificate`/`verify-implement` hermetically
- `scripts/e2e/loop-drill.sh` — the dispatcher enumeration the pin reads
- `.github/workflows/validate-plugins.yml` — the CI wiring the pin asserts

## Implementation Steps

1. Add the reachability pin: enumerate `cmd_verify_*()` definitions and the dispatcher's
   `case` arms from the drill file, and fail when any is absent from the aggregate verb's
   set **and** absent from ticket 1's recorded classification. A new drill is then either
   run or deliberately classified — never silently unreached.
2. Pin the verdict shape: a fixture run of the verb yields one of `pass`/`fail`/`skipped:<reason>`
   per drill, and a non-zero exit if and only if some verdict is `fail`.
3. Pin the CI wiring by reading the workflow file: the verb is invoked, the job declares no
   secret, and the checkout is not shallow.
4. Pin the tick's reading: a green run yields no event and no question; a failing one
   yields exactly one question keyed `drill-failing:<drill>`; a degraded read is named.
5. Delete the eight presence assertions in the same change, and say in the commit why —
   the reachability pin strictly subsumes them.
6. Keep it hermetic: throwaway directories under the OS temp dir, no `gh`, no network, no
   touching the working tree — the suite's standing contract.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Adding a `cmd_verify_*` the verb cannot reach and that ticket 1 has not classified fails
  the suite.
- The verdict vocabulary and the exit-status rule are pinned.
- The CI wiring and the tick's four readings are pinned.
- The eight presence assertions are gone, with no drill losing coverage.
- The suite still calls no `gh`, makes no network call and leaves the working tree
  untouched.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` on the unmodified tree — green.
- The same with an unreachable drill added to a scratch copy — red, naming the drill.
- `grep -c 'is in loop-drill.sh' scripts/test-workflow-scripts.mjs` → 0.

**Gate** — what must pass before approval:

- All three probes behaved as stated, offline.

## Considerations

- The pin must read the **dispatcher**, not a list in the test — a list in the test is the
  ninth presence assertion under another name.
- A drill deliberately classified `needs_server` is reachable-by-classification rather than
  by execution; the pin has to accept that state explicitly or it will push someone to
  delete the classification instead of maintaining it.

## Final Report

Development completed as planned.

`testDrillVerdictPath` pins the whole path in `scripts/test-workflow-scripts.mjs` — the
suite CI already runs, so the pin costs no new executor — in the order the path runs:

1. **Reachability.** The dispatcher's own `case` arms are enumerated from the drill file
   (never a list in the test, which would be the ninth presence assertion under another
   name) and compared with the register both ways: a drill the register does not classify
   fails, and a register row the dispatcher does not name fails too. Every classification
   must be one of the three measured kinds.
2. **The verdict vocabulary and the exit-status rule**, over a fixture built from a copy of
   the real drill file with five known drills appended: one that passes with a breaker, one
   that fails, one that passes with **no** breaker, one whose environment cannot answer, and
   one classified `needs_server` that exits 1 if it is ever invoked. Asserted: the three
   verdicts, `unproved` outside the passing total, a failure carrying the row that went
   false, `--list` invoking nothing, and a non-zero exit **if and only if** some verdict is
   `fail` — proved in both directions, including that a wholly skipped run and an unproved
   one are each exit 0.
3. **The CI wiring**, read off the workflow file: the verb is invoked, the matrix is
   derived from `--list`, both triggers are present, no secret is declared, no permission
   beyond `contents: read`, and the checkout is not shallow.
4. **The tick's reading**, over a fixture repository with a stubbed transport: a green run
   asks nothing and supplies no event; a failing drill is exactly one question keyed
   `drill-failing:<drill>`, naming the mission and addressed to its assignee; a failing
   check that is not a drill belongs to `base-health`; a read it could not make is degraded
   by name; a repository with no workflow reads `unavailable`. Plus: the step leaves the
   tree byte-identical, never reaches `plan-units.sh`, reaches no acting call site, and is
   registered in both `STEPS` and the classification table.

**The eight presence assertions are deleted** and the phrase they were named after appears
nowhere in the suite — which the pin itself asserts, so it cannot come back unnoticed. The
reachability pin strictly subsumes them: each said one drill exists; this says every drill
is reached or deliberately classified.

Hermetic throughout: throwaway directories under the OS temp dir, no `gh`, no network, and
the working tree untouched. 45 assertions; the full suite is 5081 passed, 0 failed.

### Discovered Insights

- **Insight**: A pin over a script's source must read the **code**, not the prose. The
  assertion that the step never reaches `plan-units.sh` failed on the step's own header,
  which names it to record why it is refused — an assertion that cannot tell a refusal from
  a call would have to be weakened the first time somebody explained themselves.
  **Context**: Stripping comment lines before matching is the cheap fix, and it keeps the
  incentive right: explaining a refusal in a header must never cost you the assertion that
  enforces it.

- **Insight**: The fixture is a **copy of the real drill file with known drills appended**,
  rather than a hand-written miniature. It keeps the pin honest about the real `add_row`,
  `emit_verdict` and exit-code contract while making the verdicts predictable.
  **Context**: The same shape as the drills' own breaker rows: exercise the real seam
  against a deliberately known input rather than a re-implementation of it.
