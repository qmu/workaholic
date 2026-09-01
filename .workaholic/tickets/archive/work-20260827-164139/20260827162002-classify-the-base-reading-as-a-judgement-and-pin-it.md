---
created_at: 2026-08-27T16:20:02+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260827162001-name-the-base-s-health-in-the-driving-run-s-report.md
mission: read-whether-the-base-survived-what-the-loop-merged
merge_policy:
verification_handoff: 
---

# Classify the base reading as a judgement, and pin it

## Overview

<!-- PROPOSED. -->

This repository already draws the line this mission depends on: **a consumer may act
on a proof, and may only report or ask about a judgement** (`drive/reference/claims.md`,
*Proofs and judgements*). A red check is a judgement — a re-run can turn it green, so
it can become false by somebody looking again, which is precisely the property a proof
must not have. Nothing may act on it.

Today that classification exists only in the reasoning behind tickets 3 and 5. This
ticket writes it down where the rule already lives, and **pins it in the hermetic
suite**, so a later consumer that starts acting on a red base fails the suite rather
than shipping.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/test.md` — a test must state what it verifies

## Key Files

- `plugins/workaholic/skills/drive/reference/claims.md` — *Proofs and judgements*. The
  **one** home of the classification. Read the whole section: it explains why the table
  is prose keyed on an emitted word, and why no script gained a `proof`/`judgement`
  classifier function (a second derivation of the same fact is what it exists to prevent).
- `plugins/workaholic/skills/drive/SKILL.md` — states the rule for a driving run.
- `plugins/workaholic/skills/moderate/SKILL.md` — states it for the tick.
- `scripts/test-workflow-scripts.mjs` — where the existing proofs/judgements pin lives;
  extend that pin rather than writing a second one.

## Implementation Steps

1. Read *Proofs and judgements* in full, plus the existing pin in
   `test-workflow-scripts.mjs` that fails when the table and its two consumers disagree.
2. Decide, and state, **where** the base reading's classification lives. Recommended:
   in the same section, as its own short sub-table — the existing one is keyed on
   `resume_reason`, the claim vocabulary, and the base reading is a different vocabulary.
   One section, two keyed tables, still one home. Do not open a second document.
3. Classify all three words: `red` and `green` are **judgements** (a re-run falsifies
   either), and `unanswerable` is a judgement for the reason the section already gives —
   it is the **absence** of a reading, and acting on an absence is the failure the
   three-valued shape exists to avoid. There is no proof in this vocabulary.
4. State the consequence in `workaholic:drive` and `workaholic:moderate`: no consumer
   may revert, re-run, block, gate, hold or merge on this reading. Report it, ask about
   it, and nothing else.
5. Extend the existing hermetic pin so the suite **fails** when a consumer acts on the
   base reading. Enumerate the consumers the way the existing pin does, so a new one
   must be registered rather than slipping in unclassified.
6. Word the pin's failure message so it names the rule, not just the assertion — a
   suite failure a maintainer cannot act on is a suite failure they will delete.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- the classification lives in exactly one place, beside the existing table
- all three words are classified as judgements, each with its reason
- `workaholic:drive` and `workaholic:moderate` state that no consumer may act on it
- the hermetic suite fails if a consumer acts on the reading
- no script gains a `proof`/`judgement` classifier function, and no artifact gains a field

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — passing today, failing against a deliberately
  acting consumer introduced in the test fixture
- `grep` proves one home for the classification

**Gate** — what must pass before approval:

- the pin is demonstrated to fail, not merely asserted to
- the existing claims pin still passes untouched

## Considerations

- The tempting error is to call the reading a proof because it is read straight off
  GitHub. `awaiting_verification`'s header records exactly this trap for the claim
  vocabulary: read-straight-off looks like `superseded`'s property, but a proof is a
  reading that **cannot** become false by looking again, and a check run is designed to.
- Keep the sub-table short. Its value is that it is the one place, not that it is thorough.

## Final Report

Development completed as planned. The classification lives in **one** place —
`drive/reference/claims.md`, *Proofs and judgements* — as its own sub-table beside the claim
protocol's, exactly as the ticket recommended: one section, two keyed tables, because one column
cannot classify two different questions and a second document would be the second home the split
exists to prevent.

All four words are classified `judgement`, each with its reason: `green` and `red` because a
re-run can turn either into the other; `unattributable` because it is a reading about the walk's
reach; `unanswerable` because it is the **absence** of a reading, the reason the section already
gives. **There is no proof in this vocabulary**, which the pin asserts directly.

`workaholic:drive` (**Claims**) and `workaholic:moderate` both state the consequence: no consumer
may revert, re-run, block, gate, hold or merge on the reading.

The existing pin was **extended**, never duplicated. `testProofJudgementSplit` now splits
`claims.md` at the base sub-table's heading and parses the two vocabularies apart; the base word
set comes out of the two scripts' own `emit` calls rather than a list the test carries; and both
consumers are **enumerated by name** (the `/moderate` step by call site, the driving run by the
sentence a change would have to delete), so a third consumer must be registered rather than
slipping in unclassified. No script gained a `proof`/`judgement` classifier and no artifact gained
a field.

**The pin was demonstrated to fail, not asserted to.** Four modes were introduced and the whole
suite run against each, every one turning exactly the expected row red:

| Break | Row that went red |
| ----- | ----------------- |
| `red` promoted to `**proof**` | `no base reading is a proof — every one of them is a judgement` |
| the `unattributable` row deleted | `every word the base reading emits is classified exactly once` |
| an invented `probably_red` row added | `and the sub-table classifies no word the base reading never emits` |
| `git revert` added to `step-base-health.sh` | `step-base-health.sh acts on nothing — it never reaches git revert` (**and** the step's own test's `the step never reaches git revert`) |

The fifth mode — deleting the gates-nothing sentence from `drive/SKILL.md` — was verified against
the assertion's own regex rather than by a whole suite run, and the header says so rather than
claiming a run that did not happen. The existing claims pin passes untouched (4111 passed, 0
failed).

### Discovered Insights

- **Insight**: the original pin parsed `| \`word\` | proof|judgement |` rows out of the **whole**
  of `claims.md`, so adding any second vocabulary to that file breaks it in both directions at
  once — every new word reads as a claim word the library never emits.
  **Context**: that coupling is why the extension had to split the document at a heading before
  adding a row, and it is the mechanism that makes "one home, two tables" safe: a third
  vocabulary added without splitting fails loudly rather than silently widening the first table.

- **Insight**: the acting-call-site ban had to be written as **call sites** (`git revert`,
  `/rerun`, `merge_pull_request`), never as words.
  **Context**: `step-base-health.sh`'s own `bound` string says in English that the tick never
  re-runs a check or reverts — so a word-level ban fails on the very sentence that states the
  rule, and the stricter a consumer's own wording gets the more certainly such a test breaks.
