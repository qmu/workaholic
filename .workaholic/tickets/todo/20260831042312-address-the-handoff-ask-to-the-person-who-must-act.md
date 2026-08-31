---
created_at: 2026-08-31T04:23:12+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: notify-the-person-a-directed-question-addresses
merge_policy:
verification_handoff: 
---

# Address the handoff ask to the person who must act

## Overview

PROPOSED. The ask names two carriers for the bot identity: the directed
question, and the **waiting-on-a-person handoff ask**. The handoff finish line
lost its mention on 2026-08-23 for exactly the reason this mission exists — the
token it carried resolved to the account the post is made as — so today it names
nobody at all, and the measured failure was three items waiting on operator
input that the operator found only by asking a session directly.

Give the handoff line back a mention, addressed to the person who must perform
the declared verification, and carry it on the bot so the mention fires.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/notify/reference/notifications.md` — the handoff
  shape, and the record of why its token was dropped.
- `plugins/workaholic/skills/notify/SKILL.md` — *Never mention the identity you
  are posting as*, which this narrows rather than reverses.
- `plugins/workaholic/skills/drive/SKILL.md` — the route that posts the finish
  line, and the run report that names its outcome.
- `plugins/workaholic/skills/drive/scripts/verification-handoff.sh` — the one
  reader of the declared reason; the addressee comes from the unit's assignees,
  not from this script.

## Implementation Steps

1. Read the 2026-08-23 record before changing the shape, and state in the change
   what it got right: a self-mention is decoration. The repair is the identity,
   never the removal.
2. Restore the mention on the handoff finish line, resolved from the unit's own
   `assignees` through `gather/scripts/identity.sh`, and leave it **absent** when
   the address does not resolve rather than stamping one nobody verified.
3. Carry that line on the bot when the addressee resolves to the posting
   identity, per the transport rule; otherwise the connector, unchanged.
4. Keep the declared reason quoted verbatim and the line's other wording exactly
   as the catalog has it; this changes who it names and what carries it, nothing
   else.
5. Report the carrying surface and the mention outcome in the run report beside
   the existing notification outcome, so an unposted or unaddressed line reads as
   what it is.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A handoff finish line names the person who must act, when that person resolves.
- It is carried by the bot when the addressee is the posting identity, and by the
  connector otherwise.
- An unresolved addressee produces no token and is reported, never guessed.
- The declared reason's wording is unchanged.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-handoff-question` — unchanged rows green.
- The drill added by this mission's drill ticket, covering the mention and the
  carrying surface.

**Gate** — what must pass before approval:

- The catalog and the drive route state one shape; the run report names the
  surface and the mention for every handoff line it posts.

## Considerations

- `/moderate`'s `handoff-units` question already asks the claim holder about a
  standing handoff. This is not a duplicate: that question fires hourly from the
  claim oracle, this is the finish line the run itself posts, and the two are the
  same person's business by different routes. Whether one should suppress the
  other is a judgement for the operator, not this mission.
- An attended `/drive` run still posts nothing to Slack, unchanged.
