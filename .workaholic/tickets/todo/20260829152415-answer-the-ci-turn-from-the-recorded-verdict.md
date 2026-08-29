---
created_at: 2026-08-29T15:24:15+00:00
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
