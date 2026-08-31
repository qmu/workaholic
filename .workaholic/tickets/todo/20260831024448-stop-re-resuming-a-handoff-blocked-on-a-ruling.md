---
created_at: 2026-08-31T02:44:48+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-two-runs-from-claiming-and-driving-one-unit
merge_policy:
verification_handoff:
feedback: 20260830081659-stop-two-runs-from-claiming-and-driving-one-unit.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md
---

# Stop re-resuming a handoff blocked on a ruling

## Overview

**Minted mid-run, from an observed problem outside the three blocked tickets' scope.**

A unit that took the **half-driven handoff** route because its remaining work is blocked on an
**operator ruling** reads `parked_with_pr` at the claim oracle, `resumable: true`, and is offered
as a takeover by every later survey. The takeover can drive nothing — the ruling is the blocker,
and `/implement` may neither ask for it nor make it — so each run pushes one empty `Resume a
PR-unit` commit onto a branch whose pull request is already open and reports the unit blocked
again.

**Measured on this branch** (`work-20260830-124234`, PR #755, mission
`stop-two-runs-from-claiming-and-driving-one-unit`), six consecutive takeovers in thirteen hours:

```
eb9bcb6b 2026-08-31 02:42:11 +0000 Resume a PR-unit
bfdf18b6 2026-08-31 01:43:31 +0000 Resume a PR-unit
4c40bc4a 2026-08-30 19:43:44 +0000 Resume a PR-unit
cfd833df 2026-08-30 15:42:11 +0000 Resume a PR-unit
07e7a1b4 2026-08-30 14:43:08 +0000 Resume a PR-unit
36d94f95 2026-08-30 13:42:23 +0000 Resume a PR-unit
```

Zero lines of implementation across all six. The branch story's own Motivation already records
the first half of it — *"Three consecutive runs took this unit over and reported it blocked, each
citing the recorded measurement rather than making one"* — and the count has doubled since.

**This is the shape `awaiting_verification` was split off to remove**, one state over.
`claimed_awaiting_verification` (2026-08-27, mission `stop-re-resuming-a-declared-handoff-unit`)
covers a unit whose remaining queued work **declared** `verification_handoff:` at creation: the
oracle reads the declaration off the tip and stops offering the takeover. A half-driven handoff
blocked on a ruling has the identical cost profile and no declaration to read, so it falls through
to `parked_with_pr` and is re-offered forever.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/machine-checkable-domain-gaps.md` — make the gap fail early
- `workaholic:operation` / `policies/runtime-behavior.md` — the running loop keeps serving and recovering

## Key Files

- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — where `parked_with_pr` and
  `awaiting_verification` are derived; the declared-handoff read (`claims_declared_handoff`) is the
  precedent to follow, not to copy
- `plugins/workaholic/skills/drive/scripts/verification-handoff.sh` — the one reader of the
  declared field; it must stay the one reader
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — `resumable[]` and `excluded[]`
- `plugins/workaholic/skills/drive/scripts/claim.sh` — the `resume` refusal loop
- `plugins/workaholic/skills/drive/reference/claims.md` — *Proofs and judgements*; any new word is a
  **judgement** and must be classified there with its consumers enumerated
- `scripts/e2e/loop-drill.sh` — `verify-handoff-question` is the nearest existing drill

## Implementation Steps

1. Read `stop-re-resuming-a-declared-handoff-unit`'s repair end to end before choosing anything —
   what makes `awaiting_verification` safe is that the declaration is **on the artifact before the
   drive**, so a run can never write it for its own unit. Any reading proposed here must carry the
   same property or state plainly why it does not.
2. Decide the **signal**, and prefer one already on the tree over a new field. Candidates to weigh,
   with the argument for and against each named: the branch story's `## Handoff` section (present
   by construction on exactly this route, written by the run that handed off — but written by the
   run about its own unit, which is the property step 1 says must not be lost); a `blocked` stamp on
   the remaining queued tickets; a `## Open Decisions` item naming the ruling.
3. If, and only if, no existing signal carries the property, record that finding and stop — a new
   field on an artifact is what this repository refuses by name, and *reported and never acted on*
   is a legitimate ending.
4. Whatever the signal, the verdict is a **sibling word**, never a narrowed `parked_with_pr`: *take
   it over* and *rule on this* are different next actions, and one word answering both is what made
   this invisible for six ticks.
5. The unit must reach a person exactly once — `/moderate` already asks about the neighbouring
   verdicts, and one unit drawing two questions in two vocabularies is the doubling
   `handoff-units` and `stalled-units` were split to avoid.
6. **It releases itself.** Whatever is read must be read from the work still **queued** or from a
   section the next run rewrites, so that ruling on the blocker returns the unit to
   `parked_with_pr` with nothing stored anywhere.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A unit on the half-driven handoff route whose remaining work is blocked on an operator ruling is
  **not** offered as a takeover by `plan-units.sh`, and `claim.sh resume` refuses it by its own
  word rather than under `parked_with_pr`'s.
- An ordinary `parked_with_pr` unit — one with drivable follow-up tickets — is offered exactly as
  it is today; every other verdict is byte-identical.
- The reading is **offline** and stored nowhere: driving or unblocking the remaining work returns
  the unit to its previous verdict with no field cleared anywhere.
- The new word is classified a **judgement** in `claims.md` with its consumers enumerated, and no
  consumer merges, closes, releases a claim or lifts a gate on it.
- One question reaches the claim holder once; the unit draws no second question from
  `stalled-units`.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` passes, including the proofs-and-judgements pin.
- A drill row over a fixture in this shape shows the takeover withheld and the ordinary
  `parked_with_pr` unit still offered, with a `bearing: "breaker"` row that fails when the two are
  collapsed.
- `sh scripts/e2e/loop-drill.sh verify-all` shows no other drill's verdicts moving.

**Gate** — what must pass before approval:

- No field was added to any artifact, no verdict was widened, and the reading releases itself.

## Considerations

- **This is a finding, not a design.** The signal in step 2 is genuinely open, and the honest
  outcome may be step 3 — record that no existing signal carries the pre-drive property and leave
  the verdict alone. A run declaring its own unit un-resumable is exactly the soft landing
  `handoff` must never become.
- The cost of the status quo is bounded and visible (one empty commit an hour, no work lost, no
  gate overridden), so a repair that risks stranding a genuinely drivable `parked_with_pr` unit is
  worse than the defect.
- `superseded` keeps its precedence over any word added here.
