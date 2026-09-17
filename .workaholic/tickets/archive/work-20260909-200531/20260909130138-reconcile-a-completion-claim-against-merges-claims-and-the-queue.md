---
created_at: 2026-09-09T13:01:38+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: report-a-native-tick-from-reconciled-evidence-not-from-a-worker-s-word
merge_policy:
verification_handoff: 
---

# Reconcile a completion claim against merges, claims and the queue

## Overview

PROPOSED. The reported session called implementation complete with **zero merges, six queued
tickets and two unreconciled pull requests**, and initially misidentified its own runner's claims
as another loop's. A proposal pull request can close an inbound feedback issue before any
implementation exists, so a closed issue is not evidence either.

The tick's report is assembled from each worker's own `executed` / `outcome` / `reason`. Nothing
between the worker and the report asks the tree, the claim oracle or the queue whether that is
true. This ticket makes a completion claim a reconciled reading rather than a relayed one.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/commands/infinite-development.md` — the report contract ("each completed
  worker's `executed`, `outcome`, and `reason`") and where the reconciliation must sit.
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — the claim oracle, the only reader of
  which claims are this identity's.
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — the queue reading, with its own
  `backlog_all_excluded` and degradation words.
- `plugins/workaholic/skills/drive/scripts/act-effect.sh` — the existing reader for whether an act
  the loop took had its effect.
- `plugins/workaholic/skills/loops/scripts/tick-progress.sh` — the tick's progress reading.
- `plugins/workaholic/skills/drive/reference/claims.md` — proofs versus judgements; a completion
  claim must rest on a proof.

## Implementation Steps

1. **Reproduce and localize first.** Take a tick whose workers reported success and re-derive, from
   the tree and the oracle alone, how many pull requests merged, how many claims stand and how many
   tickets remain queued. Record where the report and the reconciliation disagree.
2. Define the reconciled completion reading over readers that already exist — merged evidence,
   `list-claims.sh`'s rows, `plan-units.sh`'s backlog — and never over a worker's own word or a
   closed feedback issue. No new store, no new field on any artifact.
3. Make a degraded reading name itself: an unreadable oracle, forge or queue is reported by its
   reason with null counts, never as zero and never as complete (`plan-units.sh`'s own convention).
4. Keep a pending or failed deployment a **separate** visible state; a merge is not a deployment
   and completing the queue is not confirming a target.
5. State in `commands/infinite-development.md` that a completion claim names the reconciled counts
   it rests on, and that a claim naming none is non-conformant on its face.
6. Add hermetic rows covering: worker says done and nothing merged; a proposal PR closed the
   issue; the oracle unreadable.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A completion claim names merged count, standing claims and remaining queue, each from the
  existing readers.
- A worker's own report and a closed feedback issue are never sufficient evidence of completion.
- An unreadable oracle, forge or queue reads as unreadable with null counts, never as zero.
- A pending or failed deployment stays its own state in the report.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the new reconciliation rows.
- A tick report showing the reconciled counts beside each worker outcome.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

## Considerations

- This must not become a second claim oracle. Compose `list-claims.sh`, `plan-units.sh` and
  `act-effect.sh`; a second walker over the same refs is what this repository has repeatedly
  refused.
- Reconciliation costs reads. Bound it to the tick's own units rather than the whole repository.

## Final Report

Development completed as planned.

Step 1 was reproduced against this repository rather than against the retrospective's narrative,
and it reproduced the shape immediately: running the new reader over this very unit answered
`standing_claims: 2, standing_claims_mine: 2`, this unit's delivery `pending`, and
`queued: null` with `degraded: [{plan-units, survey_not_current}]` — because the base had moved
under the main checkout while the unit was being driven. That last reading is the whole point of
the ticket in miniature: a reader that had taken the survey's `backlog_size` at face value would
have printed a count from a checkout two commits stale and called it the queue.

The reconciliation is `loops/scripts/reconcile-completion.sh`, beside `tick-progress.sh` in the
tick's own skill. It composes and derives nothing: `act-effect.sh` for merged evidence,
`list-claims.sh` for standing claims, `plan-units.sh` for the queue. It walks no ref, reads no
`.workaholic/` artifact, reaches no forge and touches no issue source — the last by construction,
since a *proposal* pull request closes an inbound feedback issue before any implementation exists.

### Discovered Insights

- **Insight**: Composing `act-effect.sh` per unit made the reconciliation cost N+1 oracle scans
  and N+1 fetches of one fact, so the reader gained a `--claims FILE` hand-back.
  **Context**: `act-effect.sh delivery` composes `list-claims.sh` to get the row, and the
  reconciliation already holds that reading. Without the hand-back a tick naming five units
  fetched the oracle six times — and worse, the six readings could disagree, which is exactly the
  drift a single reading exists to prevent. The flag is the same shape
  `direction-state.sh --emit-survey` already uses, changes no word of `act-effect.sh`'s
  vocabulary, and is what also makes the composition testable hermetically: without it the
  fixture's `act-effect.sh` call ran `list-claims.sh` in a directory with no remote and answered
  `unreadable` for every unit.

- **Insight**: The survey's own five `ok`-forbidding facts are the right gate on its
  `backlog_size`, and reading only `backlog_size` would have been silently wrong.
  **Context**: `plan-units.sh` returns a plausible count even when `current: false` — 7 here,
  from a checkout the base had moved past. A survey that forbids `ok` has established nothing
  about the queue, so its count is not usable as one; the reader re-reads those five facts rather
  than trusting the number beside them, and answers `queued: null` with a named reason instead.

- **Insight**: `complete` had to be three-valued for the same reason `propose_gate` is.
  **Context**: A degraded source makes it `null`, never `false`. `false` asserts that outstanding
  work was *seen*; a reader that could not look has seen nothing, and collapsing the two is
  precisely how a completion claim becomes wrong and confident — the measured failure. A caller
  switching on two values sees an unfamiliar third and falls through, which is the safe direction.

- **Insight**: Whose the standing claims are is part of the answer, not a detail of it.
  **Context**: The measured session read its own runner's claims as another loop's — a mistake
  only a reading that never names the owner can make. `standing_claims_mine` rides beside
  `standing_claims`, resolved on the claim protocol's own precedence
  (`WORKAHOLIC_CLAIM_IDENTITY` as an override, then `git config user.email`), and an identity
  that cannot be resolved is a named degradation rather than a zero.
