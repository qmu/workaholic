---
created_at: 2026-08-28T10:22:30+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: finish-a-proved-retirement-where-the-write-is-permitted
merge_policy:
verification_handoff: 
---

# Re-prove the verdict inside CI and bound what may be deleted

## Overview

PROPOSED. A branch delete is destructive and outward-facing, so what makes it safe is the
**proof and nothing else** — `retire-claim.sh`'s own rule. CI must therefore re-derive the
verdict at the moment of the act rather than trust the candidate list it was handed, which
is the writer's existing discipline (`step-retire-claims.sh` reads candidates once; the
writer re-proves before touching anything) applied across an executor boundary where the
gap between the two reads is larger.

On top of the proof, the act is **bounded**: only a `work-*` branch, only one whose content
is on the base, never one with an open pull request, never a `release/*`. Each refusal is
named and the job still exits 0 — a refusal is an answer.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/retire-claim.sh` — the proof gate to mirror:
  `superseded` only, `not_superseded:<verdict>`, `ambiguous_claim`, `unanswerable:<why>`
- `plugins/workaholic/skills/drive/reference/claims.md` — *Proofs and judgements*; the
  classification a consumer may act on, and the sub-table that must not gain a row
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — the shared derivation; read
  only, emits nothing new
- `.github/workflows/claim-retirement.yml` — the caller
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — the ref delete's transport

## Implementation Steps

1. Read `retire-claim.sh`'s proof gate and every refusal it names, and the
   *Proofs and judgements* section of `drive/reference/claims.md` in full.
2. In the CI-side act, re-run the claim scan and re-derive the row's verdict immediately
   before the delete. Refuse anything that is not `superseded`, by its **own verdict word**
   (`not_superseded:<verdict>`), so `stale`, `queue_drained` and `claim_active` stay visible
   as what they are.
3. Refuse `ambiguous_claim` and `unanswerable:<reason>` as their own refusals, never folded
   into a local verdict — an absent reading must send a reader to the lookup that failed.
4. Add the bounds, each refused by name: branch does not match `work-YYYYMMDD-HHMMSS`
   (`not_a_work_branch`), a `release/*` ref (`release_branch`), content not on the base
   (`not_on_base`), an **open** pull request on that head (`pull_request_open`).
5. Always exit 0. A refusal is reported; the run is not failed by one.
6. Assert in `scripts/test-workflow-scripts.mjs` that the proof gate is not widened: no
   verdict word other than `superseded` reaches the delete, and `lib/claims.sh` emits no
   new word.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Only a row re-proved `superseded` at the moment of the act is deleted
- Every other verdict is refused carrying **its own word**; `ambiguous_claim` and
  `unanswerable:<reason>` are their own refusals
- The four bounds each refuse by name and none of them can be satisfied by a
  `release/*` ref or a branch with an open pull request
- Every path exits 0
- `superseded` gains no new meaning and `lib/claims.sh` emits nothing new

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-retire` (must stay green — the container path is
  unchanged by this ticket)

**Gate** — what must pass before approval:

- Both commands pass, and a fixture proves a live claim's branch is refused rather than
  deleted

## Considerations

- The dangerous direction is widening the gate, not narrowing it: a wrong refusal delays a
  cleanup, a wrong delete tears down a branch another run is driving. Where a reading is
  absent, refuse.
- Re-proving in CI is deliberately redundant with the container's earlier read. The
  redundancy is the point: the two reads are separated by a queue and a checkout.
- Do not add a verdict word for "CI may delete this" — that is a second derivation of
  `superseded` and exactly what the proofs table exists to prevent.

## Final Report

Development completed as planned.

`drive/scripts/delete-retired-claim-branch.sh` re-runs the claim scan and re-derives the row's
verdict immediately before the delete, refusing anything that is not `superseded` by its own
verdict word (`not_superseded:<verdict>`), with `ambiguous_claim` and `unanswerable:<reason>`
as their own refusals. The unit resolves through the library's live-row rule. On top of the
proof it is bounded four ways, each refused by name — `release_branch`, `not_a_work_branch`,
`not_on_base`, `pull_request_open` — and every path exits 0. `superseded` gained no new meaning,
`lib/claims.sh` emits nothing new, and the *Proofs and judgements* tables are untouched.

The suite pins the gate as a third acting consumer beside `retire-claim.sh` and
`retry-undelivered.sh`, read out of the script's own source, so widening it fails there rather
than in production.

### Discovered Insights

- **Insight**: `not_on_base` is genuinely redundant with the re-proved verdict at the **batch**
  grain and genuinely *not* redundant at the **mission** grain — there the proof is the
  merged-pull-request lookup, a network read, and it is the one reading in this chain that can
  answer differently the second time it is asked.
  **Context**: that asymmetry is what makes "the proof is re-taken where the act happens" true of
  both grains rather than only the cheap one, and it is what the drill exercises with a stub that
  flips its answer between the scan and the bound.
- **Insight**: the two halves of the re-proof are independent guards, not one rule written twice.
  The drill's breaker row was written against the verdict gate alone and **did not break** —
  `not_on_base` caught the live claim on its own.
  **Context**: a later change that "simplifies" one of them away still leaves the act guarded,
  which is why the breaker now has to remove both before the damage happens.
