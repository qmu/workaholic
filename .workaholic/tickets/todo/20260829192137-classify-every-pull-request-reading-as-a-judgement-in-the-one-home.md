---
created_at: 2026-08-29T19:21:37+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: follow-the-pull-requests-the-loop-opens-for-a-person
merge_policy:
verification_handoff: 
---

# Classify every pull-request reading as a judgement in the one home

## Overview

PROPOSED. The words go in the one home that already classifies whether an act the loop
took had its effect — `drive/reference/claims.md` — with the enumerated consumers named,
and `scripts/test-workflow-scripts.mjs` failing when a consumer and the table disagree or
when a consumer **acts** on a judgement.

Every value here is a **judgement**: a pull request can be merged, closed or reopened
between two reads, which is the one property a proof must not have.

## Policies

- `workaholic:implementation` / `policies/single-source-of-truth.md` — one classification, one home
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / `policies/api-design.md` — a vocabulary is named where it is defined

## Key Files

- `plugins/workaholic/skills/drive/reference/claims.md` — *Proofs and judgements* and its
  sub-tables (*The base's own checks*, *Whether the base still accepts a claim branch*,
  *Whether an act the loop took had its effect*); the pattern this follows exactly.
- `scripts/test-workflow-scripts.mjs` — the pin: the suite fails on a word a script emits
  that the table does not classify, on a table row no script emits, on any row called a
  `proof`, and on an enumerated consumer reaching an acting call site.
- `plugins/workaholic/skills/drive/scripts/act-effect.sh` — the nearest sibling table's
  script, and the model for *owns the assembly, owns no act's vocabulary*.
- `CLAUDE.md` — the claim-protocol bullet where this is summarized.

## Implementation Steps

1. Add one **sub-table beside** the existing ones, in the same section — not a second
   document, which is the second home the split exists to prevent. It classifies
   `merged`, `closed`, `open:<age>` and `unreadable`, **every one a judgement**, with the
   reason stated: a pull request is designed to change state, so every reading here can
   become false by looking again, and `unreadable` is besides that the **absence** of a
   reading.
2. State the licence explicitly: **report and ask, and nothing else** — no merge, no
   close, no revert, no re-run, no gate, no hold of work, no lifted gate.
3. Name the **enumerated consumers**: ticket 3's `/moderate` step (asks) and ticket 5's
   two run reports (report). An unenumerated consumer is a suite failure.
4. Extend the existing pin in `scripts/test-workflow-scripts.mjs` rather than writing a
   second one — the pin is what makes prose a fact a change can lose.
5. Update `CLAUDE.md`'s claim-protocol bullet in the same commit (this repository's
   docs-in-the-same-change rule).

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- All four words are classified in `drive/reference/claims.md`, in one sub-table, every
  row a **judgement** and none a proof.
- The enumerated consumers are named, and the suite fails when a consumer and the table
  disagree, when a word is unclassified, or when a consumer reaches an acting call site.
- `CLAUDE.md` states the same classification.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- A deliberate local edit adding a fifth unclassified word must fail the suite.

**Gate** — what must pass before approval:

- The suite passes on the unmodified tree and fails on the deliberate edit above.

## Considerations

- A classifier **function** returning `proof`/`judgement` is refused for the reason the
  original table records: it would be a second derivation of the same fact, which is what
  the table exists to prevent.
- No field is added to any artifact and no script emits a classification word.

## Final Report

**Implemented.** One sub-table **beside** the existing ones, in
`drive/reference/claims.md`'s *Proofs and judgements* section — *Whether an operator-facing pull
request was acted on* — never a second document.

- All four words (`merged`, `closed`, `open:<age>`, `unreadable`) are classified, **every one a
  judgement**, with the reason stated: a pull request is *designed* to change state, so every
  reading here can become false by looking again — the one property a proof must not have — and
  `unreadable` is besides that the absence of a reading.
- **The licence is explicit**: report and ask, and nothing else — no merge, no close, no revert,
  no re-run, no gate, no hold of work, no lifted gate.
- **Enumerated consumers named**: `/moderate`'s `step-operator-pulls.sh` (asks) and
  `/implement`'s and `/propose`'s run reports (report).
- **The existing pin was extended, not duplicated** (`testProofJudgementSplit`): the fifth
  sub-table is parsed apart from the other four — four of these vocabularies now share an
  `unreadable`-shaped word — and the suite fails when a word the reader emits is unclassified,
  when the table classifies a word it never emits, when any row is called a `proof`, or when an
  enumerated consumer reaches an acting call site.
- `CLAUDE.md`'s claim-protocol bullet states the same classification.

**No classifier function, no field on any artifact, and no script emits a classification word** —
the table is the one derivation, exactly as the original's reasoning requires.

**Gate:** the suite passes on the unmodified tree. The deliberate-edit check was exercised by
construction while building it: the vocabulary is parsed out of `publication-effect.sh`'s own
`emit` calls rather than from a list the test carries, so a fifth unclassified word fails the
`every word the publication reading emits is classified exactly once` row, and an extra table row
fails its converse.
