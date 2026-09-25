# Agent instructions

Portable guidance for every agent working in this repository. The full engineering standard is
`CLAUDE.md`; this file carries only what an agent that does not read `CLAUDE.md` still needs.

## Slack binding

The development loop reads this declaration before it selects any Slack route
(`plugins/workaholic/skills/transport/scripts/read-declared-binding.sh`, the one reader). One
destination, one speaking identity, one fallback order — declared once, here, rather than in an
environment variable no portable agent can see.

```workaholic-slack-binding
workspace: qmu
channel: dev-workaholic
channel_id: C0BLL9J7FMY
mount: /slack
account: team
operations: read_channel_delta, read_thread, search_exact
fallback: connector, slack_token
```

`sender_id` is deliberately **not** declared here: this repository has
no verified Slack sender to name, and a profile label is not one. The audit
(`workaholify/scripts/check-slack-binding.sh`) therefore reports `unverifiable_sender`, which is
the true state — every write stays unable to certify who spoke until the operator adds the ID.

**`mount`, `account` and `channel_id` are declared because without them the loop cannot read the
channel at all** (2026-09-21, measured in this checkout). Three readings, each reproducible with
one `qfs run`: Slack's `conversations.history` answers `channel_not_found` for the channel
**name** and returns rows for the **id**, so a binding carrying no `channel_id` addresses nothing;
two described mounts reach `C0BLL9J7FMY` (`/slack` as `team`, `/slack-cc-for-qmu` as
`cc-for-qmu`), so a declaration naming neither is refused **`ambiguous_identity`** by
`resolve-target.sh` — correctly, because guessing between two destinations is the failure the
declaration exists to prevent — and that refusal fires even when only the read operations are
asked for.

**The operations list is narrowed to the three a reachable route actually advertises, and the cost
is stated.** A binding is verified as one inseparable unit, so demanding `post_root`, `post_reply`,
`add_reaction` and `list_thread_changes` beside the reads made **every** read fail
`operations_unsatisfied` — measured as a total observation blackout while the channel itself was
readable the whole time. Of those four, `post_root` is refused by a counting error of our own
(issue #1259: `describe-native-qfs.sh` requires exactly one `/sys/drivers` row for the messages
map where six exist, one carrying `chat.postMessage`; the node itself answers `verbs.insert: true`),
`add_reaction` by an unconditional `reaction_map_unverified`, while `post_reply` and
`list_thread_changes` are genuinely absent on every reachable route. So the narrowing **costs the
loop no capability it had** — it could not post through this route either way — and buys back the
observation clock. Restore the write operations here in the same change that closes #1259, not
before: a declared operation no route can satisfy takes the reads down with it.

**Posting route.** The declared `/slack` mount reads; posts go through the `cc-for-qmu` bot,
which is a member of the channel: `insert into /slack-cc-for-qmu/qmu/C0BLL9J7FMY/messages values
(text) ('…')` with `--commit` (`workaholic:watch`). The path is `<mount>/<workspace>/<channel_id>/messages`;
omitting the workspace segment misroutes the channel and answers `channel_not_found`. The qfs
Slack insert carries no `thread_ts`, so a reply is a channel post, not a thread reply.
`/slack-cc-for-osbr` is bound to a different workspace despite its account name `cc01-qmu`.
