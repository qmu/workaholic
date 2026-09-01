---
type: Feedback
title: Finish the retirement the loop cannot complete
kind: instruction
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-27T23:19:16+00:00
author: a@qmu.jp
supersedes: 
---

# Finish the retirement the loop cannot complete

Source: https://github.com/qmu/workaholic/issues/667

The `[Propose]` routine opened this ask against the strategy
`an-autonomous-improvement-loop-run-by-the-routines` as a `depth` move.

## What to change

Make the retirement of a claim proved empty either **complete** or **reach a person with the one
act that is left** — never a generic partial that repeats forever.

`retire-claim.sh` landed on 2026-08-27 to stop the claim table only ever growing. It takes three
acts in order: close the pull request, delete the remote branch, reap the worktree. Measured on
this repository at tick `20260827-215209`, and on every tick since:

```
retire-claims: ok — 8 claimed unit(s); 4 proved superseded, 0 retired, 4 refused —
  batch-20260819063000 refused (partial_retirement);
  make-a-rename-a-registry-entry-not-a-sweep refused (partial_retirement);
  make-the-draft-release-note-an-agent-s-release-plan refused (partial_retirement);
  make-workaholify-converge-the-account-s-routines refused (not_superseded:awaiting_verification)
```

Checked directly against the transport for all three `partial_retirement` units
(`work-20260819-063001`, `work-20260821-035855`, `work-20260818-205051`): the pull request is
`closed` in every case and the remote branch is still `PRESENT` in every case. Act 1 succeeds,
Act 2 fails, Act 3 is a no-op. The script's own Act 2 comment already predicted it — "Measured
2026-08-05 on the hourly runner: a cloud container may PUSH but not DELETE a branch" — and named
it "not fatal" on the ground that the other two acts stand on their own. They do not stand on
their own for the purpose the mechanism exists to serve: **unmerged remote branches are the only
claim oracle**, so a branch that is never deleted is a claim that is never retired. The table
grows exactly as before, and the hourly tick re-attempts and re-fails the same three units
forever while reporting `0 retired`.

What must become true:

- The refusal is **diagnosed before it is coded against** — reproduce the delete in the container
  the loop actually runs in and record the exact refusal (status and message), rather than
  assuming the 2026-08-05 session-type reading still explains it. Branch protection and a missing
  scope produce the same visible symptom.
- A delete the transport refuses gets **its own reported word**, not `partial_retirement`. Each
  act's outcome already rides the row; what the caller reports must say *which* act is blocked, on
  the `session_type_cannot_merge` precedent that landed the same day.
- Where a second transport can take that one act, it is **retried under the same bounds that
  precedent set** — one named precondition, one act, the outcome reported either way. If no
  connector surface can delete a branch, that is recorded as the finding rather than worked
  around, and the mission lands on the reporting half alone.
- The blocked unit **reaches a person once**, addressed to the claim holder and naming the exact
  branches, on the `undelivered-units` / `handoff-units` precedent — a proof the loop cannot act on
  is the shape those two steps already exist for.
- The retirement reports **what stands and what is outstanding**, so a re-run is visibly a re-run
  of one remaining act and not of three, and so `0 retired` stops reading as a fresh hourly finding
  when it is a standing, already-asked condition.

Retiring the verdict, loosening the proof gate, or teaching the oracle to ignore a branch are all
out of scope: `superseded` stays a proof, the oracle keeps its single source of truth, and nothing
here merges, reverts or releases a claim.

## Experience

A claim the loop has proved empty stops accumulating. Either its branch is gone and the claim is
retired, or exactly one person has been told once, by name, which branches are waiting on them and
why the loop could not delete them — and the tick reports that unit as blocked-and-asked rather
than re-discovering it as a fresh failure every hour.

## Tickets named by the ask

1. Reproduce the refused branch delete and name the refusal (diagnosis only, no fix).
2. Give a refused delete its own reported word, splitting `partial_retirement`.
3. Retry the refused delete through a second transport, or record that none exists.
4. Report what stands and what is outstanding.
5. Ask the claim holder once for the branches the loop cannot delete.
6. Stop reporting a standing blocked retirement as a fresh hourly finding.
7. Drill the blocked retirement with no network.
8. Write the blocked retirement into the documents.
