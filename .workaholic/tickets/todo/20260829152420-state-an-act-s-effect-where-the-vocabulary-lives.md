---
created_at: 2026-08-29T15:24:20+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: read-back-whether-the-loop-s-own-act-took-effect
merge_policy:
verification_handoff: 
---

# State an act's effect where the vocabulary lives

## Overview

PROPOSED. This repository's rule is that a change updates every affected document in
the same commit, and its claim vocabulary lives in exactly one home. This ticket
states the new reading where a later reader will look for it: beside the
proofs-and-judgements tables in `drive/reference/claims.md`, in
`moderate/reference/workflow.md` where the step's rules live, and in `CLAUDE.md`.

It is the mission's last ticket by dependency, not by importance: the words it
records are the ones every consumer keys on.

## Policies

- `workaholic:development` / `policies/change-history.md` — the record travels with the change
- `workaholic:implementation` / `policies/single-source-of-truth.md` — one home per vocabulary

## Key Files

- `plugins/workaholic/skills/drive/reference/claims.md` — *Proofs and judgements*, and *When an act
  of the retirement is refused*, which states the container-side finding this mission builds on
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the step's rules and the classified
  finding table
- `CLAUDE.md` — the claim-protocol bullet and the `/moderate` row
- `docs/loop-drill-runbook.md` — the register entry from the previous ticket
- `scripts/test-workflow-scripts.mjs` — the pin that fails when a word and its table disagree

## Implementation Steps

1. **Add an act's-effect section beside the two existing keyed tables in `claims.md`**, not inside
   either: one column cannot classify three different questions, and a second document would be the
   second home the split exists to prevent. State that every value is a **judgement**, with the
   reason — a run is re-runnable and a branch's presence can change between two reads, so no
   consumer may revert, re-run, gate, hold or merge on it.
2. **Name the enumerated consumers**, as the existing tables do, so the pin can fail when one
   reaches an acting call site.
3. **Record the measurement, not just the rule**: the run at `616e3e5` completed green while three
   proved candidates stood, and CI's own log showed `candidates: []` where the container's identical
   reader found three. A later reader must be able to see what the change was answering.
4. **Correct the premise the change retires, in place.** `ci-retirement-turn.sh`'s store-free
   argument — *a successful CI turn removes the claim row and the candidate with it* — was the
   design and not the behaviour; say so rather than deleting the sentence, and say what replaced it.
5. **State the narrowed asked-once rule** in `moderate/reference/workflow.md`: asked once per
   (unit, refusal word), an unchanged word held forever, every hold and cap unchanged.
6. **Update `CLAUDE.md`'s claim-protocol bullet and `/moderate` row** to current behaviour only —
   this file states current behaviour, and the history belongs in the reference documents and the
   git log.
7. **Extend the suite's pin** so a word the reader emits that no table classifies fails the suite,
   and so does a table row naming a word nothing emits.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every value the effect reading emits is classified in exactly one place, as a judgement, with its
  enumerated consumers named.
- The retired premise is corrected in place with the measurement that retired it.
- `CLAUDE.md` and `moderate/reference/workflow.md` describe the shipped behaviour, with no stale
  sentence about a completed run implying a taken act.
- The suite fails on an unclassified word and on a classified word nothing emits.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` passes, and fails when a word is removed from the table.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`.
- `grep` for the retired sentence returns only the corrected form.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — the reference
  documents ship in the generated bundle, so `outputs/` must be regenerated in the same change.
- `sh scripts/e2e/loop-drill.sh verify-all` passes.

## Considerations

- The temptation is to add a fourth vocabulary that merges the two acts' refusal words. Refused in
  the previous ticket and restated here: a reader must be sent to the word a script actually
  printed.
- `superseded` stays a **proof** and `lib/claims.sh` emits nothing new — this mission adds a reading
  about acts, not about claims, and conflating them is the drift the one-home rule prevents.
- Documentation is this ticket's whole deliverable, which is exactly the shape `/propose` refuses as
  a *move*; it is admissible here as the closing ticket of a building mission, not as the mission.
