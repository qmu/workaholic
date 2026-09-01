---
created_at: 2026-08-29T06:20:39+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: land-the-loop-s-own-work-when-the-base-moves-under-it
merge_policy:
verification_handoff: 
---

# Reproduce the base drift that strands a unit

## Overview

PROPOSED. The failing test the rest of the mission turns green. Nothing in the
loop looks at a claim branch's mergeability after its pull request opens, so a unit
finished and refused its merge is stranded the moment the base moves. Measured
2026-08-29: pull requests #622, #625, #633 and #688 conflicting with `main`, three of
them units already recorded `report_undelivered` on 2026-08-27, with 4 active missions
and 10 queued tickets behind them.

Diagnosis first: this ticket reproduces and localizes before anything is written. The
ask's own reading — that `retry-undelivered.sh` is the wrong act for a moved base — is
a hypothesis this fixture confirms or refutes, not a design to build from.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — every outcome reported by its own name

## Key Files

- `scripts/test-workflow-scripts.mjs` — where the hermetic fixture lands; it already
  builds throwaway repositories under the OS temp dir and never calls `gh` or the network.
- `plugins/workaholic/skills/drive/scripts/retry-undelivered.sh` — the seam under test;
  its verdict gate and `scan_held` refusal are what the fixture drives.
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — the oracle the fixture must
  make answer `report_undelivered` (a story at the tip carrying a recorded merge outcome).
- `plugins/workaholic/skills/story/scripts/record-merge-outcome.sh` — the one writer of
  that recorded outcome; the fixture uses it rather than hand-writing the section.

## Implementation Steps

1. **Reproduce.** Build a git-backed fixture over a bare local origin: a `work-*`
   claim branch with its tickets archived, a branch story carrying a recorded merge
   refusal, an open pull request (stubbed transport), and a base advanced to a state
   that conflicts with that branch. No network.
2. **Localize.** Assert the oracle reads `report_undelivered` on that branch — the
   proof `retry-undelivered.sh` acts on — so the fixture is exercising the real verdict
   chain rather than a shape that merely resembles it.
3. **Pin the failure.** Assert `retry-undelivered.sh` attempts the merge and is refused,
   every time it is run, and that its refusal word is about the merge rather than about
   the branch being behind — the distinction the whole mission rests on.
4. **Pin the absence.** Assert that no script under `skills/` catches the branch up:
   walk the driving chain and the tick's steps and prove none of them reaches
   `ship/scripts/catchup-main.sh` for a branch in this state.
5. Leave the fixture reusable by the later tickets rather than private to this one.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The fixture builds, runs and tears down with no network and no `gh`.
- The oracle answers `report_undelivered` on the fixture's claim branch.
- `retry-undelivered.sh` is refused on it, repeatably, and the refusal is named.
- No path in the loop catches the branch up — proved by walking the chain, not asserted.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The new fixture fails against today's tree for the right reason, and its failure
  message names the stranding rather than a missing function.

## Considerations

The tempting shortcut is to assert the symptom (a conflicted pull request) rather than
the mechanism. The mechanism is what the later tickets change, so the fixture must key on
the verdict and the absent catch-up.

## Final Report

Development completed as planned. `scripts/test-workflow-scripts.mjs` gained
`makeDriftFixture` / `strandUnit` / `advanceBase` / `driftGhStub` and the test
`drive: the base moves under a finished unit and nothing catches it up`. The fixture is a
bare local origin plus one clone, with the transport stubbed and no network.

The hypothesis the ask carried is **confirmed**: `retry-undelivered.sh` attempts the merge,
is refused `merge_not_allowed`, and is refused identically every time it is run.
`merge-reason.sh` has no word for *the branch is behind* at all, which is the distinction the
rest of the mission rests on.

The absence is pinned as a **closed set** rather than as "nothing reaches it": exactly two
scripts under `skills/` reach `ship/scripts/catchup-main.sh`. It read `land-unit.sh` alone
against the tree this mission started from, and `land-unit.sh` refuses `headless_context`
first and unoverridably — asserted here too, so the reason the loop had no caller is stated
rather than implied. The set assertion stays meaningful now that `catch-up-claim.sh` exists
and still fails the moment a third path grows one.

### Discovered Insights

- **Insight**: A set assertion outlives the red-to-green transition where a bare absence
  assertion cannot.
  **Context**: "No script reaches X" has to be deleted the moment X gains a caller, which
  loses the guard. "Exactly these scripts reach X" survives the change and keeps catching the
  thing that actually matters — an unreviewed third caller of a merge seam.
- **Insight**: The retry's own recording moves the branch tip, so a second run reads
  `claim_active` and says nothing about the merge.
  **Context**: This is why the fixture needed `--own-tip` to assert repeatability, and it is
  the same collision that later blocked the delivery after a catch-up.
