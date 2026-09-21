---
created_at: 2026-09-17T17:44:39+09:00
author: a@qmu.jp
assignees: []
depends_on:
feedback: [20260901002017-the-moderation-tick-has-no-slack-transport-that-reaches-the-loop-s-channel.md, 20260909222245-verify-the-qfs-root-map-by-matching-not-by-counting-and-emit-add-reaction.md]
merge_policy:
verification_handoff: a verified Slack sender plus declared read_channel_delta, read_thread, list_thread_changes, post_root, post_reply, and add_reaction capabilities are not available in the unattended environment
claim: work-20260921-124857
---

# Prove the declared Slack transport before retiring delivery incidents

## Overview

Give the repeated Slack delivery incidents (#806, #939, #1095, #1101, #1106, #1114, #1167, #1173, #1179, #1182, #1184) one bounded repair and verification unit. The current QFS mounts can read channel deltas and known threads, but cannot prove thread-change discovery, root posting, reactions, or sender identity; `operations_unsatisfied` is unreadable coverage, not delivery.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/monitoring-and-observability.md` — delivery claims require observable end-to-end proof
- `workaholic:safety` / `policies/access-control.md` — sender credentials and channel authority remain operator-controlled

## Key Files

- `AGENTS.md` — declared Slack destination, identity, operations, and fallback order.
- `plugins/workaholic/skills/transport/scripts/describe-qfs.sh` — capability and identity evidence.
- `plugins/workaholic/skills/transport/scripts/observe-channel.sh` — channel/thread coverage result.
- notification delivery and moderation-root scripts — root/reply/reaction proof and incident reconciliation.

## Implementation Steps

1. Preserve one incident set keyed by the declared binding so repeated undelivered roots do not become independent repair plans.
2. After the operator provides a verified route, probe every declared read/write operation and sender identity without advancing cursors on partial coverage.
3. Post one bounded test root, reply, and reaction; read the resulting channel delta and thread change back through the declared route.
4. Emit durable per-operation proof and offer the incident set for closure only when all declared capabilities and sender identity are verified.

## Quality Gate

**Acceptance criteria** — all declared operations work against `qmu/dev-workaholic`, the sender is verified, and a written root/reply/reaction is read back from channel/thread deltas. Any missing operation keeps every affected incident unresolved.

**Verification method** — run transport fixtures first, then one live end-to-end probe using the operator-provided connector or token and preserve its typed coverage/delivery result.

**Gate** — no issue is marked delivered from configuration presence, `post_reply` alone, or `operations_unsatisfied`; closure requires end-to-end live evidence.

## Considerations

The code portion is claimable now, but live acceptance is a handoff because this repository deliberately declares no verified sender. Do not provision, rotate, or expose a credential from this ticket.

## Progress Report

Added a binding-locked live-proof validator that keeps all eleven incidents unresolved unless every declared operation, the verified sender, and the root/reply/reaction readback are present in one matching evidence document. The current repository preflight returns `unverifiable_sender` and `incidents_unresolved: 11`, consistent with `AGENTS.md`; no Slack write was attempted. Operator handoff: add the verified `sender_id`, use the declared connector to perform the bounded root/reply/reaction and readbacks, save the typed evidence, then run `sh plugins/workaholic/skills/transport/scripts/verify-live-proof.sh --root . --evidence <proof.json>` and proceed only when `closure_eligible: true`.
