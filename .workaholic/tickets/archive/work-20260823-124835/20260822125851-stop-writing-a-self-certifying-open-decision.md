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

# Stop writing a self-certifying Open Decision

## Overview

The sibling ticket makes a driving run read before it blocks. This one removes the other
half of the same defect at its source: the `## Open Decisions` item `/specificate` writes
currently *asserts its own unanswerability*. The measured item named the business owner as
the authority and told the driving session not to decide — and the answer was on the page
the ticket was about.

`/specificate` cannot ask a human, which is exactly why its Open Decision must be written
as a **question with its sources named**, not as a ruling. An unattended seam that can
declare a question closed to every later reader is a seam that can stall the loop by
writing one sentence.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/specificate/SKILL.md` — *Open decisions*, the rule that tells
  this seam to record an unrecommendable fork verbatim.
- `plugins/workaholic/skills/specificate/reference/workflow.md` — step 5 (record the
  `open_decision`) and step 9 (write it into the ticket).
- `plugins/workaholic/skills/create-ticket/reference/ticket-format.md` — the
  `## Open Decisions` section's shape, which gains the required parts.
- `plugins/workaholic/skills/discover/SKILL.md` — the discovery pass that surfaces the fork.

## Implementation Steps

1. **Read the measured item before designing anything.** Establish from
   `specificate/SKILL.md` and `reference/workflow.md` step 5 what the seam is currently
   permitted to write, and confirm that nothing requires it to name a source or to record
   that it looked.
2. Define the section's required shape in `ticket-format.md`: an Open Decision item states
   **the question**, **the sources consulted and what they said**, and **the fork's sides**.
   It may name whose ruling would settle it; it may not state that the question is
   unanswerable, and it may not instruct a later session not to decide.
3. Amend `specificate/SKILL.md` *Open decisions* and `reference/workflow.md` step 5 to
   require the history-mode discovery pass to have covered the item's own subject before an
   item is written, and to carry what it found into the item.
4. Require the whole of a cited page to have been read before an item may be written about
   a fork that page addresses — the measured failure was a partial read of one table.
5. Keep the escape hatch honest: a genuinely unrecommendable fork stays recordable. What is
   removed is the *self-certification*, not the section.
6. Update `CLAUDE.md` and any affected `rules/` document in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `ticket-format.md` states the three required parts of an Open Decision item and forbids an
  item that declares itself unresolvable or instructs a later session not to decide.
- `specificate/SKILL.md` and `reference/workflow.md` step 5 require the sources consulted to
  be named in the item.
- A genuinely unrecommendable fork is still recordable, with its sources named.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- Read-back of the three documents against the criteria above.

**Gate** — what must pass before approval:

- The three criteria hold, and the smoke tests plus the outputs freshness build are clean.

## Considerations

- The two tickets are complementary and neither is sufficient alone: this one stops new
  self-certifying items being written, the sibling stops existing ones being honoured
  unread. Drive them in this mission's order.
- `/ticket` is deliberately untouched — it resolves the same kind of fork by asking a human
  directly, so it never writes a self-certifying item.

## Final Report

Development completed as planned. `create-ticket/reference/ticket-format.md` now states the
**three required parts** of an `## Open Decisions` item — **the question**, **the sources
consulted and what they said**, and **the fork's sides** — with the item template rewritten to
carry them. An item may name whose ruling would settle it. It may **not** state that the question
is unanswerable, and it may **not** instruct a later session not to decide.

`specificate/SKILL.md`'s *Open decisions* gained rule **1b** and `reference/workflow.md` step 5
gained the matching sentence: the history-mode discovery pass must have covered the item's own
subject before the item may be written, **the whole of any page the item cites must have been
read**, and what the pass found is carried into the item as the "sources consulted" part. That
part is what turns the item from a ruling back into a question.

**The escape hatch is intact and deliberately so**: a genuinely unrecommendable fork is still
recordable, with its sources named. What is removed is the self-certification, not the section.
`/ticket` is untouched — it resolves the same kind of fork by asking a human directly in Workflow
§4b, so it never writes a self-certifying item.

**Why the parts had to be required.** The item was self-certifying: the writing seam declared a
fork unresolvable and the driving run took that declaration as evidence rather than as a claim to
check, so a fork whose answer already existed produced `blocked` on every tick forever. Measured —
a tick honoured an item whose answer sat fifty lines further down the very page the ticket named,
which is also why "read the whole of a cited page" is stated rather than left implied; on a
consuming repository the same shape ran eleven consecutive ticks for zero lines of implementation.

**This ticket and its sibling are complementary and neither is sufficient alone**: this one stops
new self-certifying items being written, the sibling stops existing ones being honoured unread.
They were driven in the mission's order.

**Verification**: `node scripts/test-workflow-scripts.mjs` — 3360 passed, 0 failed;
`build.mjs` + `verify.mjs` clean.
