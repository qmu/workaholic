---
type: Feedback
title: Discover existing QFS mounts and private channels before stopping work
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-09-09T13:06:25+09:00
author: a@qmu.jp
supersedes: 
---

# Discover existing QFS mounts and private channels before stopping work

GitHub Issue: https://github.com/qmu/workaholic/issues/1127

During a `work` session on Workaholic 1.0.342 the coordinator reported `no_connection`, failed to
locate the target through a different Slack connector, and stopped the loop asking the operator
for connection details. After the operator named the existing QFS account, `qfs connect --list`
immediately showed its authorized non-default Slack mount, and querying that mount's
`private-channels` collection returned the requested channel — the public `channels` collection
returned no matches. The operator asked that the binding be persisted in `AGENTS.md` and that the
failure be sent back to Workaholic rather than ending in an in-chat acknowledgement.

The ask: make the work/transport discovery path enumerate actual mounts and bound accounts and
inspect installed private-channel views before concluding that Slack is disconnected. A failure on
an assumed mount or an unrelated connector must stay scoped to that route. Preserve and use an
operator-supplied binding through the existing `workaholic-slack-binding` declaration, and verify
that a subsequent tick uses it. Cover an absent default mount, an authorized named mount, and a
private-only target channel, resolving the intended account and channel without unnecessary
operator setup requests or a false disconnected report.

The operator states this establishes a discovery failure in the session, not yet a proven defect
in one particular helper script.
