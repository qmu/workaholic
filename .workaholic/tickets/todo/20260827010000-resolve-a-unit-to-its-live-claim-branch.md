---
created_at: 2026-08-27T01:00:00+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy:
verification_handoff: 
claim: work-20260827-014149
---

# Resolve a unit to its live claim branch

## Overview

MINTED MID-RUN (2026-08-27, by the `/implement` run that landed
`let-a-fresh-claim-take-a-superseded-claim-s-work`). A unit can now legitimately be held by
**two** claim branches — a `superseded` one the survey ignores, and a live one a fresh claim
created beside it. Three scripts resolve a unit to *a* branch and all three take the first
match, which is the **older, superseded** one. The live claim is then reachable by nothing.

Reproduced on this repository at 2026-08-27T00:55Z, on unit
`make-workaholify-converge-the-account-s-routines`, held by `work-20260819-113836`
(`superseded`) and `work-20260827-003544` (`claim_active`):

- `claim.sh resume <unit>` → `{"reason": "superseded", "branch": "work-20260819-113836"}` —
  it resolved to the branch that holds nothing and refused on that branch's verdict, so the
  live claim cannot be resumed.
- `release-claim.sh <unit>` → `{"branch": "work-20260819-113836", "worktree_removed": true}`
  — it released the wrong branch and reported `half_released`, leaving the live claim standing.
- `ensure-worktree.sh work-20260827-003544` → created a **new local branch at `main`'s tip**
  rather than checking out the existing remote claim branch
  (`HEAD 76761cde` vs `origin/work-20260827-003544 79d1c7e2`). Pushing from that worktree
  would have silently clobbered the claim.

The two-branch shape is **new**, which is why nothing was wrong before: until a fresh claim
could be taken over a superseded one, a unit had exactly one branch and first-match was
always right.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/claim.sh` — the `resume` path's unit→branch lookup.
- `plugins/workaholic/skills/drive/scripts/release-claim.sh` — the same lookup, second copy.
- `plugins/workaholic/skills/branching/scripts/ensure-worktree.sh` — read its header whole:
  its contract is *ensure a worktree for this branch*, and whether it may create a branch that
  does not exist locally is the question this ticket has to answer, not assume.
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — where a unit's rows are derived;
  the fix belongs here, once, not in each caller.

## Implementation Steps

1. Reproduce all three with the commands above against a fixture holding two claim branches
   for one unit. The shape is what `makeSquashMergedClaims` already builds plus one fresh
   claim over the superseded one.
2. Resolve a unit to its **live** claim branch — the row whose verdict is not `superseded` —
   in `lib/claims.sh`, and have both `claim.sh resume` and `release-claim.sh` read that. One
   derivation, not three: three copies of a lookup is how these three disagreed.
3. Decide explicitly what a unit with **two live** claims means (a race the protocol says is
   settled by the push) and report it rather than picking one silently.
4. `ensure-worktree.sh` must not create a **local** branch that shadows an existing remote one
   of the same name. Either check the remote out, or refuse by name — but never diverge
   silently, because the next push from that worktree overwrites a claim.
5. State the resolution rule in `reference/claims.md` beside the `superseded` verdict, since
   the two-branch shape is what that verdict made possible.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- With a superseded and a live claim on one unit, `claim.sh resume` reaches the **live** branch.
- `release-claim.sh` releases the **live** branch, never the superseded one.
- `ensure-worktree.sh` on a branch that exists on the remote checks that branch out, or
  refuses by name; it never creates a diverging local branch of the same name.
- A unit with exactly one claim behaves byte-identically to today.
- The resolution is derived in one place, and each caller reads it.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — a case per criterion over the two-branch fixture,
  including the single-claim byte-identity case.
- `sh scripts/e2e/loop-drill.sh verify-merged-claim` — still passes, unchanged.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes.
- A fixture asserting that no caller can reach the superseded branch when a live one exists.

## Considerations

- **The `ensure-worktree.sh` half is the dangerous one** and is worth fixing even if the
  other two are deferred: a silently diverging local branch turns the next push into a
  claim-clobbering force-of-fact. It was caught here only because the run compared
  `HEAD` against `origin/<branch>` before pushing.
- The live claim `work-20260827-003544` on
  `make-workaholify-converge-the-account-s-routines` is real and currently unreachable, so
  that mission is claimable-but-undrivable until this lands or an operator removes the branch.
  This session cannot delete a remote branch (`git push --delete` is refused by the session
  type), which is why it is recorded here rather than tidied away.
