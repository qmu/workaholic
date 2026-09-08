---
created_at: 2026-09-08T12:44:19+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-slack-acknowledgements-informative-without-becoming-notification-noise
merge_policy:
verification_handoff: 
---

# Define the human-centered Slack acknowledgement contract

## Overview

Replace fixed receipt copy with a conversation contract that requires a recognizable subject, truthful state, matching language and register, and concise context-aware phrasing.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/work/` — inbound acknowledgement decision and rendering.
- `plugins/workaholic/skills/notify/` — shared human-facing message constraints.
- `plugins/workaholic/rules/interaction.md` — language, conversational register, and human/AI workspace rationale.

## Implementation Steps

1. Inventory fixed acknowledgement sentences and the workflow facts each currently carries.
2. Define required facts separately from agent-composed prose: subject, issue link, actual state, and any grouping context.
3. Permit natural concise wording in the person's language while forbidding unearned implementation promises and ornamental chatter.
4. State notification fatigue and cognitive aversion as design constraints for the Slack surface.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A receipt is understandable without opening its issue and never overstates readiness.
- The contract supports natural variation without impersonating a human.

**Verification method** — the commands/tests/probes that prove them:

- Run rendering fixtures in Japanese and English for captured, deferred, and proposed states.

**Gate** — what must pass before approval:

- Required facts remain machine-checkable while prose is not snapshot-locked.

## Considerations

Natural phrasing must not weaken exact issue and thread identity.
