---
created_at: 2026-08-30T02:21:38+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-how-long-the-loop-has-been-stuck
merge_policy:
verification_handoff: 
---

# Carry the age on the undrivable-unit question

## Overview

PROPOSED. The eleven-day case that measured this mission: five queued tickets across three
missions stamped with an address the identity mapping does not name, undrivable since
2026-08-19, each asked about once — days ago — and never again by the asked-once gate. Put the
age on that question, keyed on the artifact path `step-undrivable-units.sh` already uses.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-undrivable-units.sh` — each candidate already
  carries `{artifact, owner, key, unjudged}`; the age rides beside them and `compose` names it.
- `plugins/workaholic/skills/moderate/scripts/condition-age.sh` — composed per candidate.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the step's contract.

## Implementation Steps

1. For each candidate the step already builds, call `condition-age.sh --key "$key"` — the key is
   `undrivable-unit:<rel>`, which the step composes today and which is unchanged.
2. Attach the reading to the candidate as `age: {first_seen, ticks, truncated,
   first_seen_is_floor, readable, reason}`, carrying the reader's words verbatim rather than
   normalising them: a normalised word sends a reader to a string no script printed.
3. Extend the `compose` prose so the agent names the age in the question when the reading has a
   `first_seen`, and says nothing about age when it does not. A `readable: false` reading is
   named as unreadable, **never rendered as *this just started*** — the collapse this mission
   exists to close.
4. **The step summary does not move.** Its own header records that a summary carrying an age
   marks the step changed every tick by construction, which is the retired `📦 Release
   Preparation` shape. The age rides `needs_agent` only.
5. **The key does not move**, so `already_asked` is byte-identical and no question is re-asked by
   the changed wording — the same rule the residue and the stage additions already hold.
6. The step still asks and nothing else: no reassignment, no write, no claim touched, no gate
   lifted, and `plan-units.sh` is still never reached (that survey stages what its living
   migrations converge).

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A candidate whose key the ledger carried on an earlier day gets an `age` with a `first_seen`
  and a `ticks` greater than 1; a first-time candidate gets `first_seen: null` and the composed
  question says nothing about age.
- An unreadable age is named as unreadable and never as a fresh condition.
- The step's `summary` string is byte-identical to its pre-change form for the same inputs.
- The candidate `key`s are byte-identical, so `ask-question.sh` refuses and holds exactly as
  before.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the step's existing rows plus a summary-identity row
  and an age row.
- `sh scripts/e2e/loop-drill.sh verify-condition-age` (ticket 8).

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes; the step's summary and keys unchanged.

## Considerations

- The reading is the age of the *question*, not of the condition (ticket 1's stated limit), so
  the composed wording must say how long it has been **asked about** rather than asserting how
  long the artifact has been undrivable. On this candidate the two nearly coincide, and saying
  the weaker true thing costs nothing.
- A subject held by an open ruling (`ruling-suppression.sh`) is filtered before the candidate is
  built, so no held subject gains an age it would never show.
