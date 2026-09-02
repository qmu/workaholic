---
created_at: 2026-09-03T05:29:15+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: announce-an-ask-that-landed-outside-a-unit-route-in-its-own-thread
merge_policy:
verification_handoff: 
---

# Post the finish line from the tick, once per ask

## Overview

This is the act. The tick already reads the channel every turn and already resolves threads
through the stateless lookup, so it is the one step positioned to post. The dedup is
**structural and read from the thread**, not stored: read the item's thread first, and post
nothing when a finish line of ours already follows the receipt.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/commands/infinite-development.md` — where the tick's steps are specified.
- `plugins/workaholic/skills/loops/SKILL.md` — the tick's contract.
- `plugins/workaholic/skills/propose/scripts/list-unannounced-closed-asks.sh` — the candidate
  reader from the earlier tickets.
- `plugins/workaholic/skills/notify/SKILL.md` — the `fb:<stem>` thread lookup.

## Implementation Steps

1. Add one step to `commands/infinite-development.md`, after the channel turn and before the
   subagents are spawned, so it costs the tick nothing that waits on work.
2. Run the candidate reader, bounded; for each candidate resolve its thread by the `fb:<stem>`
   exact string through the connector — never by similarity and never by recency.
3. **Read the thread before posting.** A thread whose messages already carry a finish line of
   ours for this item is skipped, reported `already_announced`. This is the whole dedup: no
   ledger, no cursor, no field on any artifact.
4. Post the shape from the previous ticket as a reply into that thread, once. Compose the
   sentence from `landed[]` — what merged, by whom — and state an unresolvable field as
   unresolved rather than omitting it.
5. Report per candidate: `announced`, `already_announced`, `thread_unresolved`, or
   `post_failed: <reason>`. A failed post is never load-bearing and never retried in the turn.
6. Record the step in `skills/loops/SKILL.md` as part of the tick's Slack turn, since the main
   agent owns Slack and nothing else.

## Quality Gate


**Acceptance criteria** — the checkable conditions that must hold:

- A candidate whose thread carries a receipt and no finish line receives exactly one reply.
- A second tick over the same item posts nothing and reports `already_announced`.
- A candidate whose thread cannot be resolved is left alone and reported.

**Verification method** — the commands/tests/probes that prove them:

- A drilled offline case in `scripts/e2e/loop-drill.sh` covering the announce-once behaviour.
- The tick's own run report, read over two consecutive turns.

**Gate** — what must pass before approval:

- The step performs no full-channel read, and posts no root.

## Considerations

- The thread read is what makes the dedup structural. A stored ledger would have to survive a
  fresh container, which is exactly the property the loop has repeatedly failed to keep.
