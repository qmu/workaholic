---
created_at: 2026-08-28T05:21:33+00:00
status: done
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

## Final Report

Development completed as planned.

`closing-residue.sh <slug>` composes the three readings that already existed — the waiting
grains from `attributed-work.sh`, the residue from `unattributed-work.sh`, and the lifecycle
state from `direction-state.sh` — into one JSON object. No second walker, no relation of its
own, no field on any artifact; the only thing it owns is the assembly. Each block carries its
own `readable` and reason, a degraded block reports null counts, and the top-level `readable`
names the source that failed. `exhaustive` is `false` in every output. Verified with
`node scripts/test-workflow-scripts.mjs` (`testClosingResidueReader`, 19 assertions) and
against this repository's own live direction.

### Discovered Insights

- **Insight**: `direction-state.sh` is bounded to the `active` set by design, so a direction
  that has just been closed has no row there at all.
  **Context**: the one caller that reads this *after* a close is `/specificate`'s *ended*
  route, so treating an absent row as a degradation would have left that route unable to
  state anything. The absent row is reported `state: not_active`, `readable: true` — a real
  answer about a real tree, which is the same line `no_citing_artifacts` already draws
  between an empty reading and one that could not be made.
- **Insight**: composing a reader that a consumer also composes creates a recursion risk the
  moment the consumer wants to carry the composition onto its own rows.
  **Context**: `--state-row` is the escape: `direction-state.sh` hands back the row it
  already computed, so the assembly stays in exactly one place, nothing recurses, and the
  attachment costs no extra read of the tree and no extra network call.
