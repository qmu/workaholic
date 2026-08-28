---
created_at: 2026-08-28T01:20:42+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-what-the-direction-could-not-see-before-calling-it-arrived
merge_policy:
verification_handoff: 
---

# Read what no direction claims

## Overview

`strategy/scripts/unattributed-work.sh` — a pure reader answering *what does no direction
claim*, over the live tree: the active missions and the queued tickets that
`mission-strategy.sh` cannot attribute to any `active` strategy. It composes the walk that
already exists; it introduces no second walker, no relation of its own and no field on any
artifact, exactly as `mission-strategy.sh` composes `attributed-work.sh`.

`readable: false` is named with its own reason rather than rendered as an empty residue —
the `unreadable`-is-never-`dormant` precedent. An empty residue and a residue we could not
read are the two states this whole mission exists to keep apart.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/strategy/scripts/unattributed-work.sh` — new; the one reader
- `plugins/workaholic/skills/strategy/scripts/mission-strategy.sh` — composed, not duplicated; read its header first
- `plugins/workaholic/skills/strategy/scripts/attributed-work.sh` — stays the one attribution reader; not touched
- `plugins/workaholic/skills/strategy/SKILL.md` — the reader is documented where the artifact's model lives
- `scripts/test-workflow-scripts.mjs` — hermetic coverage for the honest and the degraded read
## Implementation Steps

1. Read `mission-strategy.sh` end to end, including its header: it already answers
   *which strategy does this mission belong to* for every mission in the active area, and
   reports `unreadable[]` per strategy plus `exhaustive: false`.
2. Write `unattributed-work.sh` composing it. Output `{ok, readable, reason, missions:
   [{slug, path, queued}], tickets: [{path}], mission_count, ticket_count, exhaustive:
   false}`; exit 0 always, write nothing, create nothing.
3. Derive the queued tickets from the readers the tree already uses for the queue rather
   than parsing the `mission:` relation a second time — a mission's queued tickets ride its
   row, and a queued ticket belonging to no mission is its own entry.
4. Make `readable: false` carry its own reason and never a zeroed residue: a
   `mission-strategy.sh` that answered `ok: false`, or that named every strategy in
   `unreadable[]`, is a read we did not make.
5. Add hermetic cases: an honest residue, an empty residue, and a degraded read that
   answers `readable: false` with its reason.
## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `unattributed-work.sh` names each unattributed active mission by slug and path with its
  queued-ticket count, and each unattributed queued ticket by path.
- A degraded read answers `readable: false` with a named reason and no residue counts
  presented as zero.
- `exhaustive` is `false` on every answer.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` covers the honest, the empty and the degraded read.
- Running it against this repository names the four missions the ask measured.

**Gate** — what must pass before approval:

- The script writes nothing, creates nothing and exits 0 in every case.
- `attributed-work.sh` and `mission-strategy.sh` are unchanged.

## Considerations

- The temptation is a `strategy:` field on the mission, refused three times over
  (2026-07-28, 2026-08-17, 2026-08-26). This reader must add no field and revive no relation.
- It inherits the walk's lossiness. `attributed: false` means *no strategy could be
  attributed*, never *this belongs to no direction* — the residue is a reading, not a verdict.
## Final Report

Development completed as planned.

`strategy/scripts/unattributed-work.sh` answers *what does no direction claim* by composing
`mission-strategy.sh` — no second walker, no relation of its own, no field on any artifact.
The queue rides the same composition through `mission/scripts/read-relation.sh`, the single
reader of the `mission:` relation: a queued ticket naming an attributed active mission is
absent, one naming an unattributed active mission rides that mission's row, and one naming
no active mission is its own entry. `readable: false` carries its own reason and **null**
counts rather than zeroed ones, and `exhaustive` is `false` on every answer.

Run against this repository it names the four missions the ask measured, with nine queued
tickets on their rows and one loose queued ticket beside them.

### Discovered Insights

- **Insight**: a degraded read must report `mission_count: null`, not `0`. A consumer
  skimming the counts beside `readable: false` reads an empty residue where there was no
  reading at all — which is the exact confusion this reader exists to prevent, reproduced
  one field lower.
  **Context**: the same discipline `direction-state.sh` applies to `active_count` on its own
  unreadable path.
- **Insight**: `all_strategies_unreadable` is only claimable when at least one strategy was
  *tried*. Zero active strategies is a readable answer — nothing claims anything — and
  folding the two together would make an empty repository look degraded forever.
  **Context**: `strategies_read` is what tells them apart, and it already rode
  `mission-strategy.sh`'s output.
- **Insight**: a loose queued ticket is residue **by construction** here, because the reader
  this composes answers only at the mission grain and cannot see a ticket's own `feedback:`
  refs. The reading over-reports rather than under-reports.
  **Context**: stated in the script's header so a consumer rendering it as *what I could not
  see* is saying the true thing rather than implying a verdict.
