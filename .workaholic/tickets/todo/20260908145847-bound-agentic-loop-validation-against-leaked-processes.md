---
created_at: 2026-09-08T14:58:47+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-agentic-loop-validation-finite-and-truthful
feedback: [20260908145807-make-validate-plugins-fail-finitely.md]
merge_policy:
verification_handoff: 
---

# Bound agentic-loop validation against leaked processes

## Overview

Bound the process-owning test and the GitHub Actions step so a future leaked handle or non-terminating supervisor becomes a finite, visible failure rather than a permanently pending repository gate.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/tests/agentic-loop/runtime-dispatch.test.mjs` — owns the intentionally long-running supervisor fixture.
- `.github/workflows/validate-plugins.yml` — owns the merge-gating agentic-loop command.

## Implementation Steps

1. Add an explicit `spawnSync` timeout to the supervisor fixture and assert that it ended through the intended signal rather than by timeout.
2. Wrap the workflow's agentic-loop suite in a documented finite timeout that is comfortably above measured healthy duration.
3. Preserve test output on timeout so the last completed contract and the bounded failure are visible in Actions.
4. Verify both the healthy suite and a controlled non-terminating command reach finite outcomes.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A leaked supervisor cannot keep the Node test worker or `Validate Plugins` job running without a deadline.
- Healthy agentic-loop tests complete well inside the CI bound.

**Verification method** — the commands/tests/probes that prove them:

- Run the complete agentic-loop suite and a shell-level timeout probe that confirms the workflow command's exit semantics.

**Gate** — what must pass before approval:

- The healthy command exits zero; the controlled hang exits with the documented timeout status and leaves no child process.

## Considerations

The bound must protect the repository without becoming a flaky performance threshold. Use a process-level bound for the small fixture and a much wider CI backstop for the whole suite.
