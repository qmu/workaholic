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

Development completed as planned. The failing case is reproduced offline, every layer's
current answer is recorded, and no behaviour changed.

`seed_stranded_claims` in `scripts/e2e/loop-drill.sh` builds a bare origin, a seeding clone
and a reading clone with three claims whose tickets are all archived on the base under
`work-other/`: `batch-stranded` (batch grain, holding `src/stranded.txt`), `m1` (mission
grain, holding `docs-stranded.md`) and `batch-clean` (a claim commit plus a heartbeat and
nothing else). Its `gh` stub's ref DELETE removes the ref from the bare origin, so the
destructive act actually happens rather than being answered.

What each layer answers today, verbatim:

- `claims_superseded` — `true` for all three, at both grains.
- `list-claims.sh` — `resume_reason: "superseded"` for all three.
- `list-retirable-claims.sh` — all three offered as candidates.
- `delete-retired-claim-branch.sh` — `{"deleted": true, ..., "state": "deleted"}` for all
  three; afterwards `origin` carries `main` alone and `src/stranded.txt` is reachable from
  no ref.

The inversion the ask names is confirmed by reading and by running: the CI act's
`not_on_base` bound calls `claims_superseded` again rather than testing the branch's own
diff, so it is a re-derivation of the same proof and refuses nothing this gap lets through.

Cost of the proposed term, measured on this repository (1156 archived ticket paths on
`origin/main`): 20 iterations of `git ls-tree -r --name-only origin/main -- .../archive`,
the scan's existing most expensive gate, take 0.079s (~4.0 ms per claim); 20 iterations of
`git merge-base` plus `git diff --name-only` over a real `work-*` branch take 0.165s
(~8.3 ms per claim). The new term is roughly twice the existing worst gate and can afford
to run per row, though placing it last still means it only runs where every cheaper
condition already said `true`.

### Discovered Insights

- **Insight**: every claim branch has a non-empty `merge-base..branch` diff, including one
  that holds no work at all.
  **Context**: a claim STAMPS `claim: <branch>` into the artifacts it claims, so the claim
  commit itself changes the tree. A bare "is the diff empty" term would therefore refuse
  every retirement, including the legitimate ones. A heartbeat and a resume commit are
  empty commits and contribute nothing, so the claim's own stamped artifacts — the list the
  scan already carries as the row's tenth field — are the whole of the subtraction the
  reading needs.
- **Insight**: the CI act's second proof is not a second proof.
  **Context**: `delete-retired-claim-branch.sh`'s header calls `not_on_base` "re-derived
  from the tree through `claims_superseded`", which is exactly true and exactly the
  problem: the redundancy is real against a *stale* reading and worthless against a *wrong*
  one. Both executors inherit one derivation, which is why repairing `claims_superseded`
  repairs both and why neither needed its own diff test.
- **Insight**: a stub that answers a destructive call is not a drill of the destructive
  call.
  **Context**: the pre-existing `verify-retire` drill reported `remote_branch_deleted:
  deleted` against a stub that deleted nothing, so it proves the act was *attempted*, not
  that it *happened*. The seeder here deletes the ref for real so a later drill can assert
  surviving content rather than a return word.
