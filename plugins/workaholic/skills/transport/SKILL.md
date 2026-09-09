---
name: transport
description: Resolve and perform loop communication through QFS, parent connectors, or an existing Slack token while preserving target identity and durable delivery state.
user-invocable: false
---

# Transport

Transport owns destination resolution, provider selection, typed observations,
and delivery evidence. `workaholic:notify` continues to own message wording and
which events may be posted.

Requests and results use `workaholic.transport/v1`. Resolve a target before any
operation that can cause an effect. A binding identifies mount, account,
workspace, channel, sender, and observed operations; a channel name alone is
never enough when more than one workspace matches.

## The declared binding

The repository names its own destination once, in the instruction file every agent
already loads — a fenced `workaholic-slack-binding` block (`scripts/schemas/binding.schema.json`).
`scripts/read-declared-binding.sh` is its **one reader**: it takes `CLAUDE.md` and `AGENTS.md`
at the root, then the same two under each `--scope`, then `WORKAHOLIC_SLACK_BINDING_FILE`;
a deeper scope **overrides** a shallower one, and two sources at one depth disagreeing is a
**conflict** that settles no value and is reported. `declared: false` is an ordinary answer —
such a repository runs on its environment variables exactly as before.

Read the declaration **before** selecting a route: it is the target discovery is judged
against, never a hint added afterwards. `declared_digest` is the operator's declaration
hashed, carried onto the resolved binding as `declared_digest` so an effect planned against a
superseded declaration is refused rather than delivered somewhere the operator no longer means.

## Resolving the preferred route

`scripts/describe-qfs.sh` describes what QFS actually offers. A **declared mount is described
directly** and wins deterministically; only an undeclared binding enumerates connections and
falls back to the aggregate `/slack` describe. Describing the literal path `/slack` was a guess —
qfs mounts a connection under its own name — and on a machine whose mount is named it returned
nothing while a working route sat one path segment away.

It never guesses. A mount whose channel list was read and does not carry the channel is a
`public_miss` observation, which is evidence of not seeing rather than of absence; a mount whose
channel list could not be read carries `channel_verified: false` all the way onto the binding;
an empty describe body is not a described route at all. An `account` is an operator-facing
label and is never offered as `sender_id`. Refusals are typed and none is a verdict about the
channel: `qfs_unavailable`, `connections_unreadable`, `no_connection`, `mount_not_described`,
`missing_scope`, `no_route`.

`resolve-target.sh` then verifies workspace, channel, account, sender and **required
operations** as one binding. Operations narrow after the two ambiguity checks, so
`target_unverified` still means *nothing reaches this channel* and `operations_unsatisfied`
means *a route reaches it and cannot do what was declared*. `require_verified_sender` refuses
`sender_unverified` rather than letting a profile label stand in for an identity Slack proved.
The canonical binding carries `channel_verified`, `sender_verified` and `declared_digest`.

**A declared sender is a term of the binding, and a write that cannot be proved to speak as it
is refused rather than delivered under another identity.** The refusal needs no caller opt-in:
a target that declares `sender_id` and matches a route on everything **but** that sender is
refused `sender_unverified` — *a route reaches this channel and cannot prove who would speak* —
where it used to be conflated with `target_unverified`. On the write path the same term is
settled before any route is chosen, and the refusal is **recorded**: the outbox goes `refused`
so a repeat answers `delivery_refused`, and the result carries `sender_mismatch` with
`route: null` and `preferred_route_verified: false`, so an unavailable identity is visible
rather than inferred from a channel's message counts. Measured in one channel: 94 messages from
the operator's own account, 3 from a bot, and **0** from the declared sender. **A binding that
declares no `sender_id` is unchanged** — the advisory `unverifiable_sender` names that
repository, and never posting is not this rule's remedy for it.

## Discovering thread replies

Slack channel history does not carry a reply under an older root, so `read_channel_delta` can
never see one and a coverage claim based on it is false for exactly the messages people most
expect an answer to. `list_thread_changes` asks which **threads** changed inside the same
bounded overlap window, by their own coordinates and independently of any known-thread list;
`observe-channel.sh` then reads each changed thread **whole** before classifying anything in it,
captures its messages through the same dedup, and routes each new human reply
`moderation_answer` / `answer_to_loop` / `reaction_only` / `needs_judgement`.

