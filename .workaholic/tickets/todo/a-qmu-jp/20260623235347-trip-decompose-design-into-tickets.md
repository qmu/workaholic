---
created_at: 2026-06-23T23:53:47+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on:
---

# Trip Planning phase: decompose the agreed design into tickets (new Decomposition gate)

## Overview

Today a `/trip` is instruction-driven: the Planning phase converges on `designs/design-vN.md` and the Coding phase builds directly against it — no ticket is ever produced. This makes `/trip` diverge from `/drive` (which is ticket-driven) and leaves `/report` thin for trips (its Changes section is built from archived tickets, of which a trip has none).

Add a **Decomposition gate** at the end of the Planning phase: once the design is fixed (consensus/forced-convergence), the **Constructor** decomposes the agreed `design-vN.md` into N implementation tickets written to `.workaholic/tickets/todo/<user>/`, each following the standard ticket format including the mandatory `## Policies` section (propagated from the design's Policies list) and a new **Trip Origin** reference linking back to the design artifact and section that justifies it. `depends_on` ordering is derived from the design's delivery plan. These tickets are the "ticket beforehand" the build consumes. This ticket covers **emission only**; the Coding phase consumes them in the follow-up ticket.

## Policies

The standard engineering policies — synced from qmu.co.jp into the `workaholic` policy skills — that govern this ticket. The implementing session **MUST** read each before writing.

- `workaholic:implementation` / `policies/directory-structure.md` — trip-emitted tickets MUST land under `.workaholic/tickets/todo/<user>/`, never under `.workaholic/trips/` (the `create-ticket` prohibition and `validate-ticket.sh` hook enforce this); `trips/` stays the rationale home.
- `workaholic:implementation` / `policies/objective-documentation.md` — the protocol prose must describe the actual agent behavior at the new gate, not aspirational intent.
- `workaholic:implementation` / `policies/coding-standards.md` — convention conformance for the skill/agent prose edits.

## Key Files

- `plugins/workaholic/skills/trip-protocol/SKILL.md` - PRIMARY. Add the Decomposition step (new `planning/decomposition` step identifier + gate) after the Consensus/Convergence gate; update Artifact Storage to state tickets live under `tickets/`, with `trips/` holding the rationale each ticket links back to; extend the Constructor role with the decomposition responsibility.
- `plugins/workaholic/agents/constructor.md` - Add the "decompose the agreed design into tickets" responsibility to the Constructor's Planning-phase role text.
- `plugins/workaholic/skills/create-ticket/SKILL.md` - Document the **Trip Origin** link convention (a trip-emitted ticket records the originating `.workaholic/trips/<name>/designs/design-vN.md` section); reaffirm tickets are written only under `.workaholic/tickets/`.

## Related History

This builds directly on the recorded `## Policies` ticket section ([85497b3] on main, v1.0.61) — the trip design artifact already carries a Policies list described as "the trip's equivalent of a ticket's `## Policies` list", which decomposition now propagates into the emitted tickets.

## Implementation Steps

1. In `trip-protocol/SKILL.md` Planning Phase, add a Decomposition step after the Consensus Gate / Convergence Cap: the Constructor decomposes the fixed `design-vN.md` into independently-implementable tickets. **GATE**: wait for the tickets to be written and an event logged.
2. Specify, in the step, the ticket write location (`.workaholic/tickets/todo/<user>/` inside the trip `<working_dir>`), the format (standard File Structure + mandatory `## Policies` propagated from the design + a **Trip Origin** reference), and `depends_on` derived from the design's delivery plan.
3. Add `planning/decomposition` to the `plan.md` step identifier list and the Plan Document section.
4. Update the Artifact Storage section: tickets are NOT stored under `trips/`; `trips/` holds direction/model/design as rationale, and each emitted ticket links back to its design artifact.
5. Extend the Constructor role (in `trip-protocol/SKILL.md` and `agents/constructor.md`) with the decomposition responsibility.
6. Add the **Trip Origin** link convention to `create-ticket/SKILL.md`.

## Considerations

- Tickets MUST be written under `.workaholic/tickets/todo/<user>/`; `validate-ticket.sh` rejects ticket-shaped files written outside `.workaholic/tickets/`, and `create-ticket` prohibits the `trips/` tree (`plugins/workaholic/skills/create-ticket/SKILL.md`).
- This ticket adds emission only; the Coding-phase consumption (drive over the emitted tickets) is the dependent follow-up ticket.
- Night mode: decomposition must be unattended-safe — the Constructor records reasonable assumptions in the design/`plan.md` rather than asking the developer (`plugins/workaholic/skills/trip-protocol/SKILL.md` Night Mode).
