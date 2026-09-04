---
created_at: 2026-09-03T05:37:12+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: emit-a-mission-only-when-there-is-a-mid-term-plan-to-hold
merge_policy:
verification_handoff: 
---

# State what a mission must be able to hold

## Overview

The scale is written today as a size: *roughly 7–8 tickets, the ruled scale*. That is a number
to hit, so a small ask is inflated to reach it and a genuinely mid-term programme gets no more
room than a one-line chat message. Measured: 52% of the corpus sits at exactly seven or eight,
which is that wording printed straight into the distribution. The operator asked for the scale
to be expressed as **what the container must be able to hold**.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/propose/SKILL.md` — *The unit is a mission, not a change*, where
  the 7–8 wording lives.
- `plugins/workaholic/commands/propose.md` — the ceiling's copy of it.
- `plugins/workaholic/skills/specificate/SKILL.md` — *A strategy is not a mission factory*, the
  second copy.
- `plugins/workaholic/rules/workaholic.md` — where a rule belongs when it is cited rather than
  restated.
- `CLAUDE.md` — *The ticket spine*, the third copy.

## Implementation Steps

1. Write the rule **once**, in `rules/workaholic.md`, in the operator's own terms: a mission is
   the mid-term container between a strategy and a ticket — an artifact with room to plan and
   allocate tickets across a period. Quote the operator's words where they carry the meaning.
2. State rule 2 in that same place as a **position**, not a threshold: many two- and
   three-ticket missions is a defect the loop refuses, not a size it may choose. Say what the
   loop does about it (refuse to emit one) and what it does not (rewrite existing ones).
3. Replace each surface's 7–8 wording with a citation of that rule. A number may remain as an
   *observation about typical size*, never as the criterion.
4. Say plainly what the criterion now is: is there a mid-term plan here — several tickets
   wanting ordering and allocation across a period? A judgement, arguable by a reader.
5. Keep the two-ticket floor exactly where it is: rule 1 is checkable and stays a gate, while
   rule 2 is a judgement and must not become a second threshold.

## Quality Gate


**Acceptance criteria** — the checkable conditions that must hold:

- The rule appears once in `rules/workaholic.md` and every other surface cites it.
- No surface states a ticket count as the criterion for emitting a mission.
- Rule 1 remains a mechanical floor and rule 2 remains a stated judgement.

**Verification method** — the commands/tests/probes that prove them:

- A grep for the 7–8 wording across `plugins/`, `CLAUDE.md` and `README.md`.
- `node scripts/test-workflow-scripts.mjs`.

**Gate** — what must pass before approval:

- Rule 2 has not become a numeric gate.

## Considerations

- Turning rule 2 into a threshold would be the same mistake one layer over: a number nobody can
  defend, refusing missions that are correctly small for their plan.
