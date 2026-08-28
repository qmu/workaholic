---
created_at: 2026-08-28T05:21:33+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-direction-s-end-a-turn-of-the-loop-not-its-stop
merge_policy:
verification_handoff: 
---

# Read what a direction leaves behind

## Overview

What a direction leaves when it ends is already in the tree and already readable —
what it never reached (`attributed-work.sh`'s waiting grains), what no direction claimed
(`unattributed-work.sh`'s residue) and its own last lifecycle reading
(`direction-state.sh`). Nothing composes them, so nothing can state them at the moment the
operator decides. This adds the one reader that composes what already exists.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/strategy/scripts/closing-residue.sh` — NEW: the one reader
- `plugins/workaholic/skills/strategy/scripts/attributed-work.sh` — the waiting grains, read through it unchanged
- `plugins/workaholic/skills/strategy/scripts/unattributed-work.sh` — the residue, read through it unchanged
- `plugins/workaholic/skills/strategy/scripts/direction-state.sh` — the last lifecycle reading, read through it unchanged
- `plugins/workaholic/skills/strategy/SKILL.md` — document the reader and its stated limits
- `scripts/test-workflow-scripts.mjs` — hermetic coverage for the composition and its degraded reads

## Implementation Steps

1. Write `closing-residue.sh <slug>` composing the three existing readers — no second walker,
   no relation of its own, no field on any artifact. Each fact comes from that fact's existing
   single reader.
2. Emit one JSON object naming, per source, what it read: the waiting grains, the residue
   (missions by slug with queued counts, tickets by path) and the lifecycle state.
3. Make `readable: false` carry **its own reason** and **null** counts rather than zeroed ones —
   a reading we could not make must never render as an empty one.
4. Set `exhaustive: false` by construction and say so in the output, inheriting the walk's
   stated lossiness rather than implying the answer is complete.
5. Exit 0 in every case; write nothing, commit nothing, create no branch, make no network call
   the composed readers do not already make.
6. Document it in `strategy/SKILL.md` beside the readers it composes, with the limits stated.
7. Add hermetic tests: a healthy composition, each source degraded independently, and a proof
   that a degraded source yields `readable: false` with null counts rather than zeros.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `closing-residue.sh <slug>` returns the waiting grains, the residue and the lifecycle state for a live direction
- A degraded read of any one source yields `readable: false`, its own reason, and null counts
- `exhaustive` is `false` in every output
- The script writes nothing and adds no field to any artifact

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `bash plugins/workaholic/skills/strategy/scripts/closing-residue.sh <a live slug>` against this repository

**Gate** — what must pass before approval:

- No second walker, no new relation and no new field exists anywhere in the diff
- The three composed readers are byte-identical

## Considerations

- The residue reader over-reports at the mission grain by construction; this composition inherits
  that and must state it rather than smooth it over.
