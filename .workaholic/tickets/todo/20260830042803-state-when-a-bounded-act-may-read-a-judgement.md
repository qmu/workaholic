---
created_at: 2026-08-30T04:28:03+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: catch-a-reported-claim-up-before-its-conflict-hardens
merge_policy:
verification_handoff: 
---

# State when a bounded act may read a judgement

## Overview

PROPOSED. `drive/reference/claims.md` says a consumer may **act** on a proof and may
only **report** or **ask about** a judgement — and every `mergeability` value is
classified there as a judgement. Yet `catch-up-claim.sh` reads `mechanical` and acts
on it. The exception is real and correct, made safe by re-deriving the judgement at
the moment of the act over a write that is bounded, idempotent and reversible.

**Discovery found it half-written already.** The `mechanical` row itself says *"a
consumer may act only through `catch-up-claim.sh`, which re-derives this and applies
its own six refusals; nothing acts on the word itself."* What is missing is the
**general rule** — one row cannot govern a fourth act somebody adds next month — the
**enumeration of consumers**, and the **pin**. Write the rule; do not duplicate the
row.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/reference/claims.md` — the home the two keyed
  tables already share; the new section goes beside them, and the `mechanical` row
  (currently the only place the exception is stated) points at it rather than
  repeating it
- `scripts/test-workflow-scripts.mjs` — where the existing proofs-and-judgements
  tables are already pinned in both directions

## Implementation Steps

1. Read the whole of `claims.md`'s *Proofs and judgements* section and its
   sub-tables before writing, so the new section composes with them rather than
   restating them.
2. Add one section: **an act may read a judgement only when it re-derives that
   judgement at the moment of the act, is idempotent, is reversible, and refuses
   every bound by its own word** — with the consumers **enumerated by name**.
3. Narrow the `mechanical` row to point at the new section instead of carrying its
   own copy of the rule, so the rule has one home.
4. Pin it in `scripts/test-workflow-scripts.mjs` **in both directions**: a consumer
   that acts on a judgement and is not enumerated fails; an enumerated consumer that
   stops re-deriving fails.
5. Update `CLAUDE.md` in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The rule appears once, in `claims.md`, with its consumers enumerated
- The suite fails when a consumer acts unenumerated, and when an enumerated one
  stops re-deriving
- No verdict word is added anywhere and no script's behaviour changes

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- The two breakers applied in turn, each shown red, then reverted

**Gate** — what must pass before approval:

- `git diff` touches only `claims.md`, the suite, and `CLAUDE.md`

## Considerations

- This ticket is first in the order deliberately: the widening in tickets 2–4 is
  exactly the kind of change the rule exists to bound, so the rule should be written
  before it is exercised rather than back-filled to describe what shipped.
