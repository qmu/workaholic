---
created_at: 2026-06-23T23:53:48+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 1h
commit_hash: 87e4e1f
category: Changed
depends_on: [20260623235347-trip-decompose-design-into-tickets.md]
---

# Trip Coding phase: drive the emitted ticket queue with three-agent QA

## Overview

With the Planning phase now emitting implementation tickets (the Decomposition gate from the prerequisite ticket), rework the Coding phase from a monolithic build-against-design into a **trip-native drive** over the ticket queue. The lead walks the tickets in dependency order; per ticket the three-agent QA differentiation is preserved: **Constructor** implements (reading the ticket's `## Policies`) and runs internal tests → **Architect** reviews → **Planner** E2E-tests → on consensus the ticket is **archived** via the drive `archive.sh`, landing in `.workaholic/tickets/archive/<branch>/`. The three-agent QA *is* the per-ticket approval gate — no developer prompt — so it stays night-mode-safe. Convergence and rollback still apply per ticket.

## Policies

The standard engineering policies — synced from qmu.co.jp into the `workaholic` policy skills — that govern this ticket. The implementing session **MUST** read each before writing.

- `workaholic:implementation` / `policies/directory-structure.md` — archived tickets must land under `.workaholic/tickets/archive/<branch>/` (via `archive.sh`) so `/report` finds them; reuse the existing drive script rather than a parallel path.
- `workaholic:implementation` / `policies/objective-documentation.md` — the reworked Coding-phase prose must describe the actual per-ticket agent loop, not aspirational intent.
- `workaholic:implementation` / `policies/coding-standards.md` — convention conformance for the skill/agent prose edits.

## Key Files

- `plugins/workaholic/skills/trip-protocol/SKILL.md` - PRIMARY. Rework the Coding Phase (Concurrent Launch / Review and Testing / Iteration) into a per-ticket drive loop over `.workaholic/tickets/todo/<user>/`; update step identifiers (e.g. `coding/ticket-<id>` replacing the single `coding/iteration-N`); reference `archive.sh` for per-ticket archiving.
- `plugins/workaholic/agents/constructor.md`, `plugins/workaholic/agents/architect.md`, `plugins/workaholic/agents/planner.md` - Update each agent's Coding-phase QA role text to operate per ticket.
- `plugins/workaholic/skills/drive/scripts/archive.sh` - Reused (referenced, not changed) to archive each completed ticket; confirm the structured commit message it produces is acceptable for the trip context.

## Related History

Depends on the Decomposition gate (prerequisite ticket `20260623235347-trip-decompose-design-into-tickets.md`), which writes the tickets this phase consumes.

## Implementation Steps

1. Replace the monolithic Coding-phase build with a per-ticket loop over `.workaholic/tickets/todo/<user>/`, ordered by `depends_on` then severity (mirroring the drive prioritization).
2. Per ticket: Constructor implements + internal tests → **GATE**; Architect reviews → **GATE**; Planner E2E → **GATE**. On consensus, archive the ticket via `bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/archive.sh ...` and log a trip event.
3. Update step identifiers in `trip-protocol/SKILL.md` and the `plan.md` step list to a per-ticket form (`coding/ticket-<id>`), keeping `coding/concurrent-launch` for the initial dev-env/discovery setup.
4. Update the three agents' Coding-phase role text (`agents/*.md`) to the per-ticket QA loop.
5. Keep the Rollback path (2/3 majority → return to Planning) and the iteration loop, now scoped per ticket.

## Considerations

- **Commit convention reconciliation**: `archive.sh` delegates to `commit.sh` (structured five-section message), not the trip's `[Agent] ...` format. Decide and document: the per-ticket archive uses `archive.sh`'s structured commit (so the ticket lands in `tickets/archive/` for `/report`) with a trip `event-log.md` entry alongside; do not fork a second archive path (`plugins/workaholic/skills/drive/scripts/archive.sh`).
- Each archived ticket must land in `.workaholic/tickets/archive/<branch>/` so the convergence ticket's `/report` change finds them.
- Night mode: the per-ticket QA is self-governed (Architect review + Planner E2E), so it is already unattended-safe — no developer `AskUserQuestion`.
- Depends on the Decomposition gate ticket; do not start until the emission step exists.
