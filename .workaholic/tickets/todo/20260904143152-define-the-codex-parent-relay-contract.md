---
created_at: 2026-09-04T14:31:52+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: prove-codex-loop-progress
merge_policy:
verification_handoff:
---

# Define the Codex parent relay contract

## Overview

Issue #975 reports a session-boundary failure, not a second Slack authentication problem: the
main Codex conversation owns the connector, while the separately launched worker cannot inherit
it. Reproduce that boundary and define the closed relay protocol by which a worker asks its
owning conversation to read or write Slack and returns a tick outcome without claiming delivery.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:safety` / `policies/access-control.md` — authentication remains with its owning session
- `workaholic:operation` / `policies/observability.md` — relay acceptance and failure are inspectable

## Key Files

- `plugins/workaholic/skills/work/SKILL.md` — the tick contract and Codex substitutions.
- `plugins/workaholic/skills/notify/SKILL.md` — the authoritative lookup, shape, identity, and outcome rules.
- `plugins/workaholic/skills/work/reference/other-agents.md` — the measured Codex session boundary.
- `scripts/test-workflow-scripts.mjs` — hermetic contract and compatibility coverage.

## Implementation Steps

1. Reproduce a connector-owning parent with a connector-less worker and prove that launching a
   nested `codex exec` cannot transfer connector authority.
2. Define a versioned, closed result envelope containing tick identity, ordered Slack intents,
   operation kind, exact lookup inputs or thread coordinate, post shape, and tick outcome.
3. Define the corresponding parent acknowledgements for delivered, refused, unresolved, absent
   parent, and malformed intent, including stable idempotency keys for retries.
4. State that the envelope carries intent and evidence only: it never carries OAuth material,
   never authorizes a new post shape, and never converts requested delivery into delivered.
5. Pin the schema and rejection cases in fixtures before either side begins executing it.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- The contract represents every Slack act currently allowed by `workaholic:notify` without credentials.
- Unknown versions, malformed operations, and missing acknowledgements fail closed and visibly.

**Verification method** — the commands/tests/probes that prove them:

- Exercise serialized fixtures through the contract parser and run `node scripts/test-workflow-scripts.mjs`.

**Gate** — what must pass before approval:

- Both sides can be implemented independently from one documented, fixture-backed protocol.

## Considerations

Do not invent a second thread resolver. The parent still applies the existing exact-string,
private-inclusive lookup and notification ceiling; the relay merely crosses the ownership boundary.
