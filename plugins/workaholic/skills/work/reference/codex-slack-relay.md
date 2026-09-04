# Codex Slack relay v1

The relay crosses a capability boundary; it does not move the capability. A connector-less
`codex exec` worker returns intent and evidence to the connector-owning chat. Only that parent
may search, read, post, reply, or react in Slack. OAuth material never enters either JSON file.

The envelope protocol is `workaholic.codex-slack-relay/v1`. It contains a non-empty `tick_id`,
the tick `outcome` (`ok`, `pending`, or `blocked`), and ordered `slack_intents`. Every intent has
a stable, unique `key`, a `channel`, and one closed operation:

- `search_exact`: `query` plus `private_inclusive: true`;
- `read_thread`: `thread_ts`;
- `post_root`: exact `text`;
- `post_reply`: exact `thread_ts` and `text`;
- `add_reaction`: exact `timestamp` and `emoji`.

The text, lookup tokens, coordinates, and shape come from `workaholic:notify`; the relay never
invents them. An envelope carries no `notified` field because requested delivery is not delivery.
It carries no token, cookie, OAuth value, connector handle, or fuzzy lookup result.

The parent validates the envelope with `relay-contract.sh envelope <path>`, executes intents in
array order through its existing Slack connector, and writes one acknowledgement result for every
intent key. Outcomes are `delivered`, `post_refused`, `thread_unresolved`, `parent_absent`, or
`invalid_intent`. It validates with `relay-contract.sh acknowledgement <envelope> <ack>` and reads
the aggregate with `relay-contract.sh reconcile <envelope> [ack]`. Unknown protocols, operations,
duplicate keys, missing results, wrong tick identities, and malformed operation fields fail closed.

Retries reuse the same intent key. Before a write, the parent applies `workaholic:notify`'s exact,
private-inclusive lookup or the supplied trigger/thread coordinate and reads the thread. Existing
byte-identical roots, receipts, proposal lines, and finish lines acknowledge as `delivered` without
posting again. Partial replay attempts only results not already acknowledged as delivered.

The parent must remain present for this handshake. A free-running CLI/IDE supervisor has no chat
to return to: pending intents are `parent_absent`, never `delivered`, and readiness/status says
`relay_pending` or `relay_incomplete`. The supported unattended connector path is a Scheduled task
inside the owning chat; it executes one tick, consumes any worker envelope before ending, and uses
the same connector that chat already owns.
