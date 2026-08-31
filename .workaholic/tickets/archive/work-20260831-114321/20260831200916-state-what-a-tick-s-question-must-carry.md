---
created_at: 2026-08-31T20:09:16+09:00
status: done
author: a@qmu.jp
assignees: 
depends_on:
mission: make-the-tick-s-questions-readable-and-close-them-in-the-thread
merge_policy:
verification_handoff: 
---

# State what a tick's question must carry

## Overview

The catalog fixes the question's **shape** — `🙋 <@U…> - <what this tick could not
decide>`, one sentence, max 25 words — and says nothing about what that sentence must
**contain**. Each step composes its own wording (the script gates, the agent composes),
so a question opens with whatever identifier the step happens to hold: a unit id, an
artifact path, a claim verdict, a strategy slug. The operator reads it on Slack with
nothing else in front of them and cannot tell what happened or what is being asked.

This states the composition contract in `workaholic:notify`'s catalog — the one home for
a post shape — so every step reads it from there instead of each session inventing a
voice. Wording only: no key, cap, hold or gate moves.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/notify/reference/notifications.md` — the catalog's
  `/moderate` entry; the shape block the contract sits beside.
- `plugins/workaholic/skills/notify/SKILL.md` — if it restates the shape, it reads the
  contract from the catalog rather than repeating it.
- `plugins/workaholic/skills/moderate/SKILL.md` — the tick's own statement of its voice.
- `plugins/workaholic/skills/workaholify/routines/moderate.md` — the routine template's
  byte-identical copy of the post formats.
- `scripts/test-workflow-scripts.mjs` — the drift pin over those copies.
- `CLAUDE.md` — the `/moderate` posting paragraph, updated in the same change.

## Implementation Steps

1. Read the catalog's `/moderate` entry and every step's question spec in
   `skills/moderate/reference/workflow.md`, and list what each question leads with today
   (the identifier, the verdict word, the age, the plain fact). That list is the evidence
   the contract is written against.
2. Write the contract into the catalog beside the existing shape block: the heading leads
   with **what happened, in words a reader outside the repository understands**, and names
   the identifier after it, never before; the body names **the one act asked of the
   reader**; a verdict word, dedup key or step id never appears without the plain fact
   beside it.
3. State the bound explicitly: the ≤25-word body is a **ceiling, not a target**, and the
   repair is self-containment rather than more text — a question that needs a paragraph is
   a question aimed at the wrong reader.
4. State what does not move: `ask-question.sh`, every question key, the per-tick cap, the
   daily bound, the quiet-hours and working-day holds, and the addressee of each question.
   Changing a body **never re-asks** — `already_asked` keys on the step id derived from the
   key, never on the text.
5. Keep the pinned copies byte-identical: update the `[Moderate]` template and
   `workaholic:moderate` only where they restate the shape, and re-run the drift pin.
6. Update `CLAUDE.md` in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The contract is stated in exactly one place, in `notify/reference/notifications.md`,
  beside the shape it constrains.
- No second copy of it exists: any other surface refers to it rather than restating it.
- No question key, cap, hold, addressee or gate expression is touched by this ticket.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (the post-format drift pin over the routine
  templates).
- `git diff` shows no change under `skills/moderate/scripts/`.

**Gate** — what must pass before approval:

- The contract is written as a rule a composing session can apply, not as advice: each
  clause names what to lead with, what to put where, and what never appears alone.

## Considerations

- The catalog is prose a session reads, not a script gate: nothing mechanical can tell a
  self-explanatory question from a cryptic one. What this buys is that a question leading
  with an identifier is visibly non-conformant — the same enforcement the connector retry
  and the Open Decisions floor already rest on.
- The ≤25-word bound is deliberately not raised. The measured failure is a question that
  says the wrong things, not one that says too few.

## Final Report

Development completed as planned.

The composition contract is stated in exactly one place — `notify/reference/notifications.md`,
immediately beside the `🙋 <@U…>` shape block it constrains — as five numbered clauses (lead with
what happened; the identifier after it; a verdict word never alone; the body names the one act;
the named details keep riding the heading), plus the ceiling-not-a-target rule and an explicit
statement of what does not move.

`workaholic:moderate`'s own paragraph, which carried a partial three-part version since
2026-08-26, now **refers** to the catalog rather than restating it — the second copy is removed,
not added to. The `[Moderate]` routine template needed no change: it copies the fenced shape
block, which is byte-identical, and the contract is prose beside it rather than inside it.

### Discovered Insights

- **Insight**: The evidence the contract is written against is the identifier each step happens
  to hold, not a style preference — `undrivable-unit:<path>`, `stalled-unit:<unit>`,
  `retire-blocked:<unit>:<word>`, `base-red:<commit>`, `direction-*:<slug>`,
  `operator-pull:<number>`, `catchup-blocked:<unit>`, `raced-unit:<unit>`,
  `handoff-unit:<unit>`, `undelivered-unit:<unit>`. A step composes from what it has in hand, so
  without a stated rule the key's own shape leaks into the post every time.
  **Context**: This is why the contract's clause 2 is "the identifier after it, never before"
  rather than "no identifier": the identifier is how the reader finds the thing, and removing it
  would make the question unanswerable in a different way.

- **Insight**: The drift pin extracts the fenced block by a leading-string regex
  (`scripts/test-workflow-scripts.mjs`, `block(body, lead)`), and separately asserts that the
  template authorizes exactly five shapes by listing every fence's first line.
  **Context**: Prose added *around* a shape block is invisible to both assertions, so a
  contract like this one can be stated beside the shape without touching the byte-identical
  template copy. Anything added *inside* a fence would have failed the five-shape list.
