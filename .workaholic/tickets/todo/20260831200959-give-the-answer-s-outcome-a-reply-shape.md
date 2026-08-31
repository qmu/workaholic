---
created_at: 2026-08-31T20:09:59+09:00
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
