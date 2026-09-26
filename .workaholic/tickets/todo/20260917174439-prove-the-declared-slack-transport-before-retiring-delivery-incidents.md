---
created_at: 2026-09-17T17:44:39+09:00
author: a@qmu.jp
assignees: []
depends_on:
feedback: [20260901002017-the-moderation-tick-has-no-slack-transport-that-reaches-the-loop-s-channel.md, 20260909222245-verify-the-qfs-root-map-by-matching-not-by-counting-and-emit-add-reaction.md]
merge_policy:
verification_handoff: a verified Slack sender plus declared read_channel_delta, read_thread, list_thread_changes, post_root, post_reply, and add_reaction capabilities are not available in the unattended environment
claim: work-20260926-163546
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

### 2026-09-21 — implementation step 4's emitter, and the limitation re-measured

**The gate had a reader and no writer**, so the document it refuses on was hand-made in a shape
described only inside its own jq program — a gate whose input nobody can check. Implementation
step 4's first half (*emit durable per-operation proof*) is now
`plugins/workaholic/skills/transport/scripts/emit-live-proof-evidence.sh`: it writes the evidence
template from every fact the repository establishes with no credential — the declaration's
`declared_digest`, workspace, channel and declared sender, one row per declared operation, and
the route reading `describe-qfs.sh` already makes — and leaves exactly the facts a credential is
needed for empty. **It never writes `proved: true`**: a route that *advertises* an operation has
a capability and the gate asks whether it was *performed*, so `available` carries the capability
reading while `proved` stays false, which is the ticket's own gate (*no issue is marked delivered
from configuration presence … or `operations_unsatisfied`*) enforced at the writer rather than
only at the reader. A describe nobody could make answers **`available: null`, never `false`** —
`false` means the route answered and does not carry the operation. It performs no Slack read or
write, needs no credential and decides nothing; `verify-live-proof.sh` stays the one gate.
Refusals: `root_required`, `binding_unreadable`, `not_declared`, `jq_unavailable`, nothing
written. Documented in `skills/transport/SKILL.md`, *Proving the declared route before an
incident is retired*, and in `CLAUDE.md`; pinned hermetically by
`scripts/test-workflow-scripts.mjs` (*the live-proof evidence emitter states capability and never
claims a performed act*), which runs it with no `qfs` on `PATH` and asserts the null-not-false
degradation, `proved: false` on every row, and that the emitted template alone leaves all eleven
incidents unresolved.

**The prose `verification_handoff:` was re-measured here rather than taken on its own words**
(`/drive` §6, `unmeasured`). `describe-qfs.sh --workspace qmu --channel dev-workaholic` on this
machine, 2026-09-21: two mounts reach the channel (`/slack` account `team`, `/slack-cc-for-qmu`
account `cc-for-qmu`), both `channel_verified: true`, both advertising **only**
`read_channel_delta`, `read_thread`, `search_exact`, both `sender_id: null` /
`sender_verified: false`, and both carrying the limitations `sender_unverified`,
`thread_discovery_unavailable` (`threads_not_selectable`), `reaction_map_unverified`,
`root_map_unverified_or_ambiguous`. So four of the six declared operations —
`list_thread_changes`, `post_root`, `post_reply`, `add_reaction` — are unavailable on every
reachable route and no route can prove who would speak. The declared limitation is **present**,
and the handoff stands on that measurement.

**What the operator must still do**, unchanged in substance and now bounded: declare the verified
`sender_id` in `AGENTS.md`, run
`sh plugins/workaholic/skills/transport/scripts/emit-live-proof-evidence.sh --root . --out proof.json`,
perform the bounded root/reply/reaction through a route that carries those four operations, fill
each performed operation's `proved` and the `round_trip` block in `proof.json`, then run
`sh plugins/workaholic/skills/transport/scripts/verify-live-proof.sh --root . --evidence proof.json`
and retire the incident set only on `closure_eligible: true`.
