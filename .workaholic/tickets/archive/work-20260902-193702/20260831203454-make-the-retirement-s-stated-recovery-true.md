---
created_at: 2026-08-31T20:34:54+00:00
status: done
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

## Final Report

Development completed as planned. This is the smallest ticket in the mission and, as its own
Considerations predicted, the easiest to skip: the derivation had been repaired while the
document that said it was right had not moved.

- **The two proofs are stated separately** (steps 1 and 2), in `retire-claim.sh`'s header and in
  `drive/reference/claims.md`. The header used to offer as recovery that a deleted branch is
  recoverable *because its content is on the base — that is what `superseded` means*, and that
  parenthesis was the load-bearing half of the whole safety argument and was false. It now names
  what establishes each half: `claims_archived_on_base` / `claims_mission_landed` for *the
  tickets are archived*, `claims_branch_empty_against_base` for *the branch holds no work* — and
  says plainly that **neither implies the other**, with the measurement that proved it, so the
  diff term cannot be removed later as redundant.
- **The 403's role is recorded honestly** (step 3): the delete never ran against the measured
  branches, so this is a **near miss rather than a history**, the tick was reporting that refusal
  as the problem, and repairing the transport without the verdict would have turned a reported
  nuisance into a silent loss on the first tick after the fix.
- **`not_on_base` was checked and re-documented rather than renamed** (step 4). Since the
  emptiness term joined `claims_superseded`, re-deriving it refuses on **two** facts while the
  word names only the first — so the name genuinely under-describes what it tests. It is kept
  because it is a **wire string**: it reaches `record-ci-retirement-turn.sh`'s annotations,
  `read-ci-retirement-record.sh`, and `/moderate`'s `retire-blocked:<unit>:<word>` question key
  and its asked-once ledger. Renaming it would re-ask every standing question under a new key and
  orphan every record written under the old one — a person asked twice about a branch nothing had
  changed about. The cost of keeping it is one paragraph, written where a reader chasing the word
  arrives.
- `CLAUDE.md` moves in the same commit (step 5), and `claims.md`, `CLAUDE.md` and both act
  headers now agree.

### Discovered Insights

- **Insight**: A refusal word in this repository is an interface, not a label. It is matched by
  CI annotations, by a record reader, and by a question key whose whole purpose is to be stable
  across ticks — so "rename it to match what it now tests" is the expensive option and
  documenting the gap is the cheap one. That inverts the usual instinct.
  **Context**: The same reasoning applies to every `refuse <word>` in the claim protocol's acts.
