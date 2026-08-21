---
created_at: 2026-08-21T15:10:07+09:00
author: a@qmu.jp
assignees: [tamura.yoshiya@gmail.com]
depends_on:
mission: take-the-dedup-key-out-of-the-read-post
merge_policy:
verification_handoff: 
---

# Measure what the Slack search surface matches

## Overview

PROPOSED. The shortest path to satisfying the ask is to move the key out of the visible text
into metadata the search surface still indexes. Whether that works is an empirical question
about Slack, and the ask says plainly why it must be measured rather than assumed: the
2026-08-11 record shows how badly an unmeasured assumption about this search surface goes.

This ticket measures. It designs nothing.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/notify/SKILL.md` and `reference/notifications.md` — the stateless lookup's cases 2 and 4, which define exactly what must remain matchable.


## Implementation Steps

1. Post a probe message into a scratch channel carrying a candidate key in each non-visible
   carrier available — message metadata, blocks, attachment fields, whatever the surface offers.
2. Search for each candidate through the same call the lookup uses
   (`slack_search_public_and_private`) and record which are found and which are not.
3. Record the negative results as carefully as the positive ones. A carrier that does not match
   is the finding that prevents the next ticket designing on it.
4. Repeat once after a delay: an index that matches immediately and one that matches eventually
   are different guarantees, and the lookup runs seconds after the post.
5. Write the measurement into the mission changelog with the date it was taken — a search
   surface is somebody else's product and this answer can expire.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Each candidate carrier is recorded as matched or not matched, with the query used.
- The measurement is repeated after a delay so immediate-versus-eventual indexing is known.
- The result is dated in the mission changelog.

**Verification method** — the commands/tests/probes that prove them:

- Post probes and search them back through `slack_search_public_and_private`.
- Re-run the same searches after a delay and compare.

**Gate** — what must pass before approval:

- The measurement uses the routines' own credential class.
- Negative results are recorded, not omitted.


## Considerations

- If no non-visible carrier matches, that is a complete and useful result: it eliminates
  direction 1 and hands the next ticket a two-way choice instead of a three-way one.
- Measure with the same credential class the routines use. A carrier that only an interactive
  session can search is not a carrier this loop can use.

