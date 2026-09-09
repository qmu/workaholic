---
created_at: 2026-09-09T13:01:38+09:00
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
