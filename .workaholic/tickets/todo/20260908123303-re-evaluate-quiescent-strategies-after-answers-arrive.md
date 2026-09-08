---
created_at: 2026-09-08T12:33:03+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: turn-quiescent-blockers-into-mature-decisions-and-resume-work
merge_policy:
verification_handoff: 
---

# Re-evaluate quiescent strategies after answers arrive

## Overview

Make a recorded answer invalidate the terminal-looking quiescent explanation and cause the next loop turn to evaluate the strategy with that answer as new evidence.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/work/` — coordinate answer ingestion with due-role dispatch.
- `plugins/workaholic/skills/propose/` — consume resolved blocker evidence on the next survey and judgment.
- `plugins/workaholic/skills/moderate/` — settle the standing question after its answer is recorded.

## Implementation Steps

1. Trace the existing Slack answer path through feedback capture and question settlement.
2. Make settlement expose a fresh, derived input that the next propose turn can observe without a stored workflow cursor.
3. Ensure the strategy is re-evaluated while ordinary open-work and attribution brakes still apply.
4. Prove an unanswered blocker stays standing and an answered blocker permits a new move or a newly justified refusal.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- An answer settles the exact question and the next eligible loop turn re-evaluates the strategy.
- The answer does not bypass mechanical work-in-flight or attribution gates.

**Verification method** — the commands/tests/probes that prove them:

- Run end-to-end fixtures from Slack reply through feedback record to the next propose survey.

**Gate** — what must pass before approval:

- Both the resumed and still-refused outcomes name the answer evidence that changed the judgment.

## Considerations

Prefer existing records and derived state over a new mutable reopen flag.
