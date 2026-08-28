---
created_at: 2026-08-28T21:20:22+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: put-the-loop-s-standing-rulings-on-one-pull-request
merge_policy:
verification_handoff: 
---

# Let the run supply the judgement per candidate

## Overview

PROPOSED. No script can read an Aim and rule which direction a mission answers, or read a
git history and rule which account an address belongs to. The run can. Give the reader the
seam `survey-strategies.sh --aim-kind` already established — the run hands in its answer
per candidate — and refuse, mechanically, to let any script invent one.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/list-standing-rulings.sh` — gains the
  judgement seam
- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — the shape to copy
  (`--aim-kind`): the run passes in a judgement no script can make
- `scripts/test-workflow-scripts.mjs` — pins that an unjudged candidate is never written

## Implementation Steps

1. Add a judgement input to `list-standing-rulings.sh` in `--aim-kind`'s shape — the run
   supplies, per candidate subject, its answer (a strategy slug for an `attribution`, a
   GitHub login for an `identity_mapping`). Absent the input the reader's output is
   **byte-identical** to what the previous ticket shipped.
2. **No script may invent a judgement.** Which direction a mission answers and which
   account an address belongs to are readings only a person or a run can make; the reader
   composes readings and stores an answer it was handed, and derives none.
3. A candidate with no answer is reported **`undecided`** and is **never written** by any
   later ticket in this mission.
4. A judgement naming a subject the reader did not surface is **refused**, not accepted —
   the reader's own candidate set is the domain, and an answer outside it means the run and
   the tree disagree about what is standing.
5. Report the refusal by name (`subject_not_surfaced: <subject>`) so a run that judged
   something stale can see why nothing was drafted.
6. Cover in the suite: an unjudged candidate stays `undecided`; an out-of-domain judgement
   is refused; absent the input the output is unchanged byte for byte.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Absent the judgement input, output is byte-identical to the previous ticket's.
- An unjudged candidate reads `undecided` and reaches no writer.
- A judgement naming an unsurfaced subject is refused by name; nothing is written.
- No script derives an attribution or a mapping on its own.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- A byte-for-byte diff of the reader's output with and without an empty judgement input.

**Gate** — what must pass before approval:

- A breaker: wiring any inference into the reader must fail the suite.

## Considerations

- Refused alternative: letting the script guess an attribution from title similarity. That
  is exactly what `carry-attribution.sh`'s header forbids — a machine only ever *carries* a
  ruling, never authors one — and the whole mission rests on that premise.
