---
created_at: 2026-06-23T23:53:49+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on: [20260623235347-trip-decompose-design-into-tickets.md, 20260623235348-trip-coding-phase-drive-ticket-queue.md]
---

# Converge reporting and docs on the unified ticket-centric trip model

## Overview

Once `/trip` decomposes its design into tickets (prerequisite #1) and drives them (prerequisite #2), trips produce archived tickets under `.workaholic/tickets/archive/<branch>/` — so `/report` trip-mode (which already builds its Changes section from archived tickets) becomes rich for trips automatically, no longer thin. This ticket closes the loop: link the trip story back to its rationale (the `trips/<name>/` design artifacts) so the "why" stays one click from the "what", and update `CLAUDE.md`/`README.md` to document the unified model — `/trip` and `/drive` both run on the ticket abstraction (`trips/` = rationale, `tickets/` = contract).

## Policies

The standard engineering policies — synced from qmu.co.jp into the `workaholic` policy skills — that govern this ticket. The implementing session **MUST** read each before writing.

- `workaholic:implementation` / `policies/objective-documentation.md` — `CLAUDE.md`/`README`/report prose must describe the actual new trip behavior (after #1 and #2 land), not aspirational intent.
- `workaholic:implementation` / `policies/directory-structure.md` — keep the `trips/` (rationale) vs `tickets/` (contract) split accurate in the documented architecture.

## Key Files

- `plugins/workaholic/skills/report/SKILL.md` - Trip mode: since Changes now come from archived tickets, add a step that links the story to the trip rationale (`.workaholic/trips/<name>/` design artifacts) so the narrative references the design that justified each ticket.
- `CLAUDE.md` - Document that `/trip` decomposes its design into tickets and drives them (unified with `/drive` on the ticket abstraction); update the Architecture Policy / commands description as needed.
- `README.md` - Update the development-workflow description and `/trip` explanation to the ticket-centric model.

## Related History

Completes the trip ticket-integration series begun by `20260623235347-trip-decompose-design-into-tickets.md` (emission) and `20260623235348-trip-coding-phase-drive-ticket-queue.md` (consumption).

## Implementation Steps

1. In `report/SKILL.md` trip mode, add a step that links the generated story to `.workaholic/trips/<name>/` rationale (the design artifacts), complementing the now-populated ticket-based Changes section.
2. Update `CLAUDE.md`: revise the `/trip` description and any Architecture Policy notes to reflect design → tickets → drive, and the `trips/` vs `tickets/` split.
3. Update `README.md`: the development-workflow section and the `/trip` row to the unified ticket-centric model.

## Considerations

- Documentation/convergence only; depends on #1 and #2 having landed so the prose describes real behavior (`workaholic:implementation` / objective-documentation).
- Do not duplicate the trip rationale into the story — link to it (the design artifacts remain the source of "why").
- `depends_on` both prerequisite tickets.
