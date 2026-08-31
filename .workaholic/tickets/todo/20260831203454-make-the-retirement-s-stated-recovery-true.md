---
created_at: 2026-08-31T20:34:54+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: prove-a-claim-branch-is-empty-before-deleting-it
merge_policy:
verification_handoff: 
---

# Make the retirement's stated recovery true

## Overview

PROPOSED. The ask names a second defect beside the derivation: the safety argument written into
the retirement is itself inverted. `retire-claim.sh`'s header states that what makes a
destructive act safe here is the proof and nothing else, and offers as recovery that a deleted
branch is recoverable from the base's own history *because its content is on the base — that is
what `superseded` means*. For the two measured branches that parenthesis was false, and it is
the load-bearing half. Once the derivation is repaired the sentence becomes true; this ticket
makes the documents say what is now actually guaranteed, and say which part is guaranteed by
what.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/retire-claim.sh` — the header carrying the safety
  argument and the recovery claim.
- `plugins/workaholic/skills/drive/scripts/delete-retired-claim-branch.sh` — the CI act's own
  header and its `not_on_base` bound, whose name now describes what it actually tests.
- `plugins/workaholic/skills/drive/reference/claims.md` — *Proofs and judgements*, and the
  three-acts contract.
- `CLAUDE.md` — the claim-protocol and three-acts sections.

## Implementation Steps

1. Rewrite the recovery claim to state the two halves separately: the branch's content is on
   the base **because the diff term proved it**, and the tickets are archived because the
   archive test proved it. Before this mission the second was standing in for the first.
2. State the failure that produced this, with its measurement, so a later reader knows why the
   term exists and cannot remove it as redundant — the archive test and the diff test answer
   different questions and neither implies the other.
3. Record the 403's role honestly: the delete has never actually run against the measured
   branches, so the loss is a near miss rather than a history, and repairing the transport
   without the verdict would have turned a reported nuisance into a silent loss on the first
   tick after the fix.
4. Confirm `not_on_base`'s name still describes what it tests after the change, and rename or
   re-document it if it does not.
5. Update `CLAUDE.md` in the same commit.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- No document claims a recovery the code does not provide.
- The two proofs are stated separately, each naming what it establishes.
- `CLAUDE.md`, `claims.md` and both act headers agree.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — including the proofs-and-judgements table checks,
  which fail on a word nothing emits or a row called a proof wrongly.
- A read of each header against the shipped behaviour.

**Gate** — what must pass before approval:

- Documentation lands in the same commit as the behaviour it describes.

## Considerations

- This is the smallest ticket in the mission and the easiest to skip. It is here because the
  measured incident had two halves — a derivation that was wrong and a document that said it
  was right — and repairing only the first leaves the next reader the same false assurance.
- Resist widening the headers. They are already long; what is added is one sentence per proof
  and the measurement that earned it.
