---
created_at: 2026-08-31T20:34:53+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: prove-a-claim-branch-is-empty-before-deleting-it
merge_policy:
verification_handoff: 
---

# Reproduce a superseded branch that still holds work

## Overview

PROPOSED. The ask reports a failure whose destructive half has never actually fired — a 403
has been refusing the delete — so the first thing this mission owes itself is the failing case
made real and offline, where deleting costs nothing. Every later ticket is judged against this
reproduction, and no repair may be designed before it exists.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — `claims_superseded`, the
  derivation under test, and `claims_archived_on_base` / `claims_mission_landed` beneath it.
- `plugins/workaholic/skills/drive/scripts/retire-claim.sh` — the destructive consumer.
- `plugins/workaholic/skills/drive/scripts/delete-retired-claim-branch.sh` — the CI consumer,
  whose `not_on_base` bound re-derives `claims_superseded` and therefore inherits the same gap.
- `plugins/workaholic/skills/drive/scripts/list-retirable-claims.sh` — the candidate reader.

## Implementation Steps

1. Build the measured shape offline: a base carrying a unit's tickets archived under **another
   branch's** directory, and the claim branch itself still holding a file that is on no other
   ref. Both the batch grain and the mission grain, since the two take different routes
   through `claims_superseded`.
2. Record what each layer answers today, verbatim: `claims_superseded`, the row's verdict from
   `list-claims.sh`, `list-retirable-claims.sh`'s candidate set, and
   `delete-retired-claim-branch.sh`'s `not_on_base` re-derivation.
3. Confirm the inversion the ask names: that `delete-retired-claim-branch.sh`'s `not_on_base`
   bound is a re-derivation of the same proof rather than an independent diff test, so it
   refuses nothing this gap lets through.
4. Record the cost of the proposed term — one `merge-base` plus one `diff --quiet` per branch —
   measured against the scan's existing per-claim cost, so the later ticket knows whether it
   can afford to run per row or only at the act.
5. Write the finding into the mission's `## Changelog` as one line.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The reproduction runs offline with no credential and no network call.
- It demonstrates a branch holding unmerged content being offered as retirable, at both grains.
- Each layer's current answer is recorded before any repair lands.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- The reproduction, run twice, giving the same answers.

**Gate** — what must pass before approval:

- No behaviour change ships in this ticket. It measures; it repairs nothing.

## Considerations

- The 403 masking the delete is load-bearing to how this reads in production and must not be
  relied on. The reproduction deliberately lets the delete succeed, which is the only way to
  see what would be lost.
- A branch may hold work that is genuinely disposable — a resume commit, a heartbeat, a claim
  commit. The reproduction must include one of those too, or the later ticket will not know
  which non-empty diffs are real work and which are the protocol's own bookkeeping.

## Final Report

Development completed as planned, with one honest deviation the ticket could not have
foreseen: the repair it was written to precede **had already landed** (2026-09-01, issue
#788), so step 2's "record what each layer answers *before* any repair lands" was no longer
reachable. What was recorded instead is what each layer answers **now**, which is the
question the later tickets are judged against.

The reproduction was built and run offline — no network, no credential, throwaway
repositories under the OS temp dir, removed unconditionally. Four cases, both grains:

- **A — batch grain, the measured shape.** Tickets archived on the base under *another*
  branch's directory; the claim branch still holding `docs/orphan.md`, present on no other
  ref. `claims_branch_empty_against_base` = `false`, `claims_superseded` = `stranded`.
- **B — batch grain, the ordinary superseded twin.** The branch differs from the base only
  inside `.workaholic/`. `claims_branch_empty_against_base` = `true`,
  `claims_superseded` = `superseded`. The `:(exclude).workaholic` term is what keeps the
  verdict's ordinary case alive.
- **C — mission grain**, `mission.md` as the artifact, a file on no other ref: `false` /
  `stranded`. Both grains agree.
- **D — the emptiness cannot be read.** An absent ref, empty arguments and an unrelated
  history each answer `unknown`, never `true`; `claims_superseded` routes `unknown` to
  `stranded`. A degradation licenses no delete.

Step 3's inversion is confirmed repaired rather than merely re-derived:
`delete-retired-claim-branch.sh` now refuses `branch_holds_work` and
`emptiness_unanswerable` **beside** `not_on_base`, so the CI act carries the emptiness as a
gate of its own on the classes where it is not already the row's evidence.

Step 4's cost: 50 readings in 373 ms — **~7.5 ms per branch**, one `merge-base` plus one
`diff --quiet`. That is cheap against the scan's most expensive gate (the archive listing,
one per claim), so the term is affordable per row and does not need deferring to the act.

### Discovered Insights

- **Insight**: The `:(exclude).workaholic` pathspec inside `claims_branch_empty_against_base`
  is load-bearing, not a nicety. A bare `diff --quiet` calls *every* genuinely superseded
  claim stranded, because the superseded shape is a twin branch that archived the same
  tickets under its own `archive/<branch>/` directory — the two trees differ there by
  construction. Case B is the row that proves it, and removing the pathspec would retire the
  verdict entirely rather than tightening it.
  **Context**: A later reader tempted to "tighten" the test by dropping the exclusion would
  silently stop every retirement in the repository while believing they had made the proof
  stricter.
- **Insight**: The reproduction reaches `claims_superseded` only with
  `WORKAHOLIC_CLAIM_MERGED_LOOKUP=0`. Without it the mission grain falls through to
  `claim-merged.sh`, the protocol's one network read, and an offline drill would answer
  `unanswerable` for reasons that have nothing to do with the emptiness under test.
  **Context**: Any hermetic row or drill arm over this derivation must set it, or it is
  measuring the transport rather than the verdict.
