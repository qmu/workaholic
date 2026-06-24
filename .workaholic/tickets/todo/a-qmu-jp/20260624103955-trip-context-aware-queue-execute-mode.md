---
created_at: 2026-06-24T10:39:55+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on:
---

# Make /trip context-aware: trip-drive an existing ticket queue (ticket → trip)

## Overview

Today `/trip` is always design-first: instruction → design → decompose → drive. Make it **context-aware** like `/report` and `/ship`: at start, detect the user's todo-queue state and route.

- **Instruction present** → design-first (today's behavior): Planning → Decomposition → Coding.
- **No instruction + populated queue** → **queue-execute mode**: the three agents *share-read* the queued tickets, then the lead runs the Coding Phase's Per-Ticket Drive Loop directly over the queue — **no** Planning, **no** Decomposition. The tickets are the spec.
- **No instruction + empty queue** → nothing to do; tell the user to `/ticket` first or give an instruction.

This delivers `ticket → trip` (run a three-agent trip over an existing hand-written queue) and completes the drive/trip unification: tickets are the spine, and `/drive` and `/trip` become interchangeable **executors** over the same `todo/ → archive/` lifecycle.

## Policies

The standard engineering policies — synced from qmu.co.jp into the `workaholic` policy skills — that govern this ticket. The implementing session **MUST** read each before writing.

- `workaholic:implementation` / `policies/directory-structure.md` — queue detection reads the standard `.workaholic/tickets/todo/<user>/` location via an existing skill script; the queue-execute path reuses the same Per-Ticket Drive Loop, no parallel mechanism.
- `workaholic:implementation` / `policies/objective-documentation.md` — the protocol prose must describe the actual routing and queue-execute behavior, not aspirational intent.
- `workaholic:implementation` / `policies/coding-standards.md` — convention conformance; queue detection uses a bundled script, not inline shell in the markdown (Shell Script Principle).

## Key Files

- `plugins/workaholic/skills/trip-protocol/SKILL.md` - PRIMARY. Trip Command Procedure: add a **mode routing** step (detect queue state, branch design-first vs queue-execute vs nothing-to-do); document the **queue-execute mode** (skip Planning Steps 1–4 + Consensus/Convergence + Decomposition; share-read the queue; enter the Coding Phase Per-Ticket Drive Loop); branch the Step 4 team-lead instruction on mode; set the resumed `plan.md` step for queue-execute (`coding/concurrent-launch`).
- `plugins/workaholic/commands/trip.md` - Update the description/notice to reflect the context-aware (design vs queue-drive) behavior.
- `plugins/workaholic/skills/drive/scripts/list-todo.sh` **or** `plugins/workaholic/skills/ship/scripts/check-todo.sh` - Reused (referenced) for queue detection; pick the one whose JSON best fits and do not add inline queue logic.

## Related History

Completes the trip ticket-integration series ([301d389] Decomposition gate, [13e4f22] Coding-phase drive, [e18db4c] report/docs convergence) by making `/trip` a queue-aware executor — the missing `ticket → trip` direction.

## Implementation Steps

1. In the Trip Command Procedure, after night-mode determination, add a **mode routing** step using an existing queue-check script: instruction empty + queue non-empty → `queue-execute`; instruction present → `design-first` (current); both empty → inform the user and stop.
2. Document **queue-execute mode**: the team skips Planning (Steps 1–4), the Consensus/Convergence gate, and the Decomposition gate; all three agents share-read the queued tickets (and any Trip Origin links), then the lead runs the Coding Phase Per-Ticket Drive Loop over the queue.
3. Set `plan.md`'s starting step for queue-execute (`coding/concurrent-launch`), since the planning steps are skipped.
4. Branch the Step 4 team-lead instruction on mode (design-first vs queue-execute).
5. Update `commands/trip.md` description/notice.

## Considerations

- **Instruction + populated queue**: design-first wins (the instruction signals new design intent); its Decomposition appends to the queue and the Coding loop drives the full queue. Note this so a stray pre-existing ticket is not a surprise — recommend a fresh worktree for design-first trips (already the night/default). (`plugins/workaholic/skills/trip-protocol/SKILL.md`)
- Reuse an existing queue-detection script; never add inline queue logic to the markdown (Shell Script Principle, `CLAUDE.md`).
- Night mode: queue-execute is already fully unattended (three-agent QA, no developer prompt); for night + empty instruction + empty queue, park gracefully.
- `drive → trip` escalation is intentionally **out of scope** (deferred per design decision).
