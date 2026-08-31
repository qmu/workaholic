---
created_at: 2026-08-31T20:29:34+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: read-the-base-s-colour-past-a-bookkeeping-tip
merge_policy:
verification_handoff: 
---

# Drill the base reading past a bookkeeping tip

## Overview

PROPOSED. The measured failure was silent for a full day and looked exactly like a healthy
quiet step, which is the property that makes it worth a drill rather than a test alone: a
regression here produces no output to notice. The drill turns it into a check run named after
the behaviour, which is what lets `/moderate`'s `drill-health` step name it.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — the dispatcher; `verify-all` derives its set from the `case`
  arms plus the register.
- `docs/loop-drill-runbook.md` §9 — the drill register, one table and one reader.
- `.github/workflows/loop-drills.yml` — one matrix leg per drill.
- `plugins/workaholic/skills/drive/scripts/drill-register.sh` — the register's one reader.

## Implementation Steps

1. Add one `verify-*` arm seeding a base with a `no_checks` tip over a checked ancestor, plus
   the two control cases: a checked tip, and a tip whose reading failed for our own reasons.
   Stub the check reader so the drill needs no credential and makes no network call.
2. Assert the **behaviour**: the bookkeeping tip yields a colour and its distance; the
   own-failure tip stays terminal and named; a walk that exhausts its bound says so rather
   than guessing.
3. Register it in `docs/loop-drill-runbook.md` §9 with a `bearing: "breaker"` row written
   against that behaviour — a drill with no breaker row is `unproved` and counted outside the
   passing total, and an unclassified drill fails the suite.
4. Add its matrix leg to `.github/workflows/loop-drills.yml`, hermetic: no credential, no
   permission beyond the default read.
5. Add the failure-reason to file blame row the runbook's tables carry.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-all` runs the new drill and reports it in the drill
  vocabulary (`pass` / `fail` / `skipped:<reason>`).
- Reverting the walk change turns the drill red; restoring it turns the drill green.
- The drill runs offline with no credential.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-all`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The register row is a breaker written against the behaviour, not against a return shape.

## Considerations

- Seeding check runs offline means stubbing the reader rather than calling GitHub. Say so in
  the runbook row: the drill proves the **walk**, not that any real repository's CI reports
  check runs, and the reader's own limit (check runs only, never legacy commit statuses) is
  untouched by this mission and stays stated where it already is.
- Reuse whatever seeder the first ticket's reproduction built rather than writing a second one.

## Final Report

Development completed as planned.

**The seeder was reused by extracting it, not by copying it.** The first ticket's reproduction
lived in `scripts/test-workflow-scripts.mjs`, which cannot seed a drill; what already existed
was `verify-base-health`'s inline seeder, building exactly the ground this drill needs — a
local bare origin, five commits on `main`, a clone to read from, and a `gh` stub answering per
commit out of a fixture directory. It is now `base_checks_seed`, called by both drills. A
second copy would have been two fixtures that drift, with each drill asserting on shas from
whichever one it happened to build. `verify-base-health` is byte-identical in behaviour after
the extraction (14 load-bearing rows, 1 breaker, `pass`).

**`verify-bookkeeping-tip`** seeds a base with a `no_checks` tip over a checked ancestor and
carries both controls the ticket named: a checked tip, which must read exactly as it did before
the coordinates existed, and a tip whose reading failed for our own reasons — `unparseable_response`
and `checks_pending`, each of which must stay terminal and named. Eight load-bearing rows plus
the breaker: the transport is the stub (asserted, not assumed), the bookkeeping tip yields a
colour and its distance, the attribution is the one a red tip would have produced, a checked tip
is unchanged, an own-failure tip is terminal, the bound says what stopped it and claims no red it
never saw, the step carries the distance to both its audiences while a green base read back stays
silent, and the checkout is byte-identical afterwards.

**The breaker is written against the behaviour.** It removes the continuation from a copy of the
walk — `no_checks) ;;` renamed so neither arm matches, which is the collapse exactly as it was
measured — and requires the bookkeeping-tip case to then produce no colour at all.

**Both directions were measured, not asserted.** With the continuation reverted in the real
checkout the drill exits non-zero with four named load-bearing failures (`yields_a_colour`,
`attribution_unchanged`, `bound_says_so`, `step_says_how_far_back`), each printing the
`tip_no_checks` reading that is the defect; restoring it turns the drill green. The whole
classified set runs clean: `verify-all` → `ok: true`, 41 drills, 0 failed.

**No matrix leg was written by hand, and that is correct rather than a gap.** The workflow
derives its matrix from `verify-all --list --kind hermetic`, which reads the dispatcher's own
`case` arms plus the register — a list in the workflow file would be the second hand-kept
enumeration that derivation exists to remove. The new drill appears in the hermetic set (33
legs) and `drill-register.sh drill verify-bookkeeping-tip` resolves it to this mission, which is
what lets `/moderate`'s `drill-health` step name it.

### Discovered Insights

- **Insight**: This drill's subject is a failure that produced **no output**, which is a
  different thing from a failure that produced wrong output — and it is what decides drill
  versus test row.
  **Context**: A step that cannot read reports `degraded` and asks nobody, which from the
  channel is indistinguishable from a healthy quiet step. Nothing goes red and nothing is
  missing, so the regression is invisible until somebody goes looking for a reading they had
  stopped expecting. A check run named after the behaviour is the only surface that would have
  said anything.

- **Insight**: The drill's controls are worth more than its positive rows here, because the
  change is a **narrowing** of a refusal rather than a new capability.
  **Context**: Anything can be made to walk past an unreadable tip; the whole correctness of
  the change is that it walks past exactly one reason. The two control rows are what would
  catch a later "simplification" that continued past `checks_pending` — which would report an
  older commit's colour as though it were current, the failure the three-valued reader exists
  to prevent.
