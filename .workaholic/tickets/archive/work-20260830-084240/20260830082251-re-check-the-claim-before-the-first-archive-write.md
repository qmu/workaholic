---
created_at: 2026-08-30T08:22:51+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-two-runs-from-claiming-and-driving-one-unit
merge_policy:
verification_handoff: 
---

# Re-check the claim before the first archive write

## Overview

Tickets 3 and 4 close the window between two **surveys**. They do not close the window between a
survey and the first **write**: a runner can hold a won claim, begin driving, and only later meet a
state its claim no longer covers. The measured cost of a race noticed late is an hour of duplicated
implementation; the cost of noticing it at the first archive write is one survey.

`archive.sh` is the right seam because it is where a driving run **first writes something the base
will see** — it moves the ticket, commits and pushes the claim branch. It already runs
`check-subject.sh` *before* it moves the ticket, precisely so a refusal leaves the tree
byte-identical; this re-check joins that gate, on the same reasoning and in the same place.

It is a **bounded act reading a judgement**: it re-derives the claim at the moment of the write,
refuses by its own word, writes nothing on refusal, and is idempotent.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/machine-checkable-domain-gaps.md` — make the gap fail early
- `workaholic:operation` / `policies/runtime-behavior.md` — the running loop keeps serving and recovering

## Key Files

- `plugins/workaholic/skills/drive/scripts/archive.sh` — the pre-move gate, beside `check-subject.sh`
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — the derivation the re-check reads; unchanged
- `plugins/workaholic/skills/drive/reference/claims.md` — *When a bounded act may read a judgement* enumerates its consumers
- `plugins/workaholic/skills/drive/SKILL.md` — §4's archive step
- `scripts/e2e/loop-drill.sh` — `verify-claim-race`

## Implementation Steps

1. Read `archive.sh`'s existing pre-move gate and `claims.md`'s *When a bounded act may read a
   judgement* before writing anything: that rule requires the act to re-derive at the moment of the
   act, be idempotent, be reversible, and refuse every bound by its own word, **and** it enumerates
   its consumers by name — so this ticket adds a consumer to that enumeration or it is out of
   bounds.
2. Add the re-check ahead of the ticket move: this runner still holds this unit's claim. Read it
   through the existing derivation in `lib/claims.sh` — no second oracle, no new verdict word.
3. Refuse by its own word when the claim is no longer this runner's, leaving the tree
   **byte-identical**: no move, no commit, no push, exit reported to the caller so the run reports a
   refusal rather than a silent skip.
4. Keep it **cheap**: one scan per archive call at most, reusing the fetch the run has already made
   where one is in hand. A gate that doubles the cost of every archive will be removed within a week.
5. Enumerate the new consumer in `claims.md`'s bounded-act table and confirm
   `test-workflow-scripts.mjs`'s pin still passes in **both** directions — an unenumerated act has no
   bound, and an enumerated one trusting a handed-in reading has lost the clause that makes the
   exception safe.
6. Assert in `verify-claim-race` that a runner whose claim was taken between survey and first write
   refuses at the archive rather than writing a duplicate.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The re-check runs before the ticket move and refuses with the tree byte-identical.
- It re-derives through `lib/claims.sh` and adds no verdict word and no second oracle.
- It is enumerated in `claims.md`'s bounded-act consumer list and the pin passes both ways.
- An ordinary archive by the claim's holder is byte-identical to today.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-claim-race` covers both the holder's archive and the dispossessed runner's refusal.
- `sh scripts/e2e/loop-drill.sh verify-all` passes.
- `node scripts/test-workflow-scripts.mjs` passes.

**Gate** — what must pass before approval:

- A run that lost its claim mid-drive writes nothing to the base and says so by name.

## Considerations

- **This is defence in depth, not the repair.** Tickets 3–4 are what stop the race; this bounds the
  damage when a claim changes hands for any other reason (a resume, a release, a retirement).
- The failure mode to avoid is a gate that refuses a **legitimate** archive because a fetch was
  stale. Prefer refusing only on positive evidence that the claim is another runner's, and treat an
  unreadable scan as *proceed* — the opposite bias from the claim act, because here a wrong refusal
  strands finished work.

## Final Report

Development completed as planned. `archive.sh` re-derives who holds the unit immediately before the
ticket moves — beside the subject gate, and **ahead of the todo-layout migration**, which stages
what it converges, so a refusal leaves the tree byte-identical in the strict sense: nothing moved,
nothing staged, nothing committed, and the ticket still in `todo/`.

The reading is `drive/scripts/claim-holder.sh`, a pure read composing `claims_scan` and
`claims_unit_resolution` from `lib/claims.sh`. No second oracle, no new `resume_reason`, and
nothing written anywhere. It answers `mine` / `other` / `ambiguous` / `unknown`, and `archive.sh`
refuses on the two words that are **positive evidence** — `claim_taken_over` (a different live
branch now holds this unit) and `ambiguous_claim` (two live claims, the race itself).

The bias named in the ticket's Considerations is implemented literally and is the **opposite** of
the claim act's: an unreadable scan, an unreachable origin, a shallow clone or a branch with no
claim row all answer `unknown`, and `unknown` proceeds — because a wrong refusal strands finished
work outside the archive and needs the hand-written `git mv` this seam exists to prevent. The
merged-pull-request lookup is switched off for this reading through its existing opt-out: it
compares branch identity and never asks whether a unit is finished, so the one verdict the lookup
can change cannot move the answer, and a REST call per claim per ticket would buy nothing.

The new consumer is enumerated in `claims.md`'s *When a bounded act may read a judgement*, and the
rule gained the paragraph it needed to be honest: **two shapes, one rule**. Until now every
enumerated act **licensed** itself on a judgement; this one **gates** itself on one, and the
direction decides which way an absence falls — a licensing act must refuse on an absence, a gating
act must proceed on one, for the same underlying reason. `scripts/test-workflow-scripts.mjs`'s
`JUDGEMENT_READERS` gained `claim-holder.sh`, which is what makes DIRECTION ONE sweep `archive.sh`
in.

Verified: the pin passes in **both** directions and was proved able to fail — deleting the
`archive.sh` row from the rule's table turns `every script that acts on a judgement is enumerated
in the rule` red (5391/1), and restoring it returns 5394/0. `verify-claim-race` asserts both sides:
the raced runner's first write refuses by its own word with `git status`, `HEAD` and the ticket's
location unchanged, and the **sole claim holder's** archive succeeds exactly as before, which is
the row that proves the gate strands nothing.

### Discovered Insights

- **Insight**: a gate placed "before the write" must be placed before the *migration*, not merely
  before the `mv`.
  **Context**: `archive.sh` runs `migrate-todo-owners.sh` between the subject gate and the ticket
  move, and that migration stages what it converges. A re-check placed after it would refuse with
  a dirty index — the half-archived state the subject gate was added in 2026-08-12 to prevent.
