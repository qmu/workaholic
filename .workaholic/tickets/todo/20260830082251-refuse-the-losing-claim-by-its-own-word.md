---
created_at: 2026-08-30T08:22:51+00:00
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
