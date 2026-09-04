---
created_at: 2026-09-04T14:24:05+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: [20260904142404-gate-codex-loop-startup-on-the-first-tick.md, 20260904142405-record-each-codex-tick-outcome-and-next-due-time.md]
mission: prove-codex-loop-progress
merge_policy:
verification_handoff:
---

# Expose Codex loop status to the invoking session

## Overview

Expose the durable Codex loop reading through the same entry point an operator used to start it.
Each completed tick must surface progress or its blocked reason, and an explicit status request
must distinguish a sleeping loop from one that is moving work or has lost its report path.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / `policies/user-experience.md` — status answers the operator's question directly

## Key Files

- `scripts/codex-loop.sh` — add the status/read surface and completion summaries.
- `plugins/workaholic/skills/work/SKILL.md` — document startup, status, and completed-tick reporting.
- `plugins/workaholic/commands/work.md` — keep the thin command aligned with the skill.
- `README.md` — show how CLI and desktop operators observe the loop.

## Implementation Steps

1. Add a read-only status mode that renders the status document and names absent, stale, or
   unreadable state without starting another supervisor.
2. After each CLI tick, print a concise completion line with outcome, blocked reason, report path,
   and next due time to the invoking terminal.
3. Require the desktop Scheduled-task prompt to return the equivalent report block to its owning
   chat, using the same vocabulary rather than a desktop-only interpretation.
4. Preserve the existing Slack FB root and Implemented reply contracts; status reports describe
   their delivery and never replace or duplicate them.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- `--status` starts no process and reports the current loop state or a named absence.
- Every completed tick is visible on the invoking surface with its next due time.
- Slack proposal and implementation messages remain on their existing threads.

**Verification method** — the commands/tests/probes that prove them:

- Exercise ready, sleeping, blocked, stale, and absent status fixtures; run build and full tests.

**Gate** — what must pass before approval:

- A reader can distinguish looping, progressing, and blocked without inspecting processes.

## Considerations

An external background launch can disconnect stdout from the original terminal. The durable
status remains authoritative in that case, while issue #975 separately asks for a connector-owning
parent relay rather than pretending the child inherited Slack OAuth.

## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: `--status` must be resolved before the Codex executable check.
  **Context**: A read-only diagnosis remains available precisely when the runner binary is absent.
