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

For each operation, prefer a QFS route only when its map was actually described.
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
