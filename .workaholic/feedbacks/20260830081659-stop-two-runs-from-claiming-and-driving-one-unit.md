---
type: Feedback
title: Stop two runs from claiming and driving one unit
kind: instruction
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-30T08:16:59+00:00
author: a@qmu.jp
supersedes: 
---

# Stop two runs from claiming and driving one unit

Source: https://github.com/qmu/workaholic/issues/750

The `[Propose]` routine reports that two runs claimed and drove one unit on 2026-08-30,
and that the loser is unreachable by every path the claim protocol has.

Measured on this repository:

- `work-20260830-055314` (session `cse_01SAqzRAdEBRBJ8JjSERSk76`) and `work-20260830-055318`
  (session `cse_01YBzYYCQtrWa5ZTzWJLXPqF`) were both claimed for the unit
  `draft-a-dateless-direction-with-the-operator-s-one-week-default`, four seconds apart.
- Each session then implemented the same four tickets independently for over an hour.
- `...055318` merged at 06:42 UTC. `...055314` opened PR #749 at 07:08, its merge was
  refused, and the branch now reads `mergeability: content` — colliding with the archive
  of the very tickets it duplicated.

Three things the ask asks to become true:

1. **The push must actually settle the race.** `drive/reference/claims.md` states that
   the protocol settles a race by the push, so the state cannot arise from the sanctioned
   path. That premise is false as written: a claim is a `Claim <unit-id>` commit on a
   branch named after the clock, so two runners that survey before either pushes contend
   for nothing — both pushes succeed, on different refs. The claim must contend for one
   ref per unit, so the second claimant is refused by the server and the loser holds no
   branch, no worktree and no commits.
2. **A raced loser must be readable as `superseded`.** `...055314` reads
   `report_undelivered` even though all four of its tickets are archived on the base. At
   the mission grain `superseded` is answered by `claim-merged.sh`, which asks only
   whether a merged pull request has this branch as its head, so a unit whose content
   landed through its racing twin is invisible to the proof — and therefore to
   `retire-claim.sh` and to CI's retirement turn.
3. **A lost race must be said out loud.** No run report, no `/moderate` step and no claim
   verdict names *this unit was driven twice*.

Experience asked for: a runner that loses a claim race stops within its survey, having
written nothing. A unit whose content reached the base through another branch reads
`superseded` at either grain. When a race does happen, exactly one person is told once,
with both branches named.

The ask names an ordered eight-ticket plan and declares the move `contraction` against
the strategy `an-autonomous-improvement-loop-run-by-the-routines`.
