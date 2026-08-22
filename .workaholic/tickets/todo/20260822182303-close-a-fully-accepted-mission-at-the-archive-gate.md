---
created_at: 2026-08-22T18:23:03+09:00
author: a@qmu.jp
assignees: 
depends_on:
mission: close-a-mission-the-run-can-prove-is-finished
merge_policy:
verification_handoff: 
---

# Close a fully-accepted mission at the archive gate

## Overview

`archive.sh` already reaches into the mission on every archived ticket: it calls
`append-changelog.sh` for the `ticket archived` event and `tick-acceptance.sh` for the item that
ticket satisfies, both idempotent. It is the one place in the run that knows a mission just moved,
and it stops one step short of knowing it is finished.

The standing rule — `close.sh` is the only sanctioned writer of an end state, and nothing in the
unified run calls it — was written for a real reason: `achieved` / `abandoned` / `carried` are
three different assertions, and a run that just merged its own work is a poor judge of which
applies. This ticket does not weaken that. It notices that **exactly one** of the three is
arithmetic: a mission whose acceptance is fully checked, whose ticket queue is empty and which has
no unlinked items is `achieved` by computation, not by judgement, and the run computed both facts
before it finished.

Everything else stays the operator's. `abandoned` and `carried` assert something about *intent*;
this asserts only completion.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/archive.sh` — the seam; already calls the two
  idempotent mission mutators (~lines 222-260). Read its header before adding a third call.
- `plugins/workaholic/skills/mission/scripts/close.sh` — the only writer of an end state; its
  header states why the three outcomes are not interchangeable.
- `plugins/workaholic/skills/mission/scripts/progress.sh` — `checked`/`total`/`unlinked`, the
  arithmetic half of the proof.
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — where a queued ticket is counted, so
  the emptiness half is read through an existing reader rather than a new grep.
- `plugins/workaholic/skills/drive/SKILL.md` §7 and `reference/routing.md` — the run report, which
  must carry the close.
- `plugins/workaholic/skills/mission/SKILL.md`, `CLAUDE.md` — both state that nothing in the run
  closes a mission; both move in the same commit.

## Implementation Steps

1. **Reproduce before designing.** Drive a mission to its last ticket and confirm from the scripts
   that `archive.sh` ticks the final acceptance item and stops, leaving `status: active`. Confirm
   the run report says nothing about it.
2. **Localize.** Establish that `archive.sh` is the only place the run learns a mission advanced,
   and that `close.sh` is reachable from there the way the other two mutators are.
3. Define the proof, and make every part of it come from an existing reader: `progress.sh` gives
   `checked == total` and `unlinked == 0`; the queue emptiness is read the way the survey reads it.
   A mission failing any part is untouched — no partial credit, no heuristic.
4. Call `close.sh <slug> achieved` when and only when the proof holds. Never `abandoned`, never
   `carried`, and never a status written directly — the single-writer rule does not move.
5. Make it idempotent and safe to repeat, as the other two mutators are: a mission already ended
   is a no-op, not an error.
6. Report the close in the run report as its own outcome, and report a refusal from `close.sh` by
   name rather than swallowing it — a mission that could not be closed must not read as one that
   was.
7. Update `mission/SKILL.md`, `drive/SKILL.md`, `reference/routing.md` and `CLAUDE.md` in the same
   commit; all four currently state that the run never closes a mission.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Archiving the last ticket of a fully-accepted mission with an empty queue ends it `achieved`,
  and the next survey does not offer it.
- A mission failing any part of the proof is untouched, and the run says nothing about it.
- `close.sh` remains the only writer of an end state; no status is written elsewhere.
- The close, and any refusal, appear in the run report by name.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- A hermetic drive over a two-ticket mission asserting `status: achieved` after the second
  archive, and over a mission with an unmet item asserting `status: active`.

**Gate** — what must pass before approval:

- All four criteria hold and the suite is clean.

## Considerations

- The queue-emptiness half must be read through the survey's own reader. A fresh grep for
  `mission: <slug>` would be a second parser of a relation `read-relation.sh` already owns, and
  the relation is many-valued.
- A mission can be finished by a path that archives no ticket. The seam will not catch that, which
  is what the sibling ticket reports rather than hides.
