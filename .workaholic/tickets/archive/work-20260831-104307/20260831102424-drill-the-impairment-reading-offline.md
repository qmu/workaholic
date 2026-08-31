---
created_at: 2026-08-31T10:24:24+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260831102424-let-a-changed-impairment-earn-a-root.md
mission: name-the-steps-a-tick-could-not-read
merge_policy:
verification_handoff: 
---

# Drill the impairment reading offline

## Overview

PROPOSED. Every mechanism this loop has built is proved by a `verify-*` drill in
`scripts/e2e/loop-drill.sh`, registered in the drill register (`docs/loop-drill-runbook.md`
§9) with a `bearing: "breaker"` row, run by `verify-all` and by the `Loop Drills` workflow on
every push — a drill with no breaker row is counted **`unproved`**.

This mission's defect is a **reporting silence**, which is the class a return-shape assertion
is worst at catching: a refactor that keeps the JSON shape and quietly drops the reading
would pass. So the breaker is written against the **behaviour** — restore the pre-change
parse, and the drill must show the impairment going unnamed and the impaired tick going
silent.

`verify-impairment` needs **no network, no `gh` and no Slack**: the renderer's whole input is
a JSON document and a tick log, both of which a fixture can write.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — the proof is what keeps an unattended surface honest between turns

## Key Files

- `scripts/e2e/loop-drill.sh` — the dispatcher; a new `verify-impairment` `case` arm, whose
  presence `verify-all` derives its set from.
- `docs/loop-drill-runbook.md` §9 — the drill register table; the row records
  `kind: hermetic` and the shipping mission.
- `plugins/workaholic/skills/drive/scripts/drill-register.sh` — the register's one reader;
  **read only**, to confirm the new row parses.
- `plugins/workaholic/skills/moderate/scripts/render-tick-post.sh` — the mechanism under drill.
- `.github/workflows/loop-drills.yml` — one matrix leg per drill, so the red check run is
  named after the drill; confirm the new leg appears.

## Implementation Steps

1. Add `verify-impairment` to the dispatcher, building a throwaway fixture: a tick log with
   several days of sections, and captured `run.sh` JSON documents for a sequence of ticks.
2. Drill the rows the mission's three acceptance items name:
   - an impaired tick with a question names every impaired step and its reason in the root,
     with the count in the head;
   - **two consecutive** identically-impaired ticks both name it — the outside-the-diff
     property, and the one a diff-based render would fail;
   - an impaired tick with **zero** questions posts a root — the fourth gate;
   - the **middle** of three identically-impaired ticks posts nothing — the anti-restatement
     property;
   - a cleared impairment posts exactly one root, then silence;
   - a healthy tick's `root_text`, `post` and `reason` are byte-identical to the pre-change
     renderer;
   - a `skipped` step never appears as impairment.
3. Assert the whole reading is store-free: the drill writes no cursor, no field on any
   artifact, and no second log.
4. Add the **breaker row**, `bearing: "breaker"`, written against the behaviour: restore the
   renderer's two-pattern parse (dropping `status`), and require the drill to fail on the
   *impairment going unnamed and the impaired tick going silent* — not on a missing JSON key.
5. Prove the breaker actually fires before committing it. A breaker that cannot fail is the
   same gap with more moving parts.
6. Register the row in `docs/loop-drill-runbook.md` §9 (`kind: hermetic`, mission
   `name-the-steps-a-tick-could-not-read`) and confirm `drill-register.sh` reads it,
   `verify-all` picks it up and `loop-drills.yml` gets its matrix leg.
7. Confirm the drill runs with the network unavailable.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-impairment` passes on the shipped tree.
- Every row of the mission's three acceptance items is drilled, including the
  two-consecutive-ticks row and the silent-middle-tick row.
- The breaker row is written against the behaviour and is **demonstrated to fail** when the
  pre-change parse is restored.
- `drill-register.sh` returns the new row with `kind: hermetic` and its mission; the drill is
  not `unclassified` and not `unproved`.
- `sh scripts/e2e/loop-drill.sh verify-all` includes it; `loop-drills.yml` runs it as its own
  matrix leg.
- The drill makes no network call, no `gh` call and no Slack call.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-impairment`
- `sh scripts/e2e/loop-drill.sh verify-all`
- `bash plugins/workaholic/skills/drive/scripts/drill-register.sh` over the new row
- `node scripts/test-workflow-scripts.mjs` (fails on an unclassified drill)
- The breaker demonstrated failing, then reverted.

**Gate** — what must pass before approval:

- The breaker is shown failing against the restored pre-change parse. Without that the drill
  is `unproved` and the register says so.

## Considerations

- Writing the breaker against the return shape (assert `impaired[]` exists) is the easy
  version and is refused by name: it would pass a refactor that keeps the field and loses the
  render, which is this defect exactly.
- The fixture writes a tick log rather than calling `log-append.sh` in a loop only if that
  proves unstable; preferring the real writer is this repository's own drill discipline (a
  drill that passes against a line shape the writer never produces proves nothing).
