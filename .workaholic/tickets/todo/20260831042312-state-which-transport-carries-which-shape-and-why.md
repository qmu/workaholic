---
created_at: 2026-08-31T04:23:12+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: notify-the-person-a-directed-question-addresses
merge_policy:
verification_handoff: 
---

# State which transport carries which shape and why

## Overview

PROPOSED. `workaholic:notify` ranks the two transports as *primary* and
*fallback*, so the tokened script is reachable only when the connector is
absent — a rule about **availability** that silently also decides **identity**.
The ask names this as the structural half of the defect and asks for the model
to state which transport carries which shape and why.

Narrow the rule rather than reverse it: a **directed** post — one whose whole
purpose is to reach a named person — takes the bot identity when the addressee
resolves to the posting identity. Roots, finish lines and the lookup stay on the
connector, the only transport that can search or thread on its own.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/notify/SKILL.md` — *The transport*, and *Never
  mention the identity you are posting as*, whose unstated consequence this is.
- `plugins/workaholic/skills/notify/reference/notifications.md` — *A post never
  mentions the identity it is posted as*, plus the directed shapes' catalog
  entries.
- `CLAUDE.md` — the notification model's summary, updated in the same change.

## Implementation Steps

1. Write the rule where the transport model already lives: the connector stays
   primary for every post; a **directed** post takes the bot identity when the
   mention target resolves to the posting identity, and the connector otherwise.
2. Enumerate the directed shapes by name — the moderator's question and the
   waiting-on-a-person handoff ask — and state that the enumeration is a
   deliberate edit to this skill, never a judgement made at post time (the
   discipline the precondition-stop class already carries).
3. State what does **not** move: the two-query lookup bound, the
   private-inclusive search, the fuzzy-matching prohibition, case 4's
   description root, *never mention the identity you are posting as* (which this
   satisfies by changing the identity rather than the mention), and *the prompt
   is the ceiling*.
4. State the degradation in the same breath: with no bot token a directed post
   falls back to today's connector post and is **reported as such** — never
   silently downgraded, never dropped, and never counted as delivered.
5. Record why the fallback's other limits still hold: it cannot search, so it is
   never the lookup's carrier, and the connector resolves the thread it replies
   into.
6. Update `CLAUDE.md`'s notification summary in the same commit.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- The model names, per post shape, which transport carries it and why.
- The directed set is a closed, enumerated list rather than a judgement.
- The no-token degradation is stated as reported, never as silent.
- The lookup's bounds and the mention rule are stated as unmoved.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs` — the routine-template drift pins.

**Gate** — what must pass before approval:

- Both surfaces state one rule rather than two: a reader can answer "which
  transport carries this shape" from either without contradiction.

## Considerations

- The wider rule — *any call site may pick the bot* — is refused: it would let
  an ordinary root escape the connector and lose its threading, and the identity
  question only ever arises for a directed post.
- A looser reading of "directed" (any post naming a person) is refused too: the
  merge, blocked and standup shapes name people as facts and page nobody, which
  is the distinction the enumeration keeps checkable.
