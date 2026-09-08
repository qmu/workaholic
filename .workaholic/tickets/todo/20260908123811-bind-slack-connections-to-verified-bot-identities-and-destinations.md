---
created_at: 2026-09-08T12:38:11+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-slack-intake-incremental-across-messages-threads-and-mentions
merge_policy:
verification_handoff: 
---

# Bind Slack connections to verified bot identities and destinations

## Overview

Discover live QFS Slack mounts and bind each authorized account to its actual workspace, bot/user ID, reachable private channels, and post/reply maps without guessing from display labels.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/transport/` — connection discovery and identity binding.
- `plugins/workaholic/skills/qfs-slack/` — live describe, channel, and write-map contracts.
- `plugins/workaholic/skills/work/` — consume the resolved binding at tick startup.

## Implementation Steps

1. Inventory the existing QFS and connector selection paths and their live capability checks.
2. Derive one binding record per connection from describe output, scopes, identity, channel reachability, and post/reply maps.
3. Keep account, destination, sender identity, and thread coordinates inseparable through each effect.
4. Test multiple bots, missing identity scope, private-channel visibility, and ambiguous matches.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- No connection or sender is selected from its label alone.
- Ambiguous or unverifiable identities remain explicit degraded readings.

**Verification method** — the commands/tests/probes that prove them:

- Run transport and QFS Slack fixtures for one, zero, and multiple verified matches.

**Gate** — what must pass before approval:

- Selection is deterministic only for one fully verified binding.

## Considerations

Slack search and identity scopes vary by credential; the reader must preserve unknown instead of treating it as empty.