- The drill does not exercise the Slack post: `workaholic:notify`'s transport is out of this
  mission's scope, and `root_text` is the contract the renderer owns.

## Final Report

Development completed as planned.

`verify-impairment` is a hermetic drill with **eleven load-bearing rows and one breaker**. Its
fixture is a throwaway directory: a tick log written through `log-append.sh` — the real
writer, so the drill cannot pass against a line shape the writer never produces — and a
sequence of captured `run.sh` JSON documents fed to the renderer on stdin. No network, no
`gh`, no Slack, no `origin`.

The rows walk one impairment's whole life across five logged ticks:

| Row | What it proves |
| --- | --- |
| `impairment_is_named` | an impaired tick names both steps with their reasons, count in the head |
| `impairment_earns_a_root` | the fourth gate: the same tick with **zero** questions posts, as `ready_impairment` |
| `impairment_survives_the_diff` | an hour later, `change_count: 0`, and the root still names all of it |
| `impairment_middle_tick_is_silent` | the same unchanged tick with no question posts **nothing** |
| `impairment_cleared_posts_once` | a clearing earns one root, and that root says what cleared |
| `impairment_then_silence` | the tick after is quiet again |
| `impairment_healthy_is_unchanged` | a healthy root and reason are what they were before this mission |
| `impairment_excludes_skipped` | `doc-drift` is `skipped` in every fixture and appears nowhere |
| `impairment_stores_nothing` | nothing written but the tick log the tick already keeps |
| `impairment_writes_nothing` | the checkout is byte-identical after the drill |
| `impairment_breaker` | **the intentional failure** |

Rows 3 and 4 are the pair that carries the mission and neither is sufficient alone: row 3 is
the outside-the-diff property a diff-gated render would fail, row 4 is the anti-restatement
property whose absence would make this the hourly status root retired twice.

### The breaker, demonstrated failing

Written against the **behaviour**, not the return shape: the pre-change parse restored (the
`status` pass dropped), and it must show **both** halves of the measured defect — the
impairment going unnamed on a root that posts, *and* the impaired tick going silent. A row
asserting `impaired[]` merely exists would pass the refactor this drill is for.

Proved rather than asserted: the same break was applied to the **real** script and the drill
run against it. Four load-bearing rows failed — `impairment_is_named`, `impairment_earns_a_root`,
`impairment_survives_the_diff` and `impairment_middle_tick_is_silent` — verdict `fail`,
`passed: 7, failed: 4`. The script was then restored and the drill is green again at
`passed: 11, failed: 0` with the checkout clean.

### Registered and reached

- `drill-register.sh drill verify-impairment` → `kind: hermetic`,
  `mission: name-the-steps-a-tick-could-not-read`, `mission_resolved: true`.
- `verify-all --list --kind hermetic` includes it (28 hermetic drills), which is what
  `loop-drills.yml` derives its matrix from — so it gets its own leg and its own named check
  run with no edit to the workflow, whose matrix is derived and never listed.
- `sh scripts/e2e/loop-drill.sh verify-all --kind hermetic`: 36 drills, **0 failed**,
  `verify-impairment` `pass` with `breaker: present` — not `unproved`, not `unclassified`.
- `node scripts/test-workflow-scripts.mjs`: 5422 passed, 0 failed, including
  *every drill the dispatcher names is classified in the register*.
- Re-run with `HTTPS_PROXY`/`HTTP_PROXY` unset and `PATH=/usr/bin:/bin`: passes unchanged.

### Discovered Insights

- **Insight**: The drill helpers' `_field` idiom (`sed 's/.*"key": *"\([^"]*\)".*/\1/'`) is
  **greedy** and answers with the *last* occurrence, so it silently reads the wrong value on
  any JSON carrying a repeated key. It cost one debugging round here, because `impaired[]`
  carries a `reason` on every entry and the top-level `reason` is the one under test.
  **Context**: Copied from `verify-condition-age`, whose output has exactly one `reason`. Any
  drill over a document with nested objects needs an anchored match instead — here, the exact
  leading substring `{"post": true, "reason": "..."`.

- **Insight**: `loop-drills.yml` needs no edit for a new drill: its matrix comes from
  `verify-all --list --kind hermetic`, which reads the dispatcher's `case` arms and the
  register. Adding the arm and the register row is the whole wiring.
  **Context**: The workflow's own header says a list in that file would be the second
  hand-kept enumeration the mission that built it exists to remove. Worth knowing before
  opening the YAML looking for where to add a leg.

- **Insight**: A reporting silence is the defect class a return-shape assertion is worst at,
  and the breaker discipline is what converts that from a hope into a check — the break is
  applied to the real script and the *rows that carry the mission* must be the ones that fail.
  **Context**: Here the correct break produced exactly the two symptoms measured in
  production (unnamed, and silent), which is the signal that the drill is pointed at the
  defect rather than at its implementation.
