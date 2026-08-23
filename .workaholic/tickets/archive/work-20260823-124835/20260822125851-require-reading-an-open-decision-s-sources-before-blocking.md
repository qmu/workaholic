---
created_at: 2026-08-22T12:58:51+09:00
status: done
author: a@qmu.jp
assignees: 
depends_on:
mission: make-an-open-decision-a-question-to-answer-not-a-ruling
merge_policy:
verification_handoff: 
---

# Require reading an Open Decision's sources before blocking

## Overview

`drive/reference/ticket-workflow.md` §1 already says an Open Decision item this session
cannot resolve "with reasoning it can defend" is a named blocker. What it does not say is
that the session must first **look**. A measured `/implement` tick honoured an item whose
answer was fifty lines further down the very page the ticket named, recorded the unit
`blocked` without an attempt, and ended `pending`. The failure contract's own words —
"Decide it from the evidence and the stated intent", and "if you cannot name which of
those you are missing, you are not blocked on the developer; you are declining to decide"
— were satisfied on their face, because a session can name an authority without ever
having read the sources.

The gap is that an Open Decision written by an earlier automated seam is currently
**self-certifying**: `/specificate` declares an item unresolvable and the driving run
takes that declaration as evidence rather than as a claim to check.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/reference/ticket-workflow.md` — §1 "Read and understand
  the ticket" carries the Open Decisions rule that must gain the read-first requirement.
- `plugins/workaholic/skills/drive/reference/failure-contract.md` — the `blocked` bucket
  ("a decision requiring a named human's professional judgement", ~line 21) and the
  "declining to decide" line (~line 130) that the new evidence requirement qualifies.
- `plugins/workaholic/skills/drive/SKILL.md` — the run report's contract, which must carry
  what the sources said.
- `plugins/workaholic/skills/create-ticket/reference/ticket-format.md` — the
  `## Open Decisions` section's definition, read by both seams.

## Implementation Steps

1. **Reproduce the shape before changing anything.** Take a ticket carrying an
   `## Open Decisions` item whose answer is present in a source the item names, and record
   what the current §1 rule permits: a run may block citing the item alone, with no read.
   Establish that from the text of `ticket-workflow.md` §1 and `failure-contract.md`, not
   from memory.
2. **Localize the seam.** Confirm §1 is the only place a driving run is told how to treat
   an Open Decision, and that nothing downstream re-checks it.
3. State in §1 that an Open Decision is a **question to answer, not a ruling that the
   question is unanswerable**: before a run may honour one as a blocker it must read the
   sources the item is about — the documents, files and prior decisions the item names, and
   the whole of any page it cites, not the paragraph the item quotes.
4. Require the run report (and the `blocked` finish) to **state what those sources said** —
   which were read, and why they did not answer the item. A block that cannot name a source
   it read is not a block.
5. Amend `failure-contract.md`'s "named human's professional judgement" bucket so that the
   named authority is necessary but not sufficient: the evidence of the read is what
   qualifies the unit for it.
6. Update `CLAUDE.md` and any affected `rules/` document in the same change, per this
   repository's documentation rule.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `ticket-workflow.md` §1 requires reading the item's named sources before an Open Decision
  may be honoured as a blocker.
- A `blocked` outcome reached through an Open Decision names the sources read and what they
  said; one that names none is refused by the contract's own words.
- `failure-contract.md` no longer permits "a named authority" alone to qualify a unit as
  blocked.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` (the
  reference files ship in the generated bundle)
- Read-back of §1 and the failure contract against the three criteria above.

**Gate** — what must pass before approval:

- The three criteria hold, and the smoke tests plus the outputs freshness build are clean.

## Considerations

- The requirement must not become "read everything": it is scoped to the sources the item
  itself names, plus the whole of any page it cites. An item naming no source at all is
  itself a defect — that is the sibling ticket's subject.
- This is a prose contract, not a script gate. No mechanical check can tell a real read
  from a claimed one; what it buys is that a blocked report with no sources named is
  visibly non-conformant.

## Final Report

Development completed as planned, as a prose contract in the three documents that govern the
driving run — deliberately, because no mechanical check can tell a real read from a claimed one.
What the change buys is that a blocked report naming no source is visibly non-conformant by the
contract's own words.

`drive/reference/ticket-workflow.md` §1 now states that **an Open Decision is a question to
answer, not a ruling that the question is unanswerable**, and that before a run may honour one as
a blocker it must read **the sources the item is about** — the documents, files and prior
decisions the item names, and **the whole of any page it cites**, not the paragraph the item
quotes. The requirement is scoped to exactly that: it is not "read everything", and an item naming
no source at all is a defect in the item (the sibling ticket's subject) rather than a licence to
skip the read.

`drive/SKILL.md`'s run-report contract and the `blocked` finish now require the sources read and
what they said. **A block that cannot name a source it read is not a block.**

`drive/reference/failure-contract.md`'s external-blocker bucket now says a named authority is
**necessary and not sufficient**: naming who must decide is free — a session can do it without
ever having looked — so what qualifies a unit for that bucket is the evidence of the read. The
"declining to decide" line gained its matching clause: a written Open Decision does not lift it,
because an item an earlier automated seam declared unresolvable is a claim to check rather than
evidence to cite.

**The measured shape.** An `/implement` tick honoured an item whose answer sat fifty lines further
down the very page the ticket named, recorded the unit `blocked` without an attempt, and ended
`pending`. On a consuming repository the same shape ran **eleven consecutive ticks** for zero
lines of implementation while the operator's own answer sat unread in the same tree. Both were
conformant with the old text, which is why the text moved rather than the runs being blamed.

**Verification**: `node scripts/test-workflow-scripts.mjs` — 3360 passed, 0 failed;
`build.mjs` + `verify.mjs` clean (the reference files ship in the generated bundle).
