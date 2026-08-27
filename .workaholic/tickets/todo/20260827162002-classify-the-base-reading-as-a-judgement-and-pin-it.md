---
created_at: 2026-08-27T16:20:02+00:00
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
