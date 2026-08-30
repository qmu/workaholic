---
created_at: 2026-08-30T02:21:38+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-how-long-the-loop-has-been-stuck
merge_policy:
verification_handoff: 
---

# Classify every age value as a judgement and pin it

## Overview

PROPOSED. A **sixth vocabulary in the one home**: `drive/reference/claims.md`'s *Proofs and
judgements*. Every value the age reader emits is a **judgement** — the log grows every hour, so
each reading can become false by looking again, which is the one property a proof must not have,
and `readable: false` is besides that the **absence** of a reading. So **no gate, hold, re-ask,
escalation, merge, claim or sort may read the age**: the questions name it and the run reports
report it, and that is the whole licence.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/reference/claims.md` — the one home; a **sixth sub-table** in
  the same section, parsed apart from the other five exactly as they are parsed apart from each
  other (several already share an `unreadable`-shaped word, and folding them would report one rule
  as copies of itself).
- `scripts/test-workflow-scripts.mjs` — `testProofJudgementSplit`, extended.
- `plugins/workaholic/skills/moderate/scripts/condition-age.sh` — the word set is parsed out of
  **its own emissions**, never a list the test carries.

## Implementation Steps

1. Add the sub-table under its own heading in the same section, one row per value the reader emits,
   each classified `judgement` with what established it and what a consumer may do.
2. Extend `testProofJudgementSplit` on the established pattern, splitting the new tail off the
   previous sub-table by its heading and asserting **both directions**: every word the reader
   emits is classified exactly once, and the sub-table classifies no word the reader never emits.
   A word emitted and unclassified leaves a consumer with no rule; a word classified and never
   emitted is a rule about nothing.
3. Assert **no row is a proof**, the load-bearing claim.
4. **Enumerate the consumers** — the four question steps and the two run reports — and ban acting
   call sites in each, on call sites rather than words (the steps' own prose says in English that
   they gate nothing, so a word-level ban would fail on the sentence stating the rule). Ban the
   shapes the existing pins ban plus a gate reading: the age must appear in no `refusal`, no
   `selected`, no sort key, no `--method PUT`/`PATCH`/`DELETE`, no `/merge`, no `retire-claim.sh`,
   no `release-claim.sh`, no `catch-up-claim.sh`, no `plan-units.sh`, no `git push`.
5. Assert `ask-question.sh` is **byte-identical**: the age changes no key, no cap and no hold, so
   the gate gains nothing at all.
6. **Prove the pin able to fail** before shipping it, each mode turning exactly one row red, and
   record the modes in the test's own header as the existing pin does: a value promoted to
   **proof**; a row deleted; an invented word added; a gate wired to the age in one enumerated
   consumer.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every value the reader emits is classified exactly once, and no unemitted word is classified.
- No row is a proof.
- Each enumerated consumer reaches no acting or gating call site.
- `ask-question.sh` is byte-identical.
- Each of the four failure modes was introduced and observed to turn exactly one row red.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`.
- The four breakage runs, recorded in the test's header.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes on the unmodified tree and fails on each of the
  four modes.

## Considerations

- The tempting error is to call `first_seen` a **proof**, because it is read straight off an
  append-only log that never rewrites a line — which looks like `superseded`'s property. It is
  not: the log **grows**, so `ticks` increases every hour and a bounded walk's `first_seen` can
  move as day files pass out of the bound. A proof is a reading that cannot become false by
  looking again, and this one is designed to.
- The sub-table must not be folded into the act-effect one despite both concerning the loop's own
  records: one column cannot classify two different questions, which is the rule the previous five
  splits each record.

## Final Report

Development completed as planned. A sixth sub-table in `drive/reference/claims.md`'s
*Proofs and judgements* classifies every value the reader emits, none a proof;
`testProofJudgementSplit` parses it apart from the fifth by heading and asserts both
directions, bans acting call sites in each enumerated consumer, and asserts `ask-question.sh`
byte-identical. All four failure modes were introduced and each turned exactly one row red;
they are recorded in the test's own header.

### Discovered Insights

- **Insight**: The vocabulary is parsed by RUNNING the reader over its four shapes, and the
  echo fields are dropped by comparing values rather than by a carried list.
  **Context**: `key` and `slug` are the caller's own argument and the id derived from it, not
  readings, and a hard-coded exclusion list would be the "list that proves only that it matches
  itself" the existing sub-table pins avoid. Computing `new Set([key, slugOf(key)])` PER SHAPE
  is what makes it work — a single shared key drops nothing from the shape built with a
  different one, which is how the first version failed.
- **Insight**: The tempting error is to call `first_seen` a proof, and the reason it is not is
  worth writing down.
  **Context**: It is read off an append-only log that never rewrites a line, which is
  `superseded`'s property. But the log GROWS: `ticks` rises every hour and a bounded walk's
  `first_seen` moves as day files pass out of the bound. A proof cannot become false by looking
  again; this is designed to.
