---
created_at: 2026-08-27T00:45:00+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy:
verification_handoff: 
claim: work-20260827-003503
---

# Let a fresh claim take a superseded claim's work

## Overview

MINTED MID-RUN (2026-08-27, by an `/implement` run of mission
`drive-the-work-the-loop-wrote-one-resolution-of-who-a-person-is`). The 2026-08-26
`superseded` change delivered half of its own stated intent. `plan-units.sh` **does**
resurvey the mission and tickets behind a superseded claim — its `resurveyed[]` field names
them, and `workaholic:drive` §1 says in as many words *a fresh claim drives them, because the
old branch cannot land*. But `claim.sh` still refuses the fresh claim, so the work it re-offers
is reachable by no path at all.

Reproduced on this repository at 2026-08-27T00:40Z, on a current, non-shallow survey:

- `plan-units.sh` offers `missions: ['make-workaholify-converge-the-account-s-routines']` and
  names it in `resurveyed: [{kind: mission, id: …, claim: work-20260819-113836}]`.
- `list-claims.sh` reads that branch `resume_reason: superseded`, `resumable: false`.
- `claim.sh mission make-workaholify-converge-the-account-s-routines` answers
  `{"claimed": false, "reason": "already_claimed", "holder_branch": "work-20260819-113836"}`.
- `claim.sh resume <unit>` answers `superseded` — correctly, and by design.

So the survey offers a unit, both claim paths refuse it, and the run must report it claimable
and end `pending`. It is the exact shape `report_incomplete` was added to remove in 2026-08-19,
one layer up: a unit reachable by no path is worse than one nothing offers, because it also
forbids `ok` on every later tick.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/claim.sh` — the `already_claimed` refusal; read its
  header whole first, especially why a claim refusal is deliberately conservative.
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — where `claims_superseded` is
  derived; the reading already exists and this ticket adds no second derivation of it.
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — `resurveyed[]`, the half that
  shipped; its header states why the field is top-level rather than an `excluded[]` entry.
- `plugins/workaholic/skills/drive/SKILL.md` §1 and §3, and `reference/claims.md` — where the
  fresh-claim sentence is written and where the refusal vocabulary lives.

## Implementation Steps

1. Reproduce first, with the three commands above, and record the outputs. The defect is that
   two readers of one signal disagree; confirm they still do before changing either.
2. Let `claim.sh` mint a **fresh** claim for a unit whose only holder is a `superseded` claim,
   reading that verdict through the existing `lib/claims.sh` derivation — never a second one.
   The new branch is an ordinary `work-*` claim; the old branch is untouched.
3. **Do not delete, close or release the old claim.** `superseded` has been *reported, never
   acted on* since it shipped, for the reason its own record gives: nothing here deletes a
   branch or closes a pull request. This ticket frees the *work*, not the branch.
4. Keep every other refusal exactly where it is. A live claim, a colleague's claim, a
   `queue_drained` one and a `report_incomplete` one are all unchanged — only a claim already
   **proved** to hold nothing may be claimed over, which is what bounds the change.
5. State the answer in `SKILL.md` §3's refusal list and in `reference/claims.md`, so the
   sentence in §1 and the behaviour agree.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A unit whose only claim reads `superseded` can be claimed fresh, on a new `work-*` branch.
- The superseded branch is not deleted, closed, or released by that claim.
- A unit held by a **live** claim still refuses `already_claimed`.
- A colleague's claim still refuses, at any age.
- `queue_drained` and `report_incomplete` claims behave exactly as they do today.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — a hermetic case per criterion over the
  squash-merged fixture `verify-merged-claim` already builds.
- `sh scripts/e2e/loop-drill.sh verify-merged-claim` — still passes, unchanged.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes.
- A fixture proving that the survey's offer and the claim's answer agree for all five claim
  readings, so the two cannot drift apart again.

## Considerations

- **The conservative direction is not obviously the safe one here.** A claim refusal usually
  protects work in flight; this one protects a branch already proved to hold none, at the cost
  of stranding the work behind it *and* forbidding `ok` forever. The bound that makes claiming
  over it safe is the same one `resurveyed[]` already relies on: every one of the unit's
  tickets is archived on the base, or a merged pull request has that branch as its head.
- The two readings must be derived in **one** place. Deciding "is this claim superseded"
  separately in the survey and in the claim writer is how they came to disagree in the first
  place.

## Final Report

Development completed as planned.

**Reproduced first.** The three commands in the Overview were run against the live repository
and disagreed exactly as recorded: `plan-units.sh` offered
`make-workaholify-converge-the-account-s-routines` and named it in `resurveyed[]`;
`list-claims.sh` read its only holder `work-20260819-113836` as `superseded`,
`resumable: false`; `claim.sh mission <slug>` answered `already_claimed` naming that branch;
`claim.sh resume <unit>` answered `superseded`.

The refusal loop in `claim.sh` §3 already had the verdict in hand — `_held_reason` is one of
the fields it reads off each `claims_scan` row — and threw it away. It now skips a row whose
verdict is `superseded`, before both the unit-id check and the artifact-overlap check, so the
reading is taken from `lib/claims.sh` and never re-derived: the survey's offer and this
refusal read one derivation and cannot disagree again.

**It frees the work, not the branch.** `superseded` stays *reported, never acted on*: the old
branch is not deleted, its pull request is not closed, its claim is not released, and the new
claim is an ordinary `work-*` branch beside it. Every other refusal is where it was — a live
claim (by unit id and by artifact overlap), a colleague's claim, `queue_drained` and
`report_incomplete` all refuse exactly as before, which is what bounds the change to a claim
already **proved** to hold nothing.

### Discovered Insights

- **Insight**: verifying a claim-writer change against the live repository *creates a real
  claim*. Doing so left `work-20260827-003544` standing on the mission under test, and
  `release-claim.sh` resolved the unit to the older branch rather than the new one, so the
  accidental claim outlived the check.
  **Context**: a writer's happy path is not safely testable in place. The hermetic fixture
  (`makeSquashMergedClaims`) already builds exactly this shape and costs nothing to extend;
  the live check should have been the reproduction only, never the verification.

- **Insight**: `fx.A` and `fx.B` in that fixture are two clones and the squash merges land in
  `fx.B`, so any test queueing new work in `fx.A` has to bring it onto the base first.
  **Context**: the push is rejected non-fast-forward, which reads as a fixture bug rather than
  the missing `git merge --ff-only origin/main` it actually is.
