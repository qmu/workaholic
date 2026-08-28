---
created_at: 2026-08-28T05:21:33+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-direction-s-end-a-turn-of-the-loop-not-its-stop
merge_policy:
verification_handoff: 
---

# Ask about the leaving before the close

## Overview

`/moderate`'s `direction-health` step already asks `direction-arrived:<slug>` and
`direction-overdue:<slug>`. It asks before the operator decides, which is exactly where the
leaving is useful — after the close it is a post-mortem. Render the leaving beside those
questions, carried from the survey row rather than re-read in the step.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-direction-health.sh` — the step that asks
- `plugins/workaholic/skills/strategy/scripts/direction-state.sh` — carries the reading onto the row
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the step's contract
- `scripts/test-workflow-scripts.mjs` — the asked-once gate and the carried-not-re-read rule

## Implementation Steps

1. Carry the closing reading onto the survey row through `direction-state.sh`, the same way the
   residue is already carried — the step **never** reads `closing-residue.sh` itself, because two
   readings of one fact drift.
2. Render the leaving in the body of the `direction-arrived:<slug>` and
   `direction-overdue:<slug>` questions.
3. Bound the render as the residue's already is: name a few, then `and N more`, never a silent
   truncation.
4. A **degraded** reading yields no leaving in the body and is reported as degraded; it never
   suppresses the question that would have been asked anyway.
5. Leave the keys, the asked-once gate, the addressee and the per-tick cap exactly where they
   are — changing a body must not re-ask a question, since the ledger keys on the step id.
6. Pin in the suite that the step reaches no writer and does not read the composed reader itself.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The `arrived` and `overdue` question bodies name what the direction would be leaving
- The keys, the asked-once gate, the addressee and the cap are byte-identical
- A degraded reading is reported as degraded and asks the same question without the leaving
- The step reaches no writer of the strategy artifact

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-direction-health`

**Gate** — what must pass before approval:

- Two ticks over one unchanged reading ask exactly one question
- The step still writes nothing but its own tick-log line

## Considerations

- A longer question body must not become a status report; the leaving is the evidence for one
  decision, bounded and linked.
