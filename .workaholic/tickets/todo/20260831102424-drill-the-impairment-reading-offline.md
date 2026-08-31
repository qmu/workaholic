---
created_at: 2026-08-31T10:24:24+00:00
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
