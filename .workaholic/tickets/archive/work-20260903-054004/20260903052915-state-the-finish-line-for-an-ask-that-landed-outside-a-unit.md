---
created_at: 2026-09-03T05:29:15+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: announce-an-ask-that-landed-outside-a-unit-route-in-its-own-thread
merge_policy:
verification_handoff: 
---

# State the finish line for an ask that landed outside a unit

## Overview

The post shape belongs in one place. `workaholic:notify` is the catalog and the command is
the ceiling: a shape written into a routine prompt reaches a fleet only by being re-pasted, so
this states the shape once in the catalog and once in `commands/infinite-development.md`, pinned
byte-identical. The shape **reuses `🟢 Implemented`**, marked by its sentence rather than by a new
colour — the precedent `thread-reconcile` set for a merged item announced late.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/notify/reference/notifications.md` — the catalog of shapes.
- `plugins/workaholic/skills/notify/SKILL.md` — *Which transport carries which shape, and why*,
  and the stateless `fb:<stem>` thread lookup.
- `plugins/workaholic/commands/infinite-development.md` — the ceiling this run's tick reads.

## Implementation Steps

1. Add the shape to the catalog beside the existing finish lines, in the same wording the
   command will carry:

   ```
   🟢 Implemented [<ask title>](<issue url>)
   <one sentence, max 30 words, what landed and by whom.>
   ```

2. State the bounds beside it: **no mention token** (it is addressed to the thread, not to a
   person), posted as a **reply** into the item's own thread resolved by the `fb:<stem>` exact
   string, and **once ever per item**.
3. State which transport carries it — the connector, because it is the only one that can
   search and therefore resolve the thread; the tokened fallback posts nothing here, because a
   caller with no connector never resolved a thread to reply into.
4. Write the same block into `commands/infinite-development.md` verbatim, and say in both places
   that the two must stay byte-identical.
5. Say in the catalog what this shape does **not** do: it never opens a root, and an item whose
   thread cannot be resolved is left alone rather than announced somewhere else.

## Quality Gate


**Acceptance criteria** — the checkable conditions that must hold:

- The shape appears in `notify/reference/notifications.md` and in
  `commands/infinite-development.md`, byte-identical.
- The bounds — no mention token, reply only, once ever, connector only — are stated with it.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` pins the two copies byte-identical.

**Gate** — what must pass before approval:

- No fifth colour is introduced; the shape is `🟢 Implemented` marked by its sentence.

## Considerations

- Reusing `🟢 Implemented` keeps a channel reader's vocabulary at four colours. A new colour
  for the same event read from a different reader is a distinction only the loop cares about.

## Final Report

Development completed as planned. The shape is stated in `notify/reference/notifications.md`
beside the existing finish lines and written verbatim into `commands/infinite-development.md`,
the two byte-identical from the code fence through the closing paragraph.

It **reuses `🟢 Implemented`**, marked by its sentence rather than by a new colour — the
precedent `thread-reconcile` set for a merged item announced late. The bounds are stated with
it, each as a refusal rather than a preference: no mention token, a reply and never a root
(case 4's keyed root is refused by name here), once ever per item with the dedup read from the
thread, the connector as the only transport that can resolve the thread at all, and an
unresolvable field stated as unresolved rather than filled in.

### Discovered Insights

- **Insight**: Byte-identity across two files is broken by exactly the words that make prose
  read naturally in place — "the precedent `thread-reconcile` set **above**" is true in the
  catalog and false in the command, and a cross-reference naming *the other file* differs by
  construction. The repair is to write the shared region so it is positionless: name both files
  in both copies, and drop every "above"/"below".
  **Context**: Every future block pinned byte-identical across the catalog and a command ceiling
  faces this, and the failure is silent until the pin runs.

