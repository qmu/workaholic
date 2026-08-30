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

## Final Report

Development completed as planned. `claims_superseded`'s non-ticket branch now asks the **tree
first** at the mission grain, through `claims_mission_landed`: the unit's ticket set is read off
the claim's own **tip** — queued and archived alike, so which side of the rename a ticket sits on
does not matter — and put to the **same** archived-on-the-base test the batch grain already
applies, matched by filename under any branch directory. `every`, never `any`, is preserved
verbatim from the batch grain.

The 2026-08-26 refusal is **answered rather than ignored**. It refused this test because it "would
need a second parser of a many-valued relation for a shape nothing has measured". The shape is now
measured, and the relation is still walked exactly once: `claims_remaining_tickets`'s mission walk
was **lifted out** into `claims_tickets_for_mission` and both readings compose it, so nothing reads
`mission:` on its own. The archived-on-base test itself was likewise lifted into
`claims_archived_on_base` / `claims_is_archived` and is shared by both grains rather than copied.

The local test is **first and network-free**, and `claim-merged.sh` stays the fallback for every
case the tree does not answer `true` — an absent tip ref, a mission with no tickets written yet, a
mission still holding queued work. That direction is deliberate and is the safety property: this
change can only ever **add** a `superseded`, never take one away, which is what matters when a
proof gates a destructive act. `claim-merged.sh` is byte-identical and an `unanswerable` lookup
still answers `false`.

The tip ref is a new **optional fourth argument** to `claims_superseded`, absent-means-unchanged,
so every caller that does not pass it behaves byte-for-byte as before. Two callers pass it:
`claims_scan` and `delete-retired-claim-branch.sh` — the CI-side re-derivation, so the two
executors keep agreeing about a proved-empty claim.

Verified on the live case the mission was written from: `work-20260830-055314`, the raced loser for
`draft-a-dateless-direction-with-the-operator-s-one-week-default`, read `report_undelivered` before
and reads `superseded` after, with all four of its tickets archived on the base under the twin's
`work-20260830-055318/`. Every other claim on the repository is unchanged. Step 6 confirmed:
`list-retirable-claims.sh` names the unit with no change of its own, which the drill asserts.
`sh scripts/e2e/loop-drill.sh verify-claim-race` passes and goes **red** (3 rows) when
`claims_mission_landed` is removed; `verify-merged-claim` and `verify-retire` both still pass
unchanged; `verify-all` reports 0 failed; `node scripts/test-workflow-scripts.mjs` passes (5394/0).
`superseded`'s classification, its precedence after `claim_active`, and its consumer set are
untouched.

### Discovered Insights

- **Insight**: the mission grain's ticket set must be read from the claim's **tip**, not from the
  base.
  **Context**: the tip is the branch's own statement of what its unit is. Reading the base would
  ask the twin's question instead, and a mission whose tickets the base has archived and re-planned
  would answer about work this branch never held. It is also why a unit with no tickets at the tip
  answers `false` and falls through rather than proving supersession from an empty set.
