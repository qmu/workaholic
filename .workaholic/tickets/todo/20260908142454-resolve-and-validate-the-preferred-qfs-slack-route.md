---
created_at: 2026-09-08T14:24:54+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-slack-intake-honor-its-declared-binding-and-complete-thread-coverage
merge_policy:
verification_handoff: 
---

# Resolve and validate the preferred QFS Slack route

## Overview

Resolve the declared preferred QFS Slack mount at loop startup and prove its account, private-channel
reach, sender identity, and read/write maps before accepting it as the active binding.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/transport/scripts/resolve-target.sh` — select the declared route without label guessing.
- `plugins/workaholic/skills/transport/scripts/observe-channel.sh` — perform startup describe and reachability checks.
- `plugins/workaholic/skills/qfs-slack/` — discover live mounts, private views, and post/reply maps.

## Implementation Steps

1. Diagnose the current hard-coded `/slack` describe path against live named mounts and stored account labels.
2. Enumerate QFS connections and describe the declared mount's channel views plus post and reply maps.
3. Verify workspace, channel ID, account/profile, sender identity, and required operations as one inseparable binding.
4. Return typed zero-match, multi-match, missing-scope, and channel-unreachable outcomes without silently selecting a connector route.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A declared reachable mount wins deterministically; an unverifiable profile label never stands in for a verified Slack sender.

**Verification method** — the commands/tests/probes that prove them:

- Run resolver and live-description fixtures for one match, missing private membership, ambiguous accounts, missing maps, and missing identity scope.

**Gate** — what must pass before approval:

- No Slack read or write begins until the preferred route's declared destination and identity have been checked.

## Considerations

QFS account labels and operator-facing profile names are distinct facts; preserve both and report when Slack scopes cannot connect them.
