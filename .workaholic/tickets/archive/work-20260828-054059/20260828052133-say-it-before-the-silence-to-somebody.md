---
created_at: 2026-08-28T05:21:33+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-direction-s-end-a-turn-of-the-loop-not-its-stop
merge_policy:
verification_handoff: 
---

# Say it before the silence, to somebody

## Overview

`direction-none` fires only once every direction is already closed, and it is addressed to
nobody — the loop announces its own silence after the fact, to no one. Add the reading that
fires on the **last live** direction, addressed to that direction's assignee, naming what
closing it would leave and that the loop will originate nothing after it.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-direction-health.sh` — where the question is raised
- `plugins/workaholic/skills/strategy/scripts/direction-state.sh` — where `active_count` already is
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the existing ledger and gate
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the step's contract
- `scripts/test-workflow-scripts.mjs` — the key and the asked-once gate

## Implementation Steps

1. Derive the reading from what the lifecycle reader already emits — one `active` direction —
   with no new counter and no field on any artifact.
2. Raise one question addressed to that direction's **assignee**, keyed on its slug so the
   existing asked-once gate, the per-tick cap, the quiet hours and the working-day hold all apply
   unchanged and no second ledger exists.
3. Name in the body what closing it would leave (ticket 1's reading) and that the loop originates
   nothing once no live direction remains.
4. Keep `direction-none` exactly as it is: it still fires when every direction is closed, still
   addressed to nobody.
5. Ask and nothing else — never close a direction, never propose, never lift a gate.
6. A degraded reading asks nothing and is named, as `strategy-pace` already refuses to spend a
   person's attention on our own degradation.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A repository with exactly one live direction asks its assignee once, naming the leaving
- The question is asked once across ticks, on the existing ledger
- `direction-none` is unchanged
- Nothing is closed, proposed or lifted

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-direction-health`

**Gate** — what must pass before approval:

- Two ticks produce one question
- The step still writes nothing but its own tick-log line

## Considerations

- With more than one live direction this must stay silent; a general "how many directions" report
  is the status line addressed to nobody this repository has twice retired.

## Final Report

Development completed as planned.

`direction-last:<slug>` is raised when exactly one live direction remains, addressed to that
direction's assignee, naming what closing it would leave and that the loop originates nothing
after it. It is derived from `active_count`, which the lifecycle reader already emits: no new
counter and no field on any artifact. It is silent with more than one live direction, and
silent for a direction that already has a non-`live` question this tick. `direction-none` is
byte-identical — it still fires when every direction is closed, still addressed to nobody.
Verified by `testDirectionHealthLeaving` (two ticks, one question) and by the existing
refusals pin.

### Discovered Insights

- **Insight**: the last-live reading and the `arrived`/`overdue` readings can fire on the same
  slug in the same tick.
  **Context**: one direction drawing two questions in two vocabularies is exactly the
  doubling `handoff-units` and `stalled-units` were split to avoid. The non-`live` reading
  wins, because it already puts the same direction, the same leaving and a sharper act in
  front of the same person.
