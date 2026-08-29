---
created_at: 2026-08-29T15:24:15+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: read-back-whether-the-loop-s-own-act-took-effect
merge_policy:
verification_handoff: 
---

# Answer the CI turn from the recorded verdict

## Overview

PROPOSED. `ci-retirement-turn.sh` answers `taken` when a **completed run exists at
the base tip**, on the premise its own header states: *"CI deletes the branch when
it succeeds, and unmerged remote branches are the only claim oracle — so a
successful CI turn removes the claim row and the candidate with it."* Measured
2026-08-29, that premise is false in this repository: the run at `616e3e5` completed
and three proved candidates still stand, so `taken` is returned for a turn that took
nothing and `/moderate`'s `retire-blocked:<unit>` is suppressed forever.

This ticket reworks the reading to answer from **what the act answered** (recorded
by the previous ticket) rather than from a run's existence or exit status. The
vocabulary widens by one value: `taken` / `refused:<word>` / `pending` /
`unreadable`, beside the existing `unavailable`.

## Policies

- `workaholic:implementation` / `policies/observability.md` — a reading must rest on evidence
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/ci-retirement-turn.sh` — the reading, and its header,
  whose store-free argument must be restated rather than deleted
- `plugins/workaholic/skills/moderate/scripts/step-retire-claims.sh` — the one consumer; its
  suppression rule reads `taken`/`pending`/`unavailable` today
- `plugins/workaholic/skills/drive/reference/claims.md` — where the words are classified

## Implementation Steps

1. **Read the recorded verdict for the completed run at the base tip**, per unit, and answer from
   it:
   - the act answered a success → **`taken`**
   - the act answered a refusal → **`refused:<the act's own word>`**, carried verbatim
   - the candidate reading yielded this unit no entry at all (a `[]` reading, or a candidate set
     that did not name it) → **`refused:<the candidate reading's reason>`** where it named one, and
     otherwise `unreadable` — never `taken`, which is what the measured run answered
   - no completed run at this tip → **`pending`**, unchanged
   - no such workflow here → **`unavailable`**, unchanged
   - the record is absent or unparseable on a run that did complete → **`unreadable`**
2. **Never infer `taken` from a run's exit status or existence.** The one sentence this ticket
   removes is the inference; state in the header what replaced it and why the store-free premise
   stopped holding, with the measurement.
3. **Keep the reading store-free.** It reads the run the tick is already reading and the tree; it
   creates no cursor, no ledger and no field. `readable`/`reason` keep their meanings.
4. **`unreadable` suppresses nothing**, unchanged — `ci-retirement-turn.sh`'s own discipline that
   an over-eager question beats a silently dropped one. State that `refused:<word>` **also**
   suppresses nothing: it is precisely the case a person must hear about.
5. **Update the one consumer** so `refused:<word>` and `unreadable` leave the question exactly where
   it was before this narrowing existed, and only `taken` and `pending` hold it — `pending` for that
   tick only.
6. **Classify every new value in `claims.md`.** All of them are **judgements**: a workflow run is
   re-runnable, so each can become false by looking again — the one property a proof must not have.
   The pin in `test-workflow-scripts.mjs` must cover them.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `ci-retirement-turn.sh` returns `taken` only when the recorded verdict says the act succeeded.
- A completed run whose record shows a refusal, or shows this unit no entry, never returns `taken`.
- `pending`, `unavailable` and `unreadable` behave exactly as they do today.
- Every value the script emits is classified in `claims.md` as a judgement, and the suite fails on
  an unclassified one.

**Verification method** — the commands/tests/probes that prove them:

- The first ticket's reproduction now **passes** for the reading half: the standing candidate reads
  `refused:<word>` or `unreadable`, never `taken`.
- `sh scripts/e2e/loop-drill.sh verify-ci-retirement` passes, including its existing `pending` and
  `taken` rows.
- `node scripts/test-workflow-scripts.mjs` passes.

**Gate** — what must pass before approval:

- No consumer **acts** on any of these words: the licence stays *report and ask*, exactly as the
  base-checks sub-table already fixes it.

## Considerations

- The header's store-free argument is **narrowed, not abandoned**: the reading still stores
  nothing; what changes is that it consults the run's recorded answer instead of its existence.
- `refused:<word>` carries the act's own vocabulary rather than a second one, so a reader is sent to
  the same word `delete-retired-claim-branch.sh` and `retire-claim.sh` already print.
- A repository that has not adopted the recording surface reads `unreadable` and keeps exactly the
  question behaviour it has today — no consuming repository is made worse by this.

## Final Report

Development completed as planned.

**The reading is per unit now, and so is the suppression.** `ci-retirement-turn.sh` takes
`[<unit> ...]` and returns a `units[]` entry per unit alongside the run-level word. The retired
inference — *a completed run at the base tip means CI saw this tree and the branch survived it,
therefore `taken`* — is gone, replaced by the turn's own recorded answer, read through
`read-ci-retirement-record.sh`. `taken` is claimed **only** on the act's own success word, never
on a run's existence and never on its exit status, which is green by design because a refusal
must not fail the job.

The header's store-free argument is **narrowed in place rather than deleted**, with the retired
sentence quoted and the measurement that retired it stated beneath it, per step 2.

**One distinction the ticket did not name but the shape demanded**: a tip with *no matching
completed run* is `pending`, while a matching run whose id we cannot read is `unreadable`. Only
`pending` holds a question, so collapsing the two would suppress the ask on our own degradation
— the exact shape this reading exists to remove.

`step-retire-claims.sh` drops a unit from its question set only when that unit's own word is
`taken` or `pending`. A unit the reading never answered keeps its question **by construction**,
because only named units are removed — so `refused:<word>`, `unavailable` and `unreadable` all
suppress nothing without needing a rule of their own.

Every value is classified in `claims.md` as a **judgement**, in a fourth keyed sub-table beside
the three that were there, and the suite pin parses the vocabulary out of the reader's own source
in both directions (a word emitted and unclassified fails; a row naming a word nothing emits
fails; a row called a `proof` fails), plus the consumer's call sites and the exact two words it
may hold on.

### Discovered Insights

- **Insight**: a run-level word and a per-unit word answering the same question is what let one
  degraded reading silence every unit at once.
  **Context**: the old suppression was `blocked=0; rows="[]"` on a single word. Any later reading
  of this shape should answer per subject, so a fact about one unit cannot speak for the rest.
- **Insight**: `taken` did not need replacing, only correcting. At the run level it now means
  *CI had its turn and we can see what it did* — which is what the word should always have meant
  — and the claim that an act succeeded moved to where it belongs, the per-unit answer.
  **Context**: keeping the word avoided a sixth term and kept `verify-ci-retirement`'s existing
  rows meaningful across the change.
- **Insight**: the `claims.md` pin slices its sub-tables by successive `###` headings, so adding
  a fourth vocabulary requires re-slicing the third — otherwise the new rows are read as the
  previous table's and fail its "classifies no word the reader never emits" check.
  **Context**: worth knowing before adding a fifth.
