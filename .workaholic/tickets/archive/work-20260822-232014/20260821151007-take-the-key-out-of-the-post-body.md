---
created_at: 2026-08-21T15:10:07+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: take-the-dedup-key-out-of-the-read-post
merge_policy:
verification_handoff: 
---

# Take the key out of the post body

## Overview

PROPOSED, and last: it applies what the first two tickets found. The key leaves the read text
of every shape that carries one, and case 2 of the thread lookup still finds an item's existing
thread. Which mechanism replaces the visible string is Open Decision 1, and the second ticket's
measurement is what narrows it.

Whatever is chosen, the property that must survive is the one #360 bought: one feedback item
owns exactly one thread, and a tick that finds it replies into it.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/notify/reference/notifications.md` — every post shape, and the lookup's four cases.
- `plugins/workaholic/skills/notify/SKILL.md` — the lookup's contract.
- `plugins/workaholic/skills/workaholify/routines/*.md` — the templates mirror the shapes byte-identically and are pinned against drift.
- `scripts/test-workflow-scripts.mjs` — pins the shapes and the template copies; both move together or the pin fails.


## Implementation Steps

1. Read the first two tickets' findings from the mission changelog. Do not restart either.
2. Resolve Open Decision 1 explicitly, recording why the rejected directions were rejected —
   including direction 3, which the ask asks to be rejected on the record rather than by
   omission.
3. Apply the chosen mechanism to every shape that carries a key today: `fb:`, `stuck:`,
   `deploy:`, `standup:`, `unit:`. One mechanism for all of them; a per-shape exception is a
   drift the pinning tests exist to catch.
4. Update the routine templates in the same change — they mirror the shapes byte-identically,
   and `test-workflow-scripts.mjs` fails if the two disagree.
5. Prove the surviving property end to end: post, then run the lookup, and confirm case 2
   matches and no second root appears.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- No post shape carries a key line a human reads.
- One feedback item still owns exactly one thread across repeated ticks.
- Every shape uses the same mechanism, and the templates match the catalog byte for byte.

**Verification method** — the commands/tests/probes that prove them:

- Post, wait, run the lookup, and assert case 2 matched and no second root was created.
- `node scripts/test-workflow-scripts.mjs` passes, including the template-drift pins.

**Gate** — what must pass before approval:

- Open Decision 1 is resolved in the Final Report, with direction 3 rejected on the record.
- No thread coordinate is written into this repository.


## Considerations

- Any store outside the post must also sit outside this repository (FB `20260811084130`): a
  Slack thread coordinate committed here is the irretractable exposure P9 already found.
- Direction 2 (hash the stem) does not satisfy the ask literally — it shortens rather than
  removes. If the measurement rules out direction 1, say so plainly rather than presenting a
  shortened key as the ask fulfilled.

## Open Decisions

1. **Where does the key live once it leaves the read text?** The ask offers three directions
   and chooses none. (a) Non-visible Slack metadata the search surface still indexes — shortest,
   and alive only if the previous ticket's measurement says the surface matches it. (b) A hash
   of the stem, which keeps case 2 exact-matchable and shrinks the line to a few characters, but
   does not satisfy the ask literally. (c) Delete it and accept duplicate roots — cheap, honest,
   and a reversal of a measured fix; the ask explicitly wants it rejected on the record rather
   than by omission. A fourth, a store outside the repository, is unexplored and constrained by
   FB `20260811084130`. Resolve in the Final Report against the measurement, not against
   preference.

