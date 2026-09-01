---
created_at: 2026-08-27T08:22:44+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-re-resuming-a-declared-handoff-unit
merge_policy:
verification_handoff: 
---

# Give a declared handoff its own claim verdict

## Overview

Turn the reading into a verdict. A claim whose remaining work is declared undrivable here
is not `parked_with_pr`: that word's own contract says *the follow-up tickets on its branch
are why it still has work. Taking it over is legitimate* — false by declaration for this
unit. Give it its own word, `resumable: false`, so the takeover the survey keeps offering
stops being offered.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — the verdict chain and the header
  block that documents every word and its next action.
- `plugins/workaholic/skills/drive/scripts/claim.sh` — `resume`'s refusal loop, which must
  refuse by the new name rather than under `parked_with_pr`'s wording.
- `plugins/workaholic/skills/drive/reference/claims.md` — where the words are defined.

## Implementation Steps

1. Re-run the reproduction and confirm it still holds.
2. Add the verdict where the reading applies — after `claim_active` (liveness is what gates a
   takeover, so a run still committing keeps the reading that protects it) and where
   `parked_with_pr` is reached, since that is the branch the measured unit took. Name it for
   what it says about the unit rather than for the field, and document it in the header block
   beside `queue_drained` / `report_incomplete` / `report_undelivered`.
3. `resumable: false`, for its own reason: the next action is a **person satisfying the
   declared verification**, not a takeover — resuming would push an empty `Resume` commit onto
   a branch whose pull request is open, the 2026-08-01 gate this repository already holds.
4. Make `claim.sh resume` refuse it **by its own name**, not under another verdict's wording:
   a refusal that sends the reader to the wrong next action is the failure `report_undelivered`
   was split out to avoid.
5. Leave every other verdict byte-identical, `superseded`'s precedence included: a claim proved
   empty is still `superseded`, whatever it declares.
6. Invert the previous tickets' pinned assertion in the same change.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- The fixture's declared unit reads the new verdict with `resumable: false`.
- An identical unit with the field empty still reads `parked_with_pr`, `resumable: true`.
- `claim.sh resume` refuses the declared unit by the new name.
- Every other verdict, including `superseded`'s precedence over the drained fork, is unchanged.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the reproduction, now inverted, plus the
  unchanged-empty-field case and the `resume` refusal.
- A fixture exercising each existing verdict answers exactly as it did before the change.

**Gate** — what must pass before approval:

- The suite passes; the header block documents the new word and its next action.

## Considerations

- Narrowing `parked_with_pr` versus a sibling reason beside it: a sibling is chosen, on the
  `report_undelivered` precedent the reporter names — the two states call for different next
  actions (take it over versus satisfy the declared verification), and one word answering both
  is what made this invisible.
- This adds no field to any artifact: the declaration already exists and is already read.
