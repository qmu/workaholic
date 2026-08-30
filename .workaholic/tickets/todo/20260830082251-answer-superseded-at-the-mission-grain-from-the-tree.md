---
created_at: 2026-08-30T08:22:51+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-two-runs-from-claiming-and-driving-one-unit
merge_policy:
verification_handoff: 
---

# Answer superseded at the mission grain from the tree

## Overview

**The tree holds the answer and the mission grain never asks it.** `claims_superseded` answers
from the archive for a **batch** claim — every one of the unit's tickets archived on the base, under
*any* branch directory, because which branch delivered them is exactly what the test must not care
about. For a **mission** claim it never reaches that test: the artifact is `mission.md`, which
driving never archives, so the loop hands the question straight to `claim-merged.sh`, which asks
only whether a merged pull request has **this** branch as its head.

A unit whose content landed through a racing twin therefore reads `not_merged` → `false`, so it is
not `superseded`, so `retire-claim.sh` refuses it, so CI's retirement turn finds no candidate, and
`catch-up-claim.sh` correctly refuses to resolve a collision between a unit and itself. **Measured
2026-08-30**: all four of `work-20260830-055314`'s tickets are archived on the base under
`work-20260830-055318/`, and the claim still reads `report_undelivered`.

The local test must answer at the mission grain too — **from the tree, first and network-free**,
exactly as it already does for a batch — with the merged-pull-request lookup kept as the fallback it
is today.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/machine-checkable-domain-gaps.md` — make the gap fail early
- `workaholic:operation` / `policies/runtime-behavior.md` — the running loop keeps serving and recovering

## Key Files

- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — `claims_superseded`'s non-ticket branch, which returns to `claims_merged_state` unconditionally
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — `claims_remaining_tickets`, the existing walk of a unit's tickets
- `plugins/workaholic/skills/drive/scripts/claim-merged.sh` — the network fallback, unchanged
- `plugins/workaholic/skills/mission/scripts/read-relation.sh` — the ONE parser of the many-valued `mission:` relation
- `plugins/workaholic/skills/drive/reference/claims.md` — `superseded`'s definition and its both-grains paragraph

## Implementation Steps

1. Read `claims_superseded` end to end, including the long comment on its non-ticket branch: it
   records that the local test was refused at this grain in 2026-08-26 because it would need *a
   second parser of the many-valued `mission:` relation*, and that reason must be answered rather
   than ignored — the answer is to compose the **existing** single reader, never to parse the
   relation again.
2. For a mission claim, derive the unit's ticket set through the walk the oracle already makes
   (`claims_remaining_tickets` and the relation's own reader), then apply the **same** archived-on-
   the-base test the batch grain uses: every one of the unit's tickets present under any
   `tickets/archive/<branch>/` directory.
3. Keep the test **`every`, not `any`** — a unit half of whose tickets landed elsewhere still has
   work, and calling it superseded hides that half. This is the batch grain's existing rule and it
   does not move.
4. Keep the local test **first and network-free**, with `claim-merged.sh` as the fallback for a
   mission claim the tree cannot answer for (a mission with no archived tickets yet). An
   `unanswerable` lookup still answers `false`, unchanged.
5. Leave the verdict's standing alone: `superseded` stays a **proof**, its precedence after
   `claim_active` is untouched, and no consumer gains a new act. What changes is only that the
   proof is now reachable at both grains from the tree.
6. Confirm `retire-claim.sh`, `list-retirable-claims.sh` and CI's turn reach the raced loser with no
   change of their own — that is the point of repairing the reading rather than the consumers.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A mission claim all of whose tickets are archived on the base reads `superseded`, network-free.
- A mission claim with tickets still queued does **not** read `superseded`.
- The `mission:` relation still has exactly one parser.
- `claim-merged.sh` is unchanged and still answers the case the tree cannot; `unanswerable` still answers `false`.
- `superseded`'s classification, precedence and consumer set are unchanged.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-claim-race` asserts the raced loser reads `superseded`.
- `sh scripts/e2e/loop-drill.sh verify-merged-claim` and `verify-retire` still pass (both grains, unchanged).
- `sh scripts/e2e/loop-drill.sh verify-all` passes.
- `node scripts/test-workflow-scripts.mjs` passes.

**Gate** — what must pass before approval:

- The reading is repaired and every consumer of `superseded` reaches the raced loser unchanged.

## Considerations

- **This is the most dangerous ticket in the mission.** `superseded` is a proof that `retire-claim.sh`
  acts on destructively; a reading that is too eager retires a live claim. The `every`-not-`any` rule
  and the unchanged precedence after `claim_active` are what bound it, and both must be asserted.
- The 2026-08-26 refusal was about a second parser, not about the question being wrong. Composing the
  existing reader answers it; writing a new one re-opens it.
- `verify-retire` and `verify-merged-claim` are the drills most likely to move. If either changes,
  that is a finding to state, not a fixture to adjust.
