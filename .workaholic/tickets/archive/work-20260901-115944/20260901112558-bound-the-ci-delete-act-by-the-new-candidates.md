---
created_at: 2026-09-01T11:25:58+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260901112558-name-a-closed-unmerged-branch-as-its-own-candidate.md
mission: leave-only-live-work-in-the-unmerged-branch-list
merge_policy:
verification_handoff: 
---

# Bound the CI delete act by the new candidates

## Overview

PROPOSED. `delete-retired-claim-branch.sh` re-runs the claim scan and re-derives the row's verdict
immediately before the delete rather than trusting the candidate list it was handed — its header
calls that redundancy the point, because the gap between the two reads is a queue and a checkout
rather than a function call. Two new candidate classes therefore need two new re-derivations and
their own refusal words; without them the act would either refuse every new candidate
(`not_superseded:<verdict>`) or, worse, accept one on a stale list.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:safety` / `policies/change-management.md` — a destructive act re-derives its proof
- `workaholic:operation` / `policies/observability.md` — every refusal carries its own word

## Key Files

- `plugins/workaholic/skills/drive/scripts/delete-retired-claim-branch.sh` — the act. Read the
  whole header before editing: the re-derivation discipline, the closed refusal vocabulary and the
  four bounds are all stated there and none may be relaxed.
- `plugins/workaholic/skills/drive/scripts/record-ci-retirement-turn.sh` — writes the candidate
  reading and each act's `state`/`reason` as check-run annotations; the new words must reach it.
- `plugins/workaholic/skills/drive/scripts/read-ci-retirement-record.sh` — answers per unit
  `taken` / `refused:<word>` / `pending` / `unavailable` / `unreadable`, matched on `head_sha`.
- `.github/workflows/claim-retirement.yml` — `permissions: contents: write` and nothing wider.

## Implementation Steps

1. Teach the act to re-derive **whichever proof the candidate claims**, at the moment of the act:
   `superseded_only` as today; `pull_request_merged` and `pull_request_closed_unmerged` by
   re-reading the pull-request state through `branch-pull-request-state.sh`. A state that changed
   between the list and the act refuses by its own word rather than proceeding.
2. Add the refusals as their own words, never folded into `not_superseded:<verdict>`:
   `not_merged:<state>` and `not_closed_unmerged:<state>`, plus `pull_request_unreadable:<reason>`
   for a read that failed at act time — an **absent** reading must send a reader to the lookup that
   failed, never to a delete.
3. Keep all four existing bounds over the top of both new classes unchanged: `not_a_work_branch`,
   `release_branch`, `not_on_base`, `pull_request_open`.
4. **Rule the deferred question from the previous ticket with the evidence it collected**: for
   `pull_request_closed_unmerged`, refuse `branch_holds_work` when the emptiness reading says the
   branch still holds work found on no other ref, and refuse `emptiness_unanswerable` when it
   cannot be read. The recovery a `superseded` delete offers — *its content is on the base* — is
   false for a hand-closed branch, and issue #788 measured what believing it costs. A merged
   branch needs no such term: its content is on the base by definition.
5. Carry every new word through `record-ci-retirement-turn.sh` and `read-ci-retirement-record.sh`
   so `/moderate`'s `retire-blocked:<unit>:<word>` question names the real reason.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Each new candidate class is re-derived at act time; a state that moved refuses by its own word
  with nothing deleted and exit 0.
- A closed-unmerged branch still holding work is refused `branch_holds_work` and is not deleted.
- Every existing bound and refusal word behaves exactly as before.
- The act stays idempotent: a second run over an already-deleted branch answers `already_gone`.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — hermetic rows per class, per refusal, plus the
  state-moved-between-reads case and the idempotent re-run.
- `sh scripts/e2e/loop-drill.sh verify-all` stays green.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes, including the assertion that fails on a word no
  vocabulary table classifies.
- No new permission appears in `.github/workflows/claim-retirement.yml`.

## Considerations

- Step 4 is where this mission could destroy work if it is wrong. The refusal is written to fail
  **closed**: an unanswerable emptiness reading refuses rather than deletes, which is the same
  direction issue #788 turned `superseded` in.
- The act gains no new transport. It is the same REST seam run by an executor where the write is
  permitted, one candidate class over.

## Final Report

Development completed as planned.

`delete-retired-claim-branch.sh` now takes `--branch` and `--reason` beside its positional
unit, defaulting to `--reason superseded_only` so every caller that passed a unit alone before
this change behaves exactly as it did. `--branch` is **required** for the two pull-request
classes and refused `no_branch` when absent, because their candidates may carry no unit at all
— a publish-tree publication has no `Claim` commit, so the oracle names none, and the
workflow's old `unit`-keyed loop skipped precisely the branches those classes exist for.

Each class re-asks **its own** question immediately before the delete, through
`branch-pull-request-state.sh`, and refuses by its own word rather than through
`not_superseded:<verdict>` — which would send a reader to the claim oracle for a candidate the
oracle never named: `not_merged:<state>`, `not_closed_unmerged:<state>`,
`pull_request_unreadable:<reason>`.

**Step 4's deferred question is ruled and it fails closed.** A `pull_request_closed_unmerged`
candidate is refused `branch_holds_work` when `claims_branch_empty_against_base` says the
branch still holds work found on no other ref, and `emptiness_unanswerable` when that reading
cannot be made — the direction issue #788 turned `superseded`, applied to the one class whose
proof is **authorship** rather than emptiness. A merged branch takes no such term: its content
is on the base by definition.

`release_branch`, `not_a_work_branch` and `pull_request_open` apply to every class, unchanged.
`not_on_base` stays the `superseded_only` class's own term, and the header **says why** rather
than leaving it to be inferred: it re-derives `claims_superseded` from the unit's artifacts,
which a candidate with no unit does not have, so applying it to the new classes would produce a
bound that reads as satisfied because there was nothing to evaluate. A live claim row outranks
every pull-request reading and is re-derived at the act too.

`record-ci-retirement-turn.sh` and `read-ci-retirement-record.sh` needed **no change**: the
recorder copies `state`/`reason` verbatim, so every new word reaches the annotation and
`/moderate`'s `retire-blocked:<unit>:<word>` question by construction. The workflow gained no
permission — the assertion pins `contents: write` and nothing wider — and no new transport.

Verified: `node scripts/test-workflow-scripts.mjs` — 5903 passed, the only failure the
pre-existing clock-dependent row (`expected "settled", got "unknown"`, exactly the symptom
`20260901132500` predicts). `sh scripts/e2e/loop-drill.sh verify-all` — `ok: true`, 41 drills,
0 failed, `verify-ci-retirement` among the passes.

### Discovered Insights

- **Insight**: the act's arguments had to become a *question selector*, not an answer. `--reason`
  names which proof to re-derive and carries none of its content.
  **Context**: the tempting shape is a `--proved` flag that lets CI tell the act what the reader
  concluded, which would delete the re-derivation discipline in one line while looking like a
  refactor. The distinction is worth stating in a review of any later change to this file.
- **Insight**: a test that builds a branch with `git add -A` inside a fixture whose transport is
  an untracked stub deletes that transport on the way back to `main`.
  **Context**: cost a full suite run to find. Name the file in `git add` inside any fixture that
  carries an untracked stub on `PATH`.
