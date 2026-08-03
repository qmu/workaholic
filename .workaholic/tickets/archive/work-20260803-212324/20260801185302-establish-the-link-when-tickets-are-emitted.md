---
created_at: 2026-08-01T18:53:02+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain]
effort:
commit_hash:
category: Changed
depends_on: [20260801185301-decide-the-acceptance-to-artifact-link.md]
mission: make-acceptance-ticking-measure-satisfaction-not-marker-shape
merge_policy: auto
---

# Establish the acceptance link when the ticket set is emitted

## Overview

Closes the seam. A `/propose` draft is written before any ticket exists, so its acceptance
items cannot carry a link at authoring time — but the moment the ticket set **is** emitted,
every filename exists at once. That is the first point at which the link can be
established, and today nothing does it.

This is what makes the fix structural rather than cosmetic: relaxing the ticker alone
would let markerless items be ticked, but the acceptance list would still not say which
artifact satisfies which item. The seam is the answer to "which ticket makes this true".

The seam is the same one that emits a mission's ticket set — `/mission`'s replan, and the
approval path that turns a draft into drivable work. Both must establish the link, or a
mission fleshed out by one route starts correct and by the other starts stranded.

## Policies

- `workaholic:implementation` / `policies/command-scripts.md` — the link is established by the shared mission mutators, never by hand-editing `mission.md`.
- `workaholic:development` / `policies/qa-engineering.md` — the acceptance list is the agreed bar; establishing a link must not silently change what was agreed.
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `#!/bin/sh -eu`.

## Key Files

- `plugins/workaholic/skills/mission/scripts/` - the shared, idempotent mutators; the link writer belongs here
- `plugins/workaholic/skills/mission/SKILL.md` - the replan flow that emits a ticket set
- `plugins/workaholic/skills/propose/scripts/scaffold-draft.sh` - writes the items that start unlinked
- `plugins/workaholic/skills/propose/scripts/scaffold-proposed-ticket.sh` - writes the tickets they should link to

## Implementation Steps

1. Add the link writer as a shared mission mutator, idempotent like `tick-acceptance.sh`
   and `append-changelog.sh` — running it twice must not double-write a marker.
2. Call it from **every** seam that emits a ticket set for a mission, so no route leaves a
   mission stranded. Enumerate the seams rather than assuming there is one.
3. Preserve the item's text exactly. The acceptance list is what the developer agreed to;
   establishing a link may add a marker, never re-word a criterion.
4. Handle the unmatched case honestly: an acceptance item that no emitted ticket satisfies
   stays unlinked and is **reported**, not silently linked to the nearest ticket.

## Quality Gate

**Acceptance criteria**

- A mission whose ticket set is emitted has its acceptance items linked, by the decided contract, without any hand edit.
- Every seam that emits a ticket set establishes the link — verified by enumerating them, not by checking one.
- The mutator is idempotent: running it twice leaves the file byte-identical.
- An acceptance item that no ticket satisfies is left unlinked and reported, never guessed at.
- Item text is preserved exactly; only the link is added.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green, with hermetic cases for: a mission gaining links on emission, the idempotence of a second run, and an unsatisfiable item being reported rather than linked.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` with no residual diff.

**Gate**

- The idempotence case passes. A non-idempotent mutator on `mission.md` corrupts the board on the second run, which is worse than the stranding it fixes.

Decided: the link is established at emission rather than inferred at tick time — inference would guess which artifact satisfies which criterion, and a wrong guess ticks an item the work did not satisfy, which is the failure mode this whole mission is about (developer may override at /drive).

## Considerations

- Enumerate the emitting seams before writing the call: `/mission` replan and the approval path are the known ones, and `/propose` may become a third if it ever emits its ticket set and mission together.
