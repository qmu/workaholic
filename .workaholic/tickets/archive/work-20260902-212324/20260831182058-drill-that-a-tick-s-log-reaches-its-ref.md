---
created_at: 2026-08-31T18:20:58+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: take-the-moderation-tick-s-log-off-main
merge_policy:
verification_handoff: 
---

# Drill that a tick's log reaches its ref

## Overview

PROPOSED. The ask names two drills, and this is the first: one that **fails when
a tick's log does not reach the ref**. It is the positive proof — the log's whole
value is that it survives a discarded container, and after this mission it
survives by a path nothing currently exercises.

`scripts/e2e/loop-drill.sh` is the home. `verify-all` derives what it runs from
the dispatcher's own `case` arms plus the drill register
(`docs/loop-drill-runbook.md` §9, read only through `drive/scripts/drill-register.sh`),
and `.github/workflows/loop-drills.yml` runs the **hermetic** part on every push
and pull request with one matrix leg per drill — which is what lets `/moderate`'s
`drill-health` step name the failing drill.

Three register rules bind this ticket. The drill must be classified `hermetic`
(no network, no `gh`, no credential — it builds its own fixture), or it will not
run in CI where it is needed. It must carry a **breaker row** (`bearing:
"breaker"`) or it is counted `unproved` outside the passing total. And a drill the
register does not classify is `skipped:unclassified`, which
`test-workflow-scripts.mjs` fails on — so the register row ships in the same
change as the drill.

## Policies

- `workaholic:implementation` / `policies/testing-strategy.md` — a proof that cannot fail proves nothing
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — an operational log is read, not reviewed

## Key Files

- `scripts/e2e/loop-drill.sh` — the dispatcher and the new `verify-*` arm.
- `docs/loop-drill-runbook.md` §9 — the drill register: `Kind`, `Breaker`,
  `Mission`.
- `plugins/workaholic/skills/drive/scripts/drill-register.sh` — the register's
  one reader.
- `.github/workflows/loop-drills.yml` — the per-drill matrix leg.
- `scripts/test-workflow-scripts.mjs` — fails on an unclassified drill.
- `plugins/workaholic/skills/moderate/scripts/persist-log.sh` — the seam under
  test.

## Implementation Steps

1. Build a throwaway fixture: a local repository with a remote it can push to, a
   checkout carrying a day file with one tick's sections, and no credential of any
   kind. It must run with no network, no `gh` and no `ANTHROPIC_API_KEY`.
2. Run the persist against it and assert the log reached the **ref**: the ref
   exists, carries the tick's section, and every step line is present.
3. Assert the negative in the same drill: `main` gained no commit, no `work-*`
   branch was created, no worktree, no pull request, and the caller's checkout is
   byte-identical.
4. Assert the union: persist a second overlapping section from a second checkout
   and confirm neither loses a line.
5. Assert the degradation: with the ref unreachable, the run reports its named
   reason and leaves the log in the checkout for the next tick. A drill that only
   covers the happy path leaves the failure the log exists to prevent untested.
6. Add the register row in the same change — `hermetic`, `Breaker: yes`, this
   mission's slug — and confirm `drill-register.sh` reads it.
7. Write the breaker: a deliberately broken copy of the seam that the drill must
   fail against. Write it **against the behaviour** (a persist that writes to the
   base instead of the ref), never against a return shape.
8. Confirm the CI matrix picks the drill up as its own named leg.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-all` runs the new drill and it passes.
- The drill runs with no network, no `gh`, no credential — classified `hermetic`
  and measured as such, not asserted.
- The breaker fails the drill.
- The register carries its row and `drill-register.sh` reads it; the drill is not
  `skipped:unclassified` and not `unproved`.
- `loop-drills.yml` shows a matrix leg named after the drill.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-all`
- The drill run twice with `PATH` stripped of `gh` and no proxy, per the register's
  own measurement rule.
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The breaker was actually run and observed to fail the drill. A breaker row
  asserting a failure nobody watched happen is the gap the register exists to
  close.

## Considerations

- The drill's fixture needs a pushable remote without a credential — a local bare
  repository as `origin` is the standard shape here and keeps the drill hermetic.
- Ticket 8 is the mirror image (a tick log that reaches `main` again). Keep them
  separate drills so `drill-health` can name which property broke.

## Final Report

Development completed as planned, and the drill this ticket asks for **existed already and had
never once run**. `verify-log-branch` was written with the mission, registered `hermetic` with a
breaker, and carried in the hermetic matrix — but it looked for `log-ref.sh` and `ensure-log-ref.sh`
under `moderate/scripts`, where they have never lived. The ref is a fact about the **repository**,
so both are `gather/scripts`'; the drill therefore exited `log_branch_seam_unreadable` on every
invocation since it was written, and `verify-all` reported that as **`skipped`** rather than
`fail`. A skip is not a red check run, so the guard for the whole mission was absent from the very
set that exists to run it, silently.

The repair names the two directories separately (`_gth` for the ref's derivation, `_mod` for the
tick's own scripts) so a future move of either is visible rather than silent, and records why in
the drill's own header.

Positive proof, now actually executing: `log_reaches_its_branch` (the persist files the day file),
`log_day_file_on_the_branch` (it is really there — *the persist answered true* and *the file
exists* are different claims), and `hydrate_restores_the_memory` (a fresh clone of `main` gets the
log back), with `log_ref_is_not_the_base` under them and the breaker
`log_ref_may_not_be_the_base` proving the drill can fail.

### Discovered Insights

- **Insight**: A drill that exits its seam-check code reads as `skipped`, and `verify-all` exits
  zero over it — so a drill can be dead for its entire life without any surface going red.
  **Context**: This is the second failure mode of the drill set, distinct from a drill that fails:
  a `skipped:<reason>` naming a *path* rather than `needs_server` is a defect in the drill, not a
  classification. Worth reading `verify-all`'s skip list as a to-do rather than as a legend.
