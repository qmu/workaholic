---
created_at: 2026-08-31T20:34:54+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: prove-a-claim-branch-is-empty-before-deleting-it
merge_policy:
verification_handoff: 
---

# Drill the stranded-branch refusal offline

## Overview

PROPOSED. This is the one mechanism in the loop whose regression destroys work rather than
delaying it, and the ask says exactly why a drill is owed: the 403 blocking the delete has been
keeping the measured branches alive by accident, so the day the transport is repaired is the
day a regression here becomes silent loss. The drill is what makes that regression a named red
check run instead.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — the dispatcher; `verify-all` derives its set from the `case`
  arms plus the register.
- `docs/loop-drill-runbook.md` §9 — the drill register, one table and one reader.
- `.github/workflows/loop-drills.yml` — one matrix leg per drill, so the red check run is named
  after the drill and `/moderate`'s `drill-health` step can name it.
- `plugins/workaholic/skills/drive/scripts/drill-register.sh` — the register's one reader.

## Implementation Steps

1. Add one `verify-*` arm over the first ticket's reproduction, seeding all three cases: a
   branch empty against the base, a branch holding a file that is on no other ref, and a branch
   whose diff cannot be read.
2. Assert the **behaviour**, with the delete allowed to actually run in the sandbox: the empty
   branch is deleted; the branch holding work is refused and its files named; the unreadable one
   is refused. Assert at both grains, and assert that the file which would have been lost still
   exists afterwards — that is the property, and asserting a return word instead would pass over
   a delete that happened anyway.
3. Register it in `docs/loop-drill-runbook.md` §9 with a `bearing: "breaker"` row written
   against that behaviour.
4. Add its matrix leg to `.github/workflows/loop-drills.yml`, hermetic: no credential, no
   permission beyond the default read, no network.
5. Add the failure-reason to file blame row the runbook's tables carry.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-all` runs the new drill and reports it in the drill
  vocabulary (`pass` / `fail` / `skipped:<reason>`).
- Reverting the diff term turns the drill red; restoring it turns it green.
- The drill asserts surviving content, not a return word.
- The drill runs offline with no credential.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-all`
- `node scripts/test-workflow-scripts.mjs` — which fails on a drill the register does not
  classify.

**Gate** — what must pass before approval:

- The register row is a breaker written against the behaviour, not against a return shape.
- The drill deletes only inside its own throwaway repository.

## Considerations

- The drill proves the refusal, not the transport. It cannot show that the production 403 is
  gone or that a real delete behaves identically; say so in the runbook row rather than implying
  wider coverage.
- Reuse the first ticket's seeder rather than writing a second one, and keep the sandbox's
  cleanup unconditional — a drill that leaves throwaway repositories behind on failure is how a
  container runs out of disk.

## Final Report

Development completed as planned. `verify-stranded-branch` runs offline, asserts the property
rather than a return shape, and is proved able to fail.

`scripts/e2e/loop-drill.sh` gains the arm and its dispatcher case. It reuses
`seed_stranded_claims` — the reproduction's own seeder, not a second one — whose `gh` stub's ref
DELETE really removes the ref from the bare origin, so the destructive act happens for real.
Eight rows: the stub is what `gh` resolves to; the fixture reads `stranded` at both grains and
`superseded` on the branch that holds nothing; only the empty branch is offered as retirable; a
diff this clone cannot read answers `unanswerable` and the proof answers `false` over it; the
step asks per unit and names the files; the sibling filters and counts; the checkout is
byte-identical; and the **breaker** asserts that after the deletes both files reachable from no
other ref are still there **and** the branch that held nothing was retired.

**Proved able to fail, and the way it was proved changed the drill.** Neutering
`claims_branch_diff_reading` to answer `empty` first turned only the fixture row red, because
the arm hard-stopped there like its siblings do — so the breaker never measured what the
regression costs. The fixture row no longer hard-stops: the wrongness a wrong fixture shows here
*is* the regression, the deletes then run for real, and the breaker reports the loss. With the
term neutered the run reports `verdict: fail` with `stranded_content_survives_the_delete` red;
restoring it returns `verdict: pass, breakers: 1`.

**The register row** is `docs/loop-drill-runbook.md` §9, `hermetic` / breaker `yes` /
`prove-a-claim-branch-is-empty-before-deleting-it`, written against the behaviour — *work was
lost* — rather than a return shape. **No edit to `.github/workflows/loop-drills.yml` was needed
or wanted**: that workflow's matrix is derived from `verify-all --list --kind hermetic`, and its
own header says a list there would be the second hand-kept enumeration the mission that built it
exists to remove. Registering the drill as `hermetic` adds its leg, confirmed by the verb now
listing 33 hermetic drills including this one.

**§5l-quinquies of the runbook** carries the operator section and the row-to-file blame table,
and says in words what the drill does *not* prove: the refusal, not the transport. It cannot
show that the production 403 is gone or that a real GitHub delete behaves identically.

### Discovered Insights

- **Insight**: a drill that hard-stops on its fixture cannot drill a regression that *is* a
  wrong fixture.
  **Context**: every claim drill here bails out when its fixture does not read the shape under
  test, which is right when the fixture is scaffolding. Here the fixture's own reading is the
  subject — a branch reading `superseded` while it still holds work — so the bail-out fired
  first and the breaker was never reached. The rule that falls out: a drill whose breaker
  measures a *consequence* must let the run continue to the consequence.
- **Insight**: the deliberately broken seam has to be chosen against the code path, not against
  the name.
  **Context**: neutering `claims_branch_diff_empty` changed nothing, because `claims_delivery`
  reads `claims_branch_diff_reading`'s state directly and the one-word helper is only what
  `claims_superseded` composes. A breaker proved against the wrong seam is a breaker that has
  not been proved at all — which is the whole reason this repository requires the proof rather
  than the claim.
