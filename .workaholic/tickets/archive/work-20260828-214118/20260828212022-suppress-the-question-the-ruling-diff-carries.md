---
created_at: 2026-08-28T21:20:22+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: put-the-loop-s-standing-rulings-on-one-pull-request
merge_policy:
verification_handoff: 
---

# Suppress the question the ruling diff carries

## Overview

PROPOSED. Once a ruling diff names a subject, the hourly question about that subject is
asking the operator to do by hand what the pull request already proposes. Hold exactly
that question and nothing else — an undecidable subject still asks, and says why.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-undrivable-units.sh` — its
  `undrivable-unit:<path>` question is held for a subject a ruling names
- `plugins/workaholic/skills/moderate/scripts/step-direction-health.sh` — its
  `direction-arrived:<slug>` question likewise
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the gate; **unchanged**
- `plugins/workaholic/skills/drive/scripts/ci-retirement-turn.sh` — the precedent for a
  narrowing that suppresses a question an act is about to take, and only that one

## Implementation Steps

1. While an open ruling pull request **names a subject**, hold that subject's
   `undrivable-unit:<artifact path>` or `direction-arrived:<slug>` question — the diff
   already carries the ask, and a question beside it sends the person to perform by hand
   what they are being asked to merge.
2. **Only that one.** Every other question, the `asked-once` gate, `max_per_tick`,
   `day_cap`, the quiet hours and the working-day hold are **byte-identical**; nothing here
   touches `ask-question.sh`.
3. A subject the run left **`undecided`** still draws its question, and the question names
   **why the loop could not judge it** — otherwise an undecidable subject would go silent
   for the one reason that most needs a person.
4. Follow `ci-retirement-turn.sh`'s discipline on failure: an unreadable ruling-pull-request
   read leaves the question exactly where it was, because an over-eager question is better
   than a silently dropped one.
5. Once the ruling pull request is merged or closed, the subject stops being named and the
   question is reachable again with no state anywhere — the suppression is derived, never
   stored.
6. Cover in the suite: a named subject's question is held; every other question is
   unchanged; an `undecided` subject still asks; a closed ruling restores the question.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A subject an open ruling names draws no `undrivable-unit` / `direction-arrived` question.
- Every other question, key, cap and hold is byte-identical.
- An `undecided` subject still draws its question and names why it was undecidable.
- An unreadable read suppresses nothing.
- The suppression is stored nowhere.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- A byte-for-byte diff of the tick's question set with and without an open ruling, over one
  fixture.

**Gate** — what must pass before approval:

- `ask-question.sh` is unmodified in the diff.

## Considerations

- The risk is over-suppression: a ruling naming one mission must not silence the question
  about a different one. Keying the hold on the **subject** rather than on the existence of
  an open ruling is what bounds it, and the drill should prove exactly that.

## Final Report

Development completed as planned.

`moderate/scripts/ruling-suppression.sh` composes `list-open-rulings.sh` into one answer both
steps read — one reader, so `undrivable-units` and `direction-health` cannot disagree about
which subjects a diff already asks for. `undrivable-units` holds and **counts** a candidate
whose owner address an open ruling names; `direction-health` holds an `arrived` reading only
when an open ruling names **every** mission in that direction's residue. `ask-question.sh` is
unmodified in the diff; every other question, key, cap and hold is byte-identical. An
unreadable read suppresses nothing, and the suppression is stored nowhere.

### Discovered Insights

- **Insight**: the two questions are keyed on different things from what a ruling names — the
  mapping question on an artifact **path** (its owner is the address), the arrival question on
  a **strategy** slug (its residue holds the missions). So the hold is by *subject membership*
  in each case rather than by key equality, and for the arrival it must be **all-or-nothing**
  over the residue: holding on partial cover would drop the missions the ruling omits, which
  is the over-suppression the ticket names as the risk.
  **Context**: this is why one shared reader answers *which subjects*, not *which keys*.
- **Insight**: `overdue` and `dormant` are never held, and that is not an omission — they are
  about the **date** and the **silence**, which no attribution ruling answers. Only `arrived`
  exists to name the residue, so only `arrived` can be made redundant by a ruling.
  **Context**: a later reader might otherwise "complete" the suppression across all readings.
