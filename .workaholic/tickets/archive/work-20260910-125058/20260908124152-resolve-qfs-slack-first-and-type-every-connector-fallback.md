---
created_at: 2026-09-08T12:41:52+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-slack-intake-incremental-across-messages-threads-and-mentions
merge_policy:
verification_handoff: 
claim: work-20260910-125058
---

# Resolve QFS Slack first and type every connector fallback

## Overview

Make a validated QFS Slack binding a startup invariant and allow connector fallback only after a typed QFS capability, authorization, reachability, or availability failure.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/work/` — startup validation before the first Slack effect.
- `plugins/workaholic/skills/transport/` — QFS preference, typed degradation, and fallback.
- `plugins/workaholic/skills/qfs-slack/` — live mount, channel, identity, and map probes.

## Implementation Steps

1. Reproduce the silent connector fallback against declared and undeclared QFS bindings.
2. Enumerate live connections, describe the selected mount and paths, and verify private-channel read/write/reply reachability.
3. Verify sender identity when scopes allow and preserve exact uncertainty when they do not.
4. Bind connector fallback to typed QFS failure while preserving channel and thread identity, then revalidate before effects after changes or failures.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Reachable declared QFS bindings carry all Slack reads and writes under the declared sender.
- Every connector fallback names its QFS failure and preserves the declared destination and thread.

**Verification method** — the commands/tests/probes that prove them:

- Test QFS success, channel membership failure, missing reply map, missing identity scope, QFS unavailable, and connector fallback.

**Gate** — what must pass before approval:

- A successful connector read cannot certify that the preferred QFS sender is configured.

## Considerations

Operator-facing profile names and QFS account labels are separate identifiers and must never be treated as aliases without evidence.

## Final Report

Development completed as planned — **and, as with its sibling, the mechanism was already on the
base when this ticket was driven**, so this drive verified each acceptance criterion against the
tree rather than writing it a second time. It landed 2026-09-08/09 under the missions
`make-slack-intake-honor-its-declared-binding-and-complete-thread-coverage` and
`make-the-declared-slack-route-speak-be-seen-and-be-named`.

**Criterion 1 — reachable declared QFS bindings carry all Slack reads and writes under the
declared sender.** `transport/scripts/perform.sh` settles the identity **before a route is
chosen**: a target declaring a `sender_id` that no route can prove is refused `sender_mismatch`
with `route: null` and `preferred_route_verified: false`, and the outbox transitions to `refused`
so a repeat answers `delivery_refused` rather than trying again. `resolve-target.sh` refuses
`sender_unverified` — *a route reaches this channel and cannot prove who would speak* — without
the caller having to opt in, which is the distinction from `target_unverified` (*nothing reaches
this channel*). `describe-qfs.sh` describes a **declared mount directly** rather than guessing
the literal `/slack`, and never rounds an unread channel list up: an unreadable list carries
`channel_verified: false` and a list that was read and lacks the channel is a `public_miss` —
evidence of not seeing, never of absence. An `account` is an operator-facing label and is refused
as a `sender_id`.

**Criterion 2 — every connector fallback names its QFS failure and preserves the declared
destination and thread.** `qfs_fallback_class()` is the one derivation and the two consumers read
it: the read path at `perform.sh:159` and the write path at `perform.sh:308` both leave the
preferred route **only** on a named class, and every other failure keeps the operation where it
was declared. `connector_handoff()` carries workspace, channel ID, thread timestamp and expected
sender **verbatim** — a fallback that re-resolved the destination would be a different
destination. Every result is decorated with `route`, `degraded`, `degraded_from`,
`degradation_reason` and `preferred_route_verified`, the last true only for an `ok` result that
stayed on QFS, so a connector success is a **degraded** success that proves delivery and proves
nothing about the declared route or about who spoke.

**The six verification cases the gate names were each found present and typed**: QFS success
(`P3 QFS uses only a described operation and normalizes a successful read`); channel membership
failure (`public_miss`, `mount_not_described`); missing reply map (`qfs_map_unverified`, at
`perform.sh:171` and `:291`); missing identity scope (`missing_scope`, `sender_unverified`); QFS
unavailable (`qfs_unavailable`); and connector fallback (`P3 a fallback needs a typed failure,
keeps the destination, and never certifies the route`). `binding_stale` closes the loop on step
4's *revalidate before effects after changes* — a caller passing `expected_declared_digest` is
refused before any effect when the declaration has moved under it.

No gap in the mechanism was found and nothing under `transport/` was changed. One observation
outside this ticket's implementation scope was recorded as a ticket rather than fixed
opportunistically (below).

### Discovered Insights

- **Insight**: `qfs_preview_refused` is named in `CLAUDE.md` as one of the four typed classes an
  operation may leave the preferred route on, but `qfs_fallback_class()` maps it to **`none`** —
  an authorization refusal stays a refusal and never falls back.
  **Context**: the behaviour is right and matches the repository's own `not_permitted` doctrine
  for a refused merge (*an authorization denial stays a refusal*); it is the prose that groups it
  with the fallback-permitting classes. A reader implementing a new adapter from `CLAUDE.md`
  alone would route around a provider's refusal, which is the exact failure typed fallback
  exists to prevent. Minted as
  `20260910040721-say-that-an-authorization-refusal-never-falls-back.md`; the mechanism was
  deliberately left byte-identical.

- **Insight**: the split between `resolve-target.sh`'s `target_unverified` and
  `sender_unverified` is the one that makes a silent misdelivery detectable, and it works only
  because operations narrow **after** the two ambiguity checks.
  **Context**: reversing that order would let `operations_unsatisfied` (*a route reaches the
  channel and cannot do what was declared*) mask `target_unverified` (*nothing reaches this
  channel*), collapsing two different repairs — fix the declaration versus fix the connection —
  into one word. Worth preserving explicitly if this resolver is ever refactored.
