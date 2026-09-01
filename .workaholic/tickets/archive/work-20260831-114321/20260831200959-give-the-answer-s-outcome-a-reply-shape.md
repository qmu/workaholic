---
created_at: 2026-08-31T20:09:59+09:00
status: done
author: a@qmu.jp
assignees: 
depends_on:
mission: make-the-tick-s-questions-readable-and-close-them-in-the-thread
merge_policy:
verification_handoff: 
---

# Give the answer's outcome a reply shape

## Overview

The catalog says, of `question-answers`: *no reply is posted for this event, in any
thread* — a deliberate anti-restatement decision, because a reply into a thread the person
is already reading was the hourly restatement two roots were retired for. That reasoning
holds for a **restatement** and not for what is asked here: the operator answers in the
thread and the thread never says what the loop recorded or what came of it.

Reverse it narrowly and name the shape once: **one reply, after the loop has acted**,
carrying the answer as recorded and its outcome. The `:ballot_box_with_check:` reaction
keeps its own job — it says *received*, which is not *acted on*.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/notify/reference/notifications.md` — the catalog's
  `/moderate` entry, where the no-reply rule is stated and where the new shape belongs.
- `plugins/workaholic/skills/moderate/reference/workflow.md` §22 — the step whose
  *What it never does* paragraph this narrows.
- `plugins/workaholic/skills/workaholify/routines/moderate.md` — the template's copy of the
  post formats.
- `scripts/test-workflow-scripts.mjs` — the drift pin.
- `CLAUDE.md` — the `question-answers` note, updated in the same change.

## Implementation Steps

1. Write the shape into the catalog: a heading naming the question it closes, and one
   sentence carrying **the answer as recorded** and **what came of it**. No mention token —
   it closes a loop rather than demanding attention, exactly as `✅ 解消を確認` does.
2. State the narrowing that admits it, in the catalog, beside the rule it changes: it is
   posted **once**, **after the act**, and carries **facts the thread does not already
   have**. It never restates the question, never re-asks, and never fires before the
   outcome is known.
3. State what keeps its job: the reaction still stamps *received* at recording time, and
   the two are different events with different emoji — one answering both is how a reader
   stops being able to tell them apart.
4. Rewrite §22's *What it never does* so it says what is still true: it never re-asks,
   never confirms, never opens an issue except through `file-inbound-ask.sh`, never reads a
   channel — and now posts exactly one reply, after the act.
5. Update the routine template's copy byte-identically and re-run the drift pin; update
   `CLAUDE.md` in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The shape is named in exactly one place and every other surface reads it from there.
- The narrowing is stated where the rule it reverses is stated, with what still holds.
- The reaction's rule is untouched, and the two events carry different emoji.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (the routine template's copy is pinned
  byte-identical to the catalog's).

**Gate** — what must pass before approval:

- The reversal reads as a bounded exception with its bounds, not as the no-reply rule
  being dropped.

## Considerations

- The bright line this repository keeps is *a status line addressed to nobody is noise*.
  This reply is addressed to the one person who wrote the answer, in their own thread,
  exactly once — the same ground the inbound sweep's receipt and the thread reconciliation
  already stand on.
- Two replies (one at recording, one at landing) were considered and refused: the reaction
  already says *received*, so a second post before the outcome is known carries nothing new.

## Final Report

Development completed as planned.

The catalog's `/moderate` entry gains a sixth shape, `🧾 対応結果`, stated once and read from
there by the `[Moderate]` template byte-identically. The narrowing is written beside the rule it
changes — the no-reply rule was written against a **restatement**, right at the moment of
recording and wrong once something has happened — with its three bounds spelled out: once ever
per question, after the act never before, and carrying facts the thread does not already have.

Only a `settled:` reading from `answer-outcome.sh` posts; `pending` and `unreadable:<reason>`
post nothing and are reported by name. The `:ballot_box_with_check:` stamp keeps its own rule
and its own job untouched — *received* is not *acted on*, and the two events carry different
emoji so a reader can tell them apart.

`reference/workflow.md` §22's *What it never does* now says what is still true rather than what
was true: it never re-asks or confirms, never opens an issue except through
`file-inbound-ask.sh`, never adds an edit path, never reads a channel, and posts **exactly one**
reply after the act plus none at all for the recording event.

The drift pin was extended: the sixth shape must read byte-identically in both documents, carry
no mention token, and the template's authorized-shape list is now six in order.

### Discovered Insights

- **Insight**: The template's authorized-shape assertion compares an **ordered array** of every
  fenced block's first line, so a new shape has to be placed in the template at the position the
  test lists it — the pin is a total specification of the routine's Slack vocabulary, not a
  membership check.
  **Context**: That is what makes "emit only the shapes below" enforceable rather than
  aspirational: a shape added to the catalog and forgotten in the template fails, and so does
  one added to the template and never named in the catalog.

- **Insight**: The pinned sentence `post **no reply** for that event` had to survive verbatim
  while its meaning narrowed, which is what forced the scoping to be written into the sentence
  itself (`— the outcome reply below is a different event`) rather than into a paragraph
  somewhere else.
  **Context**: A pin on a literal phrase is a useful forcing function for exactly this: it makes
  a narrowing land where the rule is, instead of as a footnote a later reader never reaches.
