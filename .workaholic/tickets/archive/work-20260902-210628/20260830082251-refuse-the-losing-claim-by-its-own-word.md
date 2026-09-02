---
created_at: 2026-08-30T08:22:51+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-two-runs-from-claiming-and-driving-one-unit
merge_policy:
verification_handoff: 
---

# Refuse the losing claim by its own word

## Overview

Ticket 3 makes the second claimant's push lose. This ticket makes it **lose cleanly**: a named
refusal, and **no branch, no worktree and no commit** left behind.

`claim.sh` already ends in an `abort_claim` for `branch_collision` and `push_failed`, and those are
the wrong words here — `branch_collision` means *two units minted one name in one second, retry*,
and `push_failed` means *the remote did not take it*. A lost race is neither: it is the protocol
working, and the runner should survey again rather than retry the same claim. It gets its **own
word**, on the precedent of `report_undelivered` beside `queue_drained` — one word answering two
next actions is what makes a state invisible.

The refusal is **re-derived at the moment of the act**: the losing push is the evidence, not a
handed-in reading.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/machine-checkable-domain-gaps.md` — make the gap fail early
- `workaholic:operation` / `policies/runtime-behavior.md` — the running loop keeps serving and recovering

## Key Files

- `plugins/workaholic/skills/drive/scripts/claim.sh` — §6's push classification and `abort_claim`'s teardown
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — must gain nothing; this word is the claim act's, not the oracle's
- `plugins/workaholic/skills/drive/reference/claims.md` — the refusal is documented beside `resume_race_lost`
- `plugins/workaholic/skills/drive/SKILL.md` — §3's claim step names the refusals a run may see
- `scripts/e2e/loop-drill.sh` — `verify-claim-race`

## Implementation Steps

1. Read `abort_claim`'s existing teardown before adding a path: it already exists for
   `commit_failed` and `push_failed`, and the question is whether it removes the worktree, the local
   branch and the claim commit in every order the loser can be in. Extend it rather than writing a
   second teardown.
2. Add the refusal word for a lost race — distinct from `branch_collision` and `push_failed` —
   emitted only when the contended ref's create was refused **because it already exists**, never for
   a generic transport failure. A transport failure stays `push_failed`: collapsing them would tell
   a runner the protocol worked when the remote was simply unreachable.
3. Report the **winner** in the refusal payload where the ref read gives it, so the survey and any
   later report can name both branches — ticket 7 needs that pair and must not re-derive it.
4. Assert the teardown: after the refusal, the runner holds no `.worktrees/<unit-id>/`, no local
   `work-*` branch, and no unpushed claim commit; nothing of the loser reaches origin.
5. Document it in `claims.md` beside `resume_race_lost`, whose shape it follows, and name it in
   `drive/SKILL.md` §3 as a refusal a run may see. It is the **claim act's** vocabulary, not the
   oracle's: `lib/claims.sh` emits nothing new and the proofs-and-judgements tables do not move.
6. Confirm the loser's next survey offers the unit as **claimed by the winner** — an ordinary
   `already_claimed` exclusion — rather than as free backlog.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A lost race refuses by its own word, distinct from `branch_collision` and `push_failed`.
- The loser holds no branch, no worktree and no commit, locally or on origin.
- The refusal names both branches where the ref read supplies the winner.
- `lib/claims.sh` emits no new word and the proofs-and-judgements tables are unchanged.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-claim-race` asserts the refusal word and the empty teardown.
- `sh scripts/e2e/loop-drill.sh verify-all` passes.
- `node scripts/test-workflow-scripts.mjs` passes (the tables' pin must stay green).

**Gate** — what must pass before approval:

- The loser wrote nothing, said which word it lost by, and the oracle's vocabulary did not grow.

## Considerations

- **A transport failure must never read as a lost race.** The distinguishing evidence is that the
  contended ref *exists*, not that the push failed; key on that and nothing else.
- The teardown is the risky half: a partial removal leaves a shadow worktree that
  `ensure-worktree.sh` will later refuse. Prove the empty state rather than asserting the refusal
  alone.

## Drive Findings — 2026-08-31 (blocked)

**Step 1's audit ran and found no gap; steps 2-6 are blocked upstream.**

*Step 1, the existing teardown — completed.* `abort_claim` (`claim.sh` §4) reverts this script's
own stamps by targeted path, then calls `cleanup-mission-worktree.sh`, which runs
`git worktree remove` and then `git branch -d || git branch -D`. So the worktree, the local
`work-*` branch and — with it — the claim commit all go, in every order the loser can be in, and
the pre-commit and post-commit call sites (`commit_failed`, `push_failed`) share that one path.
**There is no second teardown to write and no gap to extend**; a lost-race refusal would reuse
this path unchanged.

*Steps 2-6 — blocked.* The refusal word must be emitted "only when the contended ref's create was
refused **because it already exists**". No contended ref can exist: this container's transport
refuses ref creation everywhere except `refs/heads/*`, and refuses the delete there, so the
mechanism ticket `20260830082251-make-the-claim-contend-for-one-ref-per-unit.md` is blocked with
the full measurement (four `git push` probes and two REST calls, raw output recorded there).
Without that ref there is no losing push to name, and inventing a word for a condition nothing can
produce would put an unreachable refusal in `claims.md` — the opposite of this ticket's own point
that one word answering two next actions is what makes a state invisible.

Unblocked by: a ruling on that ticket's re-scope. Nothing here needs re-deriving — the teardown
audit above is the answer to step 1 and stands whatever the ruling.

## Final Report

Development completed as planned, and **the teardown step turned out to be unnecessary by
construction** — which is the better answer, not a skipped one.

- **`abort_claim` was read before anything was added** (step 1). It already handles
  `commit_failed` and `push_failed`, and what it does is unwind a worktree, its branch and this
  script's own stamps. The lost race never reaches it: §3b arbitrates **before** §4 creates the
  worktree, so the loser has no worktree, no local `work-*` branch and no commit to unwind.
  `abort_claim` gained one line — releasing the arbitration locks — for the *other* failures,
  which can happen after a lock is won.
- **`claim_race_lost` is its own word** (step 2), distinct from `branch_collision` (*two units
  minted one name in one second — retry*) and `push_failed` (*the remote did not take it*),
  because the next action differs: a lost race is the protocol **working**, and the runner should
  **survey again**. It is emitted **only** when the contended ref's create was refused because
  the ref exists — the arbiter classifies the push's own output, and a transport refusal answers
  `unavailable`, which is not a refusal at all.
- **The refusal names what it can and guesses nothing** (step 3): `held_by_ref`, the contended
  ref, and `stale_lock`, which says the oracle knew of no claim behind that lock. It does **not**
  name the winner's branch, because at that instant the winner has arbitrated and not yet pushed
  — the branch does not exist. `/moderate`'s `raced-units` names both once both exist, and that
  limit is written down rather than papered over.
- **The teardown is asserted** (step 4): after the refusal the loser holds no `.worktrees/<unit>/`,
  no local `work-*` branch, and nothing of it reached origin.
- **Documented beside `resume_race_lost`** in `claims.md` and named in `drive/SKILL.md` §3 as a
  refusal a run may see (step 5). `lib/claims.sh` emits nothing new and the proofs-and-judgements
  tables did not move — it is the **claim act's** vocabulary.
- **The loser's next survey sees an ordinary claim** (step 6), asserted: once the winner pushes,
  a second attempt refuses `already_claimed`. The arbitration hands the unit to the oracle; it
  does not replace it.

### Discovered Insights

- **Insight**: A hermetic test of a claim race must reproduce **the window**, not the sequence. A
  second `claim.sh` run after the winner has pushed is refused by the ORACLE
  (`already_claimed`) and never reaches the arbitration at all — the case that already worked.
  The race is the interval where the winner has arbitrated and not yet pushed, and the only way
  to hold a fixture there is to take the locks directly and then run a real claim against them.
  **Context**: The first version of this row asserted `claim_race_lost` against the sequential
  shape and failed for the right reason; a test that had passed there would have been measuring
  the old refusal.
