---
created_at: 2026-09-08T14:24:54+09:00
status: done
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

## Final Report

Development completed as planned.

`transport/scripts/describe-qfs.sh` is the one describer: a declared mount is described directly
and wins deterministically, and only an undeclared binding enumerates connections before falling
back to the aggregate `/slack` describe. `observe-channel.sh` and `check-slack-channel.sh` both
composed it and stopped carrying the hard-coded `/slack` path. `resolve-target.sh` now verifies
required operations (`operations_unsatisfied`) and refuses a profile label as a sender
(`sender_unverified`), and stamps `channel_verified`, `sender_verified` and `declared_digest`
onto the canonical binding.

**Scope deviation, stated**: the ticket's Key Files named a new `plugins/workaholic/skills/qfs-slack/`
skill. The discovery is one script, and a skill directory would have added a cross-agent bundle
namespace and a second home for provider description while `transport` already owns it. It ships
as `transport/scripts/describe-qfs.sh` instead. Nothing in the Quality Gate depends on the path.

### Discovered Insights

- **Insight**: The describe response shape differs by qfs version — some answer the mount, older
  ones answer the whole `/slack` listing — and the mount must be taken out of a listing by its own
  path, never by position. A positional read is how a describe of one mount silently returns
  another one's workspace, account and sender.
  **Context**: The same aliasing tolerance already existed in the two callers; centralising it
  meant the positional hazard had to be answered once rather than twice.
- **Insight**: An empty describe body had to be rejected as "not a described route". Accepting
  `{}` produced a fully-formed observation with default operations and an unverified channel —
  a route manufactured out of a describe that said nothing, which is exactly the fabricated
  evidence the resolver's `described: true` flag is supposed to exclude.
  **Context**: Found by a fixture whose stub answered `{}` for an unknown mount; a real qfs errors,
  but nothing guaranteed that and the failure would have been silent.
- **Insight**: A jq `select` inside a pipe rebinds `.`, so `($m.operations | index(.))` tests the
  operations array against itself and every route passes. The operations filter silently did
  nothing until the required operation was bound with `. as $op` first.
  **Context**: Worth remembering wherever these scripts filter one array by another; the failure
  mode is a gate that always passes, which no output distinguishes from a gate that is satisfied.
