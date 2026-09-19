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
**conflict** that settles no value and is reported. `declared: false` **under `ok: true`** is an
ordinary answer — such a repository runs on its environment variables exactly as before. Read
`ok` first: `declared` is a field on a hard refusal (`no_root`, `unreadable:<source>`) as much as
on an empty answer, so an `ok: false` reading is `binding_unreadable:<reason>` and is never
reported, audited or written against as *this repository declares nothing*.

**`--root` is optional and defaults to the repository the caller is standing in**
(2026-09-19, ticket `20260919230600`) — `git rev-parse --show-toplevel`, resolved before the
validity test, with an explicit `--root` always winning. It removes the commonest way to reach
`no_root`: a required argument whose omission answers `declared: false` does not fail loudly, it
reads as *this repository declares nothing* and the loop falls back to the environment, which is
the misdelivery the declaration exists to prevent. The default is the repository **root** and
never `pwd`, because the sources are composed against it. `no_root` stays exact — outside any
repository with no `--root`, and an explicit `--root` that is not a directory — and every call
site in the tree passes `--root` and is byte-identical.

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

**Where the discovery operation refuses, the WATCH SET is read instead** (2026-09-17, ticket
`20260917123453`). A route that does not carry `list_thread_changes` used to leave the fallback
with nothing to read at all, so a reply under a root the loop had seen five minutes earlier went
unanswered for as long as the provider kept refusing. Every root the channel delta names and
every explicit Slack permalink in a message's text now joins a **durable, bounded** watch set —
`watch_threads` on the binding record, newest `WORKAHOLIC_WATCH_SET_MAX` (default 50), one
revision-checked write after the captures, `watch_set_unwritten` on a refusal — and the fallback
reads it newest first through the same one classifier, bounded by the same fan-out. It is
**evidence, never coverage**: the status stays `partial` with the **discovery's** own reason and
`source: watch_set_fallback`, and the fallback's own failure rides `fallback_reason` beside it
rather than overwriting a refusal that never happened.

## Discovering mentions outside the read window

The mention reading was a text test over the channel delta, so a mention on a root older than the
window — or in a reply, which channel history never carries — could not be seen at all, and
nothing registered the thread either, so the next tick looked past it too (2026-09-17, ticket
`20260917122814`). `observe-channel.sh` searches the channel's own history for the declared
sender's mention token through `search_exact`, **one bounded call per tick**, joins every
coordinate it finds to the watch set, and **reads it immediately** (`WORKAHOLIC_MENTION_FANOUT`,
default 3) — a mention is the one discovery that means a person is waiting.

**One thread is read at most once per tick**, whichever arm named it: three arms can name one
coordinate and a second read could only return duplicates. **The search captures nothing** —
capture is per surface, and capturing there makes the thread read see its own message as a
duplicate, so the classifier, which emits only new ids, drops the very reply the arm exists to
route. **A search is not an index**: `coverage.mentions` reports `searched`, `discovered`,
`tracked` and `exhaustive: false`, never a completeness claim, because zero rows certify nothing;
an absent `sender_id` leaves the arm unrun and the reading `unreadable`.

**`search_exact` is deliberately NOT added to a binding's declared `operations`.** A declared
operation is a **required** one — `resolve-target.sh` refuses `operations_unsatisfied` when no
route can satisfy it — so declaring it would make a route that cannot search fail the whole
observation rather than lose one arm of it. Route selection reads what the describe advertised,
not what the declaration requires, so the arm runs wherever the route carries it and is refused
`operation_unavailable` where it does not. An operator who wants the search guaranteed declares
it and accepts that refusal.

## When an observation may be called quiet

`observation_settled` is the one derivation of whether a read may be reported as the channel
having nothing new. It is false while any of four terms stands, each named in `unsettled[]`:
**`channel_delta_incomplete`** (`has_more` still true — a spent page budget, or a later page that
could not be read), **`thread_coverage_partial`**, **`thread_fanout_truncated`**, and
**`sender_identity_unverified`**. `plan-poll.sh` answers **`observation_incomplete`** in place of
`quiet` while one stands; `settled` **absent means settled**, so a caller that does not pass it
behaves exactly as before. It moves the **word and never the cadence** — an unread page already
forces an immediate re-poll, and a standing limitation would otherwise shorten the interval
forever, which is a spin rather than a repair.

The channel delta is drained inside the one call to make the first term mean something:
`read_channel_delta` is paged until `has_more` is false or `WORKAHOLIC_CHANNEL_PAGES` (default 5)
is spent, each page captured before the next is asked for — so page N+1's lower bound is page N's
own advanced cursor with **no** overlap, and the boundary message is dropped by the existing
provider-id dedup. `window_since` rides the **first** page only, because the capture is the one
writer of the unproved mark. A spent budget leaves `has_more` standing with
`channel_pages_exhausted` rather than reading as a drained channel.

## The binding record and the unproved interval

`observe-channel.sh` keeps one runtime record per resolved binding (`runtime/scripts/state.sh`,
scope `binding`): `cursor`, the newest coordinate a **proved** read captured, advanced only by
`capture-inbox.sh` after every message of the page survived; and **`unproved_since`**, the
coordinate from which the channel has not been read. An unproved read — a refused route, a
provider failure, a capture that did not complete — writes `unproved_since` once (the stored
cursor, or the read's own time when no cursor exists; an earlier value is kept) and never the
cursor. Every later read derives `overlap_seconds` as the greater of the standing 300 and
`now − unproved_since`, on the channel delta and the thread discovery alike, so the interval
that was never read is re-read once; `capture-inbox.sh` clears the mark only inside the same
revision-checked write that advances the cursor, and only when the request's `window_since`
(the lower bound the read actually asked for) reached it. The observer reports
`observation_proved`, `unproved_since`, `overlap_seconds`, `window_since` and
`cursor_advanced`, so a tick can say *unread since* rather than *quiet*.

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
