---
created_at: 2026-09-01T11:25:58+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260901112558-read-a-claim-branch-s-pull-request-state.md
mission: leave-only-live-work-in-the-unmerged-branch-list
merge_policy:
verification_handoff: 
---

# Name a closed-unmerged branch as its own candidate

## Overview

PROPOSED. Five branches have a pull request the operator **closed unmerged**, deliberately, as
superseded — `#801`, `#802`, `#790` by `#800`; `#520` by `#519`; `#466` by `#465`. `#802`'s closing
comment reads *"this branch and `main` repaired the same defect twice"*. A hand-closed branch is
not empty by construction, so `superseded` can never reach it and `retire-claim.sh` never will.

Closing a pull request unmerged is a **person's decision about that branch**, which is exactly the
authority a delete needs. This makes it its own candidate word — never folded into the merged one,
because the two say different things and a reader must be able to tell a branch the loop delivered
from one a person discarded.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:safety` / `policies/change-management.md` — a destructive act rests on a stated proof

## Key Files

- `plugins/workaholic/skills/drive/scripts/list-retirable-claims.sh` — the candidate reader; this
  adds the third class beside `superseded_only` and `pull_request_merged`.
- `plugins/workaholic/skills/drive/scripts/branch-pull-request-state.sh` — the source of the
  `closed_unmerged` fact.
- `plugins/workaholic/skills/drive/reference/claims.md` — the classification table; this word is a
  proof and the argument for it differs from the merged one and must be written out separately.
- `plugins/workaholic/skills/drive/scripts/delete-retired-claim-branch.sh` — the act, whose
  `pull_request_open` bound already covers the one case this must not reach.

## Implementation Steps

1. Add the third candidate class to `list-retirable-claims.sh`: a `work-*` branch with no live
   claim row whose pull request reads `closed_unmerged`, carrying
   `candidate_reason: pull_request_closed_unmerged`.
2. Keep it separate from the merged class in every surface — the candidate row, the CI record, the
   `/moderate` report line. One word answering two questions is how two questions drift, and here
   the questions are *the loop delivered this* and *a person discarded this*.
3. Register the word in `drive/reference/claims.md` as a proof, with **its own** argument: a closed
   pull request is a person's recorded decision about that branch, not a reading of the tree, so
   what makes it safe is authorship rather than emptiness. State the residual risk plainly — the
   branch may still hold work found on no other ref, and closing it unmerged is the operator saying
   that work is not wanted.
4. Because that residual risk is real, make this class's act carry the emptiness reading **as
   evidence, not as a gate**: report `branch_empty: true|false|unanswerable` on the candidate row so
   CI's record names it, and let the next ticket decide whether the act refuses on it.
5. Do not touch `superseded`, `stranded`, or the emptiness derivation.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A branch whose pull request is closed-unmerged, with no live row, appears with its own
  `candidate_reason`, distinct from the merged class in every rendered surface.
- Its row carries a three-valued `branch_empty` reading, `unanswerable` named rather than assumed.
- A branch with an **open** pull request appears in no class.
- `superseded`, `stranded` and the emptiness derivation are byte-identical.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — hermetic rows for closed-unmerged, open, and an
  unanswerable emptiness read.
- `git diff` over `lib/claims.sh` shows no change to the verdict derivation.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes, including the assertion that every emitted claim
  word is classified and no row is miscalled a proof.

## Considerations

- Whether the act should **refuse** a closed-unmerged branch that still holds work is a genuine
  question and is deliberately deferred to the next ticket, where the act lives. Recording it as
  evidence first means CI's own record answers it from real data before anything is gated on it.
- The `#802` case shows why this matters more than the count suggests: five closures is five
  occasions a person read two implementations of one defect and carried the good parts across by
  hand. This ticket removes the residue; the localization ticket asks why it happened.
