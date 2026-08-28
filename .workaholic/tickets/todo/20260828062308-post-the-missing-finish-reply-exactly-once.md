---
created_at: 2026-08-28T06:23:08+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: reconcile-a-stale-thread-with-the-unit-s-real-state
merge_policy:
verification_handoff: 
---

# Post the missing finish reply, exactly once

## Overview

The agent half: for each candidate the step hands back, find the item's thread, read it, and post
the missing finish reply — or nothing. This is the ticket where the ask's own promise is made
mechanical: *"the step reads the thread before writing, so never re-announce a merge the channel
already carries is satisfied by construction"*.

Unlike `question-answers`, **no coordinate is in hand**: the `🔵`/`🟡` line was posted by another
container, in another run, and nothing persisted where. So the thread is found the way everything
else finds it — `workaholic:notify`'s stateless exact-token lookup, private-inclusive with
`include_bots: true`, **at most two search queries per lookup**, fuzzy matching prohibited by name.
And **case 4 does not apply here**: a lookup that finds no thread means the loop never announced
this item at all, so there is nothing stale to correct — report it and post nothing. Posting a
description root would announce a merge nobody was ever told about, which is `[Consent]`'s retired
job.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / `policies/ux-principles.md` — one short post, addressed to the item's readers

## Key Files

- `plugins/workaholic/skills/moderate/reference/workflow.md` — the step's section, where the agent's contract is written
- `plugins/workaholic/skills/notify/SKILL.md` — the lookup, its two-query bound, and the fuzzy prohibition
- `plugins/workaholic/skills/notify/reference/notifications.md` — the shape, named by the previous ticket
- `plugins/workaholic/skills/moderate/scripts/log-append.sh` — the `thread-reconcile-filed` line, one per candidate
- `plugins/workaholic/skills/moderate/scripts/persist-log.sh` — how that line reaches the base

## Implementation Steps

1. Write the agent contract into the step's section: per candidate, run the lookup (cases 2 and 3
   only, two queries maximum), then read that thread.
2. **Define the bar for "already carries its finish", and make it conservative.** A thread whose
   latest status reply is `🟢`, `🚀`, `🔴` or a reconciliation this loop already posted is **not**
   a candidate. Only a latest status of `🔵 Proposed` or `🟡 Handoff` is. **When unsure, post
   nothing and say what made you unsure** — the standing bar, and here it costs one tick rather
   than a duplicate announcement in a person's thread.
3. Post the shape the catalog names, with the sentence naming that it merged outside the loop, by
   whom and when, from the merge commit the reader supplied. Never invent an author or a time: an
   unresolved one is stated as unresolved, never omitted silently and never guessed.
4. **No thread found → post nothing**, report it by name. Case 4's description root is explicitly
   not taken, and the section says why.
5. Record one `thread-reconcile-filed` line per candidate through `log-append.sh` naming the
   candidate and the outcome, then persist again through `persist-log.sh --tick` — the second
   persist, without which the line dies with the container.
6. **Per candidate, one outcome or the other**: posted, or a named not-posted reason
   (`no_thread`, `already_finished`, `unsure`, `no_slack_transport`, `thread_unreadable`,
   `post_failed`). A candidate handed back with no outcome is non-conformant on its face.
7. Write what it never does: never merges, never closes, never reopens, never touches a claim,
   never posts a root, never posts into any thread but the item's own, never posts twice.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The thread is read before anything is posted, and a thread already carrying its finish is never touched
- At most two search queries per candidate; no channel history read anywhere
- A lookup that finds no thread posts nothing and is reported by name
- Every candidate has exactly one reported outcome, posted or a named reason
- Nothing is merged, closed, reopened, or claimed, and no post lands outside the item's own thread

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-reconcile` — the drill built in the next ticket
- `node scripts/test-workflow-scripts.mjs` — the contract's prose is pinned where it is mechanical

**Gate** — what must pass before approval:

- The drill passes, including the already-finished and no-thread rows
- `node scripts/test-workflow-scripts.mjs` passes

## Considerations

- **This is a prose contract, not a script gate** — no mechanical check tells a real thread read
  from a claimed one, exactly as the `## Open Decisions` floor and `question-answers`' bar are
  written. What it buys is that a report naming no outcome is visibly wrong.
- The post carries **no mention token**: it is addressed to whoever follows the item, not to a
  person, and the standing rule forbids mentioning the identity it is posted as.
- The idempotence is structural (read before write), so resist adding a cursor or a second ledger;
  the `<step>-filed` line stays an optimisation the agent is handed.
