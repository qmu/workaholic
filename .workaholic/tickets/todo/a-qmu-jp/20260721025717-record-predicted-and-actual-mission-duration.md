---
created_at: 2026-07-21T02:57:17+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain, Config]
effort:
commit_hash:
category:
depends_on:
mission: reorganize-missions-under-strategies
---

# Record predicted and actual mission duration

## Overview

A mission artifact gains a **prediction** of how long its implementation will take a coding agent and the **actual** it consumed, so archived missions accumulate a trend the next planning reads. Measurement ruling (mission creation, 2026-07-21): the actual is **agent active time** — `/monitor` accumulates each leaf's dispatch→completion wall-clock per mission, summed across waves and across nights. Calendar span and commit-timestamp heuristics were rejected (idle pollution / estimation logic). Solo `/drive` time outside `/monitor` is deliberately **not** counted — a documented limitation, not a gap to close silently: the prediction answers "how long will the agents need", and the monitor run is where agents run at scale.

Frontmatter gains `predicted_hours:` (stamped once at creation, decimal hours) and `actual_hours:` (accumulated, decimal). Prediction is **deterministic**: a script over archived missions' records — median `actual_hours ÷ acceptance-item total` across archived missions that have both, times the new mission's planned item count. With no archived basis (today's state), it reports `basis: 0` and the field stays empty with a changelog note — never a fabricated number.

## Policies

The standard engineering policies that govern this ticket. Read each linked hard copy before writing code; keep every change defensible against its Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — conventional layout (applies to all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX scripts (applies to all code work)
- `workaholic:planning` / `policies/verify-before-building.md` — the predictor is a heuristic over sparse data: keep it one small script, honest about `basis`, verified against fixtures before anything steers by it
- `workaholic:design` / `policies/history-structures.md` — per-run actuals append as changelog history (`run recorded — <run-id>`), so the accumulated number is reconstructable from lines, never a bare mutable counter alone
- `workaholic:implementation` / `policies/objective-documentation.md` — predicted/actual are computed and measured values with stated units; no narrated estimates
- `workaholic:operation` / `policies/ci-cd.md` — prediction and accumulation are reproducible scripts, identical for human or AI callers

## Key Files

- `plugins/workaholic/skills/mission/scripts/create.sh` — scaffold gains `predicted_hours:` and `actual_hours:` (empty).
- `plugins/workaholic/skills/mission/scripts/predict-duration.sh` — new: args `<planned-item-count>`; scans `missions/archive/*/mission.md` for non-empty `actual_hours` + `progress.sh` totals; emits `{predicted_hours, basis, per_item_median}` (`predicted_hours: null` when `basis` is 0). Pure read, no writes.
- `plugins/workaholic/skills/mission/scripts/record-run-hours.sh` — new mutator: args `<mission> <hours> <run-id>`; idempotent via the `(run recorded, <run-id>)` changelog key — a re-run adds nothing; otherwise adds `<hours>` into `actual_hours` (awk float add), appends the changelog line, git-stages. The changelog line carries the hours in its event phrase (`run recorded (+2.4h) — <run-id>`) so history reconstructs the sum.
- `plugins/workaholic/skills/mission/SKILL.md` — Schema (two fields, units, the monitor-only measurement rule and its limitation), Creation Interrogation (prediction stamped at the end of emission, stated to the developer as a report line, never asked), close/archive prose (both fields ride into archive; nothing to do in `close.sh` itself).
- `plugins/workaholic/skills/monitor/SKILL.md` + `plugins/workaholic/commands/monitor.md` — §2/§3: the dispatcher notes each leaf's dispatch and completion timestamps, computes hours, and calls `record-run-hours.sh` once per mission per run-id (run-id = the run's branch-safe timestamp, minted once at pre-flight); §5 final report shows predicted vs accumulated actual per mission.
- `plugins/workaholic/skills/mission/scripts/list.sh` — include `predicted_hours`/`actual_hours` in entries (the trend surface `predict-duration.sh` and `/catch` read).
- `scripts/test-workflow-scripts.mjs` — fixture archive missions with actuals → predictor median math, `basis: 0` honesty, `record-run-hours.sh` idempotency and float accumulation.
- `outputs/workflows` — mission skill built: run the argument-less build. `CLAUDE.md`/`README.md`/`.workaholic/README.md` in the same change.

## Implementation Steps

1. Add the two frontmatter fields to `create.sh` and the SKILL schema.
2. Implement `predict-duration.sh` (read-only, deterministic, `basis`-honest) and `record-run-hours.sh` (idempotent by run-id, history-carried hours).
3. Wire prediction into the create-flow end (`commands/mission.md`: after the ticket set is emitted, run the predictor with the acceptance count, stamp when `basis > 0`, else record the no-basis changelog note) — a report line, never a question.
4. Wire accumulation into `/monitor` (skill §2/§3 + command): per driven mission per run, one `record-run-hours.sh` call; surface predicted-vs-actual in §5.
5. Update `list.sh`; add hermetic tests; run the full build; update docs.

## Quality Gate

Interrogated at mission creation (2026-07-21); verification depth ruling: hermetic suite + in-session demo.

**Acceptance criteria**

- `predict-duration.sh` returns the correct median-per-item × count on a fixture archive, and `{predicted_hours: null, basis: 0}` on an empty one; it never writes.
- `record-run-hours.sh` accumulates decimal hours exactly once per `(mission, run-id)` across repeated calls; the changelog line carries the increment; `actual_hours` equals the sum of its lines' increments.
- A scaffolded mission carries both fields empty; `list.sh` surfaces them.
- Monitor prose stamps one run-id per run and reports predicted vs actual in the final report.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green with predictor/recorder cases (including double-call idempotency and the empty-archive case).
- `node scripts/build-plugins/build.mjs` + `verify.mjs` + `validate-metadata.mjs` green; POSIX lint.

**Gate**

- Suite green, build/verify green, and an in-session demo: run `record-run-hours.sh` twice with one run-id against a throwaway mission and show the single accumulation; run `predict-duration.sh` against the fixtures.

## Considerations

- Sparse early data makes the median noisy; `basis` is reported so the create flow can state confidence honestly ("predicted from 2 archived missions") rather than dress a guess as data (`predict-duration.sh`).
- Leaf wall-clock includes tool waits; that is fine — the question is "how long must the orchestration run", not CPU seconds (`skills/monitor/SKILL.md`).
- Do not let `actual_hours` become hand-edited: the recorder is its only writer, same doctrine as `tick-acceptance.sh` (`skills/mission/SKILL.md`).
- This mission itself predates the fields; its own drive may backfill them via the recorder as the live demo's second half — worthwhile but optional, and if done, recorded as a normal run line.
