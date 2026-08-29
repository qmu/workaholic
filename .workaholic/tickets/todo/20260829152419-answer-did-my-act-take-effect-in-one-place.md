---
created_at: 2026-08-29T15:24:19+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: read-back-whether-the-loop-s-own-act-took-effect
merge_policy:
verification_handoff: 
---

# Answer did my act take effect in one place

## Overview

PROPOSED. The loop performs exactly two acts on a **proof**: the retirement's Act 2
(`retire-claim.sh` in the container, `delete-retired-claim-branch.sh` in CI) and the
delivery retry (`retry-undelivered.sh`). The retry already answers *did my act take
effect* — it records the merge outcome back onto the branch story through
`record-merge-outcome.sh`, so the next survey and `/moderate`'s question read a
current answer. The retirement does not, which is the defect this mission repairs.

This ticket puts the question in **one** place for both, so the answer is derived
once rather than re-derived per act. The retry is the shape to generalise from; it
must come out of this ticket behaving byte-identically.

## Policies

- `workaholic:implementation` / `policies/single-source-of-truth.md` — one derivation, one home
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/retry-undelivered.sh` — the act that already records its
  own outcome; the shape to generalise from
- `plugins/workaholic/skills/story/scripts/record-merge-outcome.sh` — the one writer of the retry's
  recorded outcome; it does not move
- `plugins/workaholic/skills/drive/scripts/retire-claim.sh` — Act 2 in the container, reporting
  `branch_delete_failed` and three act states
- `plugins/workaholic/skills/drive/scripts/delete-retired-claim-branch.sh` — Act 2 in CI
- `plugins/workaholic/skills/drive/scripts/ci-retirement-turn.sh` — the retirement's reader, reworked
  by the previous ticket; this ticket makes it and the retry's reader one shape

## Implementation Steps

1. **Name the question once** and write down what an answer is: for a given act on a given unit,
   `taken` / `refused:<word>` / `pending` / `unreadable`, derived from the tree, the refs and the
   run the tick is already reading — the ask's own constraint, and the reason no new store may
   appear here.
2. **Read the retry's existing derivation and keep it whole.** Its answer is read off the branch
   story blob the claim oracle already fetches — no network call, no second derivation — and that
   property is what makes it the model. Generalising must not turn it into a re-fetch.
3. **Compose rather than duplicate**: one reader answers the question for both acts by composing
   each act's existing outcome source (the branch story for the retry, the recorded CI verdict for
   the retirement). It owns the **assembly** and no act's vocabulary.
4. **Carry each act's own word verbatim.** The two acts have different refusal vocabularies and
   they must not be merged into a third; a reader is sent to the word the acting script printed.
5. **Prove the retry is byte-identical** across the change — its outputs, its refusals and the
   number of network calls it makes.
6. **No field, no store, no second oracle.** State in the reader's header which existing sources it
   composes and that it adds none.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- One reader answers *did my act take effect* for the retirement's Act 2 and the delivery retry.
- Each answer carries the acting script's own word, unchanged.
- `retry-undelivered.sh`'s behaviour, refusals and network-call count are unchanged.
- The reader creates no file, no field, no cursor and no second oracle, and its header names the
  sources it composes.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-delivery-retry` passes unchanged.
- `sh scripts/e2e/loop-drill.sh verify-retire` and `verify-ci-retirement` pass.
- A fixture asserting the reader returns the same word for one act read directly and read through
  the composition.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes, with the proofs-and-judgements pin covering every
  word the reader can emit.

## Considerations

- **Every value here is a judgement, not a proof**: a run is re-runnable and a branch can be
  deleted or restored between two reads, so nothing may revert, re-run, gate or merge on this
  reading. The licence stays *report and ask*.
- The tempting error is a third vocabulary that "normalises" the two acts' refusals. It is refused:
  a normalised word sends a reader to a string no script ever printed.
- This ticket is where the mission's *no second oracle* constraint is most at risk; the reader must
  compose existing sources and be visibly unable to answer on its own.
