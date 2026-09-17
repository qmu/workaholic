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
operations: read_channel_delta, read_thread, list_thread_changes, post_root, post_reply, add_reaction
fallback: connector, slack_token
```

`mount`, `account` and `sender_id` are deliberately **not** declared here: this repository has
no verified Slack sender to name, and a profile label is not one. The audit
(`workaholify/scripts/check-slack-binding.sh`) therefore reports `unverifiable_sender`, which is
the true state — every write stays unable to certify who spoke until the operator adds the ID.
