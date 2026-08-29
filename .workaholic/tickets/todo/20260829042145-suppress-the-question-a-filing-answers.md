---
created_at: 2026-08-29T04:21:45+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-the-tick-s-own-findings-become-the-loop-s-work
merge_policy:
verification_handoff: 
---

# Suppress the question a filing answers

## Overview

PROPOSED. A finding that has become work must no longer also ask a person: the same
person, in the same hour, about the same thing the loop is already driving. That is
precisely `ruling-suppression.sh`'s existing job one artifact over, so this reads
through **that shared shape** rather than a second reading — two readings of one fact
drift, which is the rule that script's own header states.

Three bounds, all inherited rather than invented: it is **keyed on the subject, never
on the existence of a filing** (a filing about one finding must not silence a question
about a different one); an **unreadable read holds nothing** (`ci-retirement-turn.sh`'s
discipline — an over-eager question beats a silently dropped one); and a
**`needs_ruling` finding still asks**, byte-identically. Every other key, cap, hold and
`ask-question.sh` itself stay untouched.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / `policies/interaction.md` — a person's attention is spent once per thing

## Key Files

- `plugins/workaholic/skills/moderate/scripts/ruling-suppression.sh` — the shared shape;
  its header states the subject-keying, the one-reader and the unreadable-holds-nothing
  rules. Read all three before touching it.
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the gate; **untouched**.
- `plugins/workaholic/skills/moderate/scripts/step-file-findings.sh` — supplies the
  filed subjects.
- `plugins/workaholic/skills/moderate/scripts/step-retire-claims.sh`,
  `step-stuck-prs.sh`, `step-merge-conflicts.sh`, `step-inbound-sweep.sh` — the steps
  whose questions a repairable filing can answer; each consults the shared reader.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the contract.

## Implementation Steps

1. Read `ruling-suppression.sh` in full, including the four boxed rules in its header.
   Decide whether the finding subjects extend its `held` map or ride a sibling reader
   composing the same source — **report which and why**; a second reader that answers
   the same question differently is the defect this is written against.
2. Derive the held set from the **filed** subjects — the ids ticket 5 keyed the issues
   on — so the suppression is derived and stored nowhere: closing the finding issue
   makes the question reachable again, exactly as closing a ruling does.
3. Wire the consulting steps to the shared reader. None of them reads the open-issue
   ledger itself.
4. Assert the invariants: a `needs_ruling` finding's question is byte-identical; a
   subject no filing names still asks; an unreadable read holds nothing and is named.
5. Leave `ask-question.sh` alone. The gate, the day cap, the per-tick cap, the quiet
   hours, the working-day hold and the one bounded re-ask do not move.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A subject a filing names draws no question; a subject it does not name still does.
- A `needs_ruling` finding's question is unchanged in key, addressee, cap and hold.
- An unreadable suppression read suppresses nothing and names its reason.

**Verification method** — the commands/tests/probes that prove them:

- Ticket 8's drill: one filed finding held, one unfiled finding still asking, in one run.
- `node scripts/test-workflow-scripts.mjs` — a pin that the suppression has one reader.

**Gate** — what must pass before approval:

- The suite is green and the drill shows the held and the still-asking subject together.

## Considerations

- The dangerous simplification is suppressing on *any* open finding issue. That is the
  bug `ruling-suppression.sh` names in its own header, and it would silence the whole
  question queue behind one filing.
- A filing and a question about the same subject in the **same** tick is the ordering
  case to think about: the agent files after `run.sh` returns, so the suppression bites
  from the next tick. Say so in the contract rather than reordering the run.
