---
created_at: 2026-09-03T05:37:12+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: emit-a-mission-only-when-there-is-a-mid-term-plan-to-hold
merge_policy:
verification_handoff: 
---

# Floor a mission at two tickets at every seam

## Overview

The operator's rule 1 — a mission must have two or more tickets, and one with a single ticket
cannot be made — holds today at exactly one seam. `mission/scripts/check-floor.sh` runs at
`/specificate`'s publish seam, and `open-proposal.sh` floors a *proposal* at two with
`under_planned`. Nothing floors a mission after that: `/mission`'s creation path, a replan, and
any hand-written mission reach no floor at all. Measured: one mission on disk carries a single
ticket, which rule 1 says cannot exist.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/mission/scripts/check-floor.sh` — the existing floor and the one
  derivation of the number; every seam must read it rather than spell `2`.
- `plugins/workaholic/skills/mission/scripts/create.sh` — the interrogation path's writer.
- `plugins/workaholic/commands/mission.md` — `/mission`'s Creation Interrogation, which
  publishes a mission plus its whole ticket set.
- `plugins/workaholic/hooks/validate-mission.sh` — the write-time floor, and the reason a hook
  alone cannot carry this one.
- `plugins/workaholic/skills/specificate/reference/workflow.md` — step 9's existing call.

## Implementation Steps

1. Enumerate every seam that can put a mission into `missions/active/` with its ticket set:
   `/specificate`'s publish seam, `/mission`'s creation interrogation, `/mission`'s replan, and
   any other writer the enumeration finds. Record the list — the ticket is judged on it being
   complete, not on the first two.
2. Read `check-floor.sh` from each of them. The number lives in that script and nowhere else;
   a second seam spelling `2` is the drift this ticket exists to prevent.
3. Refuse rather than warn: a seam that would publish a mission below the floor reports the
   script's own `alternative` (a loose ticket, or the record) and writes no mission.
4. **Do not put the count in `validate-mission.sh`.** A write-time hook fires when the mission
   file is written, which is before its tickets exist, so counting there would refuse every
   legitimate mission. State that in the hook's own header so the next reader does not try.
5. Add a hermetic case per seam in `scripts/test-workflow-scripts.mjs`.

## Quality Gate


**Acceptance criteria** — the checkable conditions that must hold:

- Every seam that can create a mission reads `check-floor.sh`, and none spells the number itself.
- A one-ticket mission is refused at each of them, with the alternative named.
- `validate-mission.sh` is unchanged, and its header says why.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` with one case per enumerated seam.
- A grep proving no call site spells the floor number.

**Gate** — what must pass before approval:

- The seam enumeration is recorded in the ticket's result, not just asserted.

## Considerations

- A mission whose tickets are added over time legitimately passes through a one-ticket moment.
  The floor is on **publication**, not on the artifact's whole life; getting that wrong would
  refuse a replan that is adding its second ticket.
