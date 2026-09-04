---
created_at: 2026-09-04T14:24:04+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: [20260904142404-reproduce-and-classify-codex-loop-readiness-failures.md]
mission: prove-codex-loop-progress
merge_policy:
verification_handoff:
---

# Gate Codex loop startup on the first tick

## Overview

Make the first completed tick, rather than the supervisor PID, the Codex loop's readiness gate.
The start path must report whether `/implement` could run, what `/propose` decided, and whether a
report transport exists before it claims the loop is ready.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/runtime-behavior.md` — startup reflects the running system's state

## Key Files

- `scripts/codex-loop.sh` — run and evaluate the first tick before entering the sleep loop.
- `plugins/workaholic/skills/work/SKILL.md` — state what readiness means on each Codex surface.
- `scripts/test-workflow-scripts.mjs` — pin successful and refused startup paths.

## Implementation Steps

1. Compose the readiness reader from the verdicts localized by the preceding ticket.
2. Run one tick synchronously at startup and evaluate its exit status and structured report before
   printing a ready result or scheduling another tick.
3. Refuse readiness by name when the tick failed, no report was produced, or the required report
   transport is absent; preserve the transcript for diagnosis.
4. Keep later tick failures non-destructive to the supervisor, but report each one under the same
   vocabulary rather than the current generic stderr sentence.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A supervisor cannot report ready until its first tick completed and was evaluated.
- Every refused start names whether execution, report production, or transport caused it.

**Verification method** — the commands/tests/probes that prove them:

- Stub each first-tick outcome and run the full workflow script suite.

**Gate** — what must pass before approval:

- No PID- or lock-only condition is sufficient evidence of readiness.

## Considerations

The desktop Scheduled-task path has no long-lived supervisor; its invocation result is its startup
evidence. Keep that path distinct while sharing the tick-result vocabulary.
