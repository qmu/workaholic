---
created_at: 2026-08-28T05:21:33+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-direction-s-end-a-turn-of-the-loop-not-its-stop
merge_policy:
verification_handoff: 
---

# State the leaving at the close

## Overview

`/specificate`'s *ended* route (step 9c) runs `close.sh` and publishes the pull request that
ends a direction, and says nothing about what that direction is leaving. Name the reading from
ticket 1 in the run report and in the pull-request body, so what is being left is visible in
the same pull request that ends it.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/specificate/reference/workflow.md` — step 9c and step 13's report line
- `plugins/workaholic/skills/specificate/SKILL.md` — the *ended* announcement's documented outcome
- `plugins/workaholic/skills/strategy/scripts/closing-residue.sh` — the reader (ticket 1)
- `scripts/test-workflow-scripts.mjs` — pin the route's own text

## Implementation Steps

1. In step 9c, after `close.sh` returns, read `closing-residue.sh <slug>` for the direction
   just closed.
2. Name the reading in the pull-request body composed at step 10: what it never reached, what no
   direction claimed, and its last lifecycle reading.
3. Name the same reading in step 13's one-line run report, beside the existing
   `strategy <slug> closed <achieved|abandoned>, PR left open for the operator` wording.
4. Report a **degraded** read as degraded, by its own reason, never as an empty leaving.
5. Leave the route otherwise untouched: `close.sh` stays the only writer of an end state, every
   existing refusal falls back to record-only naming it, and the pull request still never
   auto-merges.
6. Pin the step's own text in the suite so a later edit that drops the reading fails.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A close publishes a pull request whose body names the closing reading
- The run report names the same reading
- A degraded read is named as degraded, never rendered as an empty leaving
- `close.sh` is still the only writer of an end state and the pull request still does not auto-merge

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-succession` (ticket 7)

**Gate** — what must pass before approval:

- The suite's strategy-writer pin stays `["amend.sh", "close.sh", "create.sh"]`
- No refusal path gained a write

## Considerations

- The reading is evidence for the operator, never an assertion that closing is correct.
