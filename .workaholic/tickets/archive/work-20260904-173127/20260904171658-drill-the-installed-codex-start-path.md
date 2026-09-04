---
created_at: 2026-09-04T17:16:58+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-the-codex-work-entrypoint-self-contained
merge_policy:
verification_handoff: 
---

# Drill the installed Codex start path

## Overview

Add an integration drill that installs the built full plugin into an empty consuming repository
and proves the documented Codex CLI entrypoint can launch exactly one dry-run tick.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — packaging failures become visible verdicts

## Key Files

- `scripts/build-plugins/` — assembled full-plugin fixture source.
- `scripts/e2e/` — integration drill and deliberate breaker.
- `.github/workflows/` — CI reachability for the new drill.

## Implementation Steps

1. Build or install the full plugin into a temporary isolated location.
2. Initialize an empty consuming Git repository with no Workaholic supervisor script.
3. Invoke the documented plugin-owned launcher with `--dry-run --once` and assert its command.
4. Add a breaker proving the drill fails when the packaged launcher is removed.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- The fixture launches from the installed package and fails on a missing launcher.

**Verification method** — the commands/tests/probes that prove them:

- Run the focused drill and the complete workflow script suite.

**Gate** — what must pass before approval:

- CI reaches both the positive case and a load-bearing negative assertion.

## Considerations

The fixture must not use source-tree fallback paths that hide a packaging failure.

## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: The integration fixture can copy the full plugin into an isolated install path and
  invoke its launcher directly from a separate Git repository.
  **Context**: The positive row cannot pass through source-tree fallback paths, while the breaker
  proves that removing the packaged launcher is load-bearing.
