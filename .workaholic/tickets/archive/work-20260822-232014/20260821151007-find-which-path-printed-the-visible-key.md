---
created_at: 2026-08-21T15:10:07+09:00
status: done
author: a@qmu.jp
assignees: [tamura.yoshiya@gmail.com]
depends_on:
mission: take-the-dedup-key-out-of-the-read-post
merge_policy:
verification_handoff: 
---

# Find which path printed the visible key

## Overview

PROPOSED, and first because the reporter puts it first. `🔵 Proposed` is specified as a
**reply** in every connector case; it carries the key only on the tokened fallback, which
cannot thread (`notify/reference/notifications.md`). So a `🔵 Proposed` seen carrying the key
is either the tokened fallback or the description root — and if it is the fallback, the
connector was unavailable on that tick, which is a different and possibly more useful defect
than the one reported.

This ticket answers which. It changes nothing.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/notify/reference/notifications.md` — the shapes, and which of them carries a key.
- `plugins/workaholic/skills/specificate/scripts/notify-slack.sh` — the tokened fallback, keyed-root only.
- `plugins/workaholic/skills/workaholify/routines/specificate.md` — the two formats this routine authorizes, and its `mcp` list.


## Implementation Steps

1. Retrieve the observed post and read which surface wrote it — connector or tokened fallback —
   from Slack itself rather than inferring it from the shape.
2. If it was the fallback: report why the connector was unavailable on that tick, and stop.
   That is a separate defect and this mission does not absorb it; raise it as its own ticket.
3. If it was the description root: confirm that the root is specified to carry the key and the
   reply is not, so the mission's later tickets know exactly which shapes they touch.
4. Record the finding in the mission changelog. Both later tickets read it.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The surface that wrote the observed post is identified from Slack, not inferred.
- The set of shapes that actually carry a key is enumerated.
- A fallback-path finding, if any, is raised as its own ticket rather than absorbed.

**Verification method** — the commands/tests/probes that prove them:

- Read the message back through the Slack surface and inspect its author/app.
- Diff the enumerated shapes against `notify/reference/notifications.md`.

**Gate** — what must pass before approval:

- No behaviour changes in this ticket.
- The finding is written into the mission changelog before the next ticket starts.


## Considerations

- The answer may make the rest of the mission smaller — if only the root and the fallback carry
  keys, far fewer shapes change than "every template" implies.
- Do not fix anything here. A diagnosis ticket that also edits is a diagnosis nobody can trust.