The fan-out is bounded (`WORKAHOLIC_THREAD_FANOUT`, default 5) and reported: a truncated page
is `truncated: true`, never silence. `coverage.threads.status` is **`covered` only when the
discovery operation ran**, and `partial` with its reason otherwise. Never replace the bounded
delta with a full-channel or every-thread scan; partial provider coverage stays explicit.

## Typed fallback and revalidation

For each operation, prefer a QFS route only when its map was actually described. An operation
leaves the preferred route **only on a named failure**: `qfs_unavailable` (availability),
`qfs_operation_unavailable` / `qfs_map_unverified` (capability), and `qfs_preview_failed`
(reachability). `qfs_preview_refused` preserves the refusal and never changes route to escape
an authorization decision. Every other failure keeps the operation
where it was declared — an untyped switch is how a route nobody configured starts carrying the
traffic while every report says it succeeded.

**A read may also leave on a reachability failure; a write may not.** Every write class above
fails *before* `--commit`, so nothing was accepted and the fallback is a first attempt. A
`qfs_connector_failure` or `accepted_send_timeout` happens after it: the outbox goes `unknown`
and the effect is reconciled, never resent over another route.

The declared `fallback` order governs; absent keeps the historical order, and an explicitly
**empty** one forbids every fallback. Workspace, channel ID, thread timestamp and expected
sender ride the handoff verbatim — a fallback that re-resolved the destination would be a
different destination. Every result carries `route`, `degraded`, `degraded_from`,
`degradation_reason` and **`preferred_route_verified`**: a connector or token success proves
delivery and proves nothing about the preferred route's configuration or about who spoke.

A caller that knows which declaration it resolved against passes `expected_declared_digest`; a
binding carrying a different `declared_digest` is refused **`binding_stale`** before any effect,
so a resolution never outlives the declaration it came from. Absent on both sides, nothing
changes.

Use a parent connector reaching the same binding when QFS cannot perform that
operation. Keep the configured Slack token route as compatibility fallback and
never require a new credential. A parent round trip returns `needs_parent`; pass
the result through `accept-observation.sh` before using it.

Persist each send under its stable request ID before invoking a provider. A
timeout after acceptance becomes `unknown` and is reconciled by reading the same
destination. Never immediately resend an unknown effect. A read result observes
messages; it is not a delivery acknowledgement.

Scripts emit one JSON result on stdout. A typed result exits 0, invalid input
exits 2, and an internal script failure exits 1.

## Native QFS pipe-SQL

Discovery accepts `connect --list` TSV and `describe` path/children/verbs responses, including
`/slack-<account>` mounts. The native adapter normalizes `ts,user` into message identifiers and
senders, reads replies at `messages/<ts>/replies`, and uses verified INSERT maps with QFS default
preview (not a `--preview` flag). **The affected count is read where the provider answers it** —
QFS nests it at `.preview.total_affected` as `{"exact": N}`, and reading only the top-level
`.total_affected` made every correct preview refuse, because `null > 0` is false. Both nestings
and a bare number are read; a preview whose count no reading can find stays `qfs_preview_refused`,
the honest word for *the preview did not say what was affected*, and only a preview positively
stating an affected row may commit. A committed write without a Slack timestamp remains an unknown
effect requiring reconciliation. Generic `service_rejected` does not establish missing scope.

**Thread discovery on this dialect is proved, never assumed — in either direction.** The
collection `list_thread_changes` queries is described and the driver's own `verbs.select` is the
proof: only then is the operation advertised and the `thread_discovery_unavailable` limitation
dropped, and the adapter's arm is reachable only through that advertisement. An unproved route
declares the limitation carrying the reason the describe gave (`thread_collection_verified`,
`thread_discovery_reason`: `threads_not_selectable` / `threads_not_described`), so a provider
that has no such collection is named rather than guessed at. Measured 2026-09-09 on
`/slack-cc01-qmu/qmu/C0BLL9J7FMY`: the channel node advertises only `messages` and `files`, so
the limitation stands there. Reaction maps, ambiguous root maps and sender verification remain
explicit capability limitations; a successful channel read does not certify any of them.
