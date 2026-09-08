---
created_at: 2026-09-08T14:58:46+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-agentic-loop-validation-finite-and-truthful
feedback: [20260908145807-make-validate-plugins-fail-finitely.md]
merge_policy:
verification_handoff: 
---

# Make the observation-clock fixture emit distinct activity

## Overview

Repair the activity-clock fixture so its fake provider emits a new source coordinate on the second observation. Preserve the contract that an observation-only wake may prompt the coordinator without moving the five-minute work boundary.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/tests/agentic-loop/runtime-dispatch.test.mjs` — the hanging provider fixture and anchored-clock assertion.
- `plugins/workaholic/skills/work/scripts/codex-loop.sh` — the production cadence contract the fixture exercises; change only if reproduction exposes a production defect.

## Implementation Steps

1. Reproduce the test with the same command as the `Validate Plugins` workflow and prove the last fake Codex invocation is never reached.
2. Make the QFS stub return deterministic, monotonically distinct `id` and `ts` values per observation without weakening durable deduplication.
3. Assert that exactly two coordinator invocations occur and that the second prompt is observation-only while the anchored work clock remains not due.
4. Run the test repeatedly to prove it terminates deterministically.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- The second inbound observation has a distinct durable source identity and causes exactly one observation-only coordinator wake.
- No production deduplication rule is relaxed to satisfy the fixture.

**Verification method** — the commands/tests/probes that prove them:

- Run the named test alone repeatedly, then run the complete `scripts/tests/agentic-loop/*.test.mjs` suite.

**Gate** — what must pass before approval:

- Every repetition exits without an external kill and retains the observation-only prompt assertion.

## Considerations

Changing the assertion to accept one invocation would hide the contract rather than repair the fixture. The provider must supply genuinely new source identity.
