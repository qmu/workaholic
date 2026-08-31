---
type: Feedback
title: Give the asking path a bot identity so a directed question actually notifies its addressee
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-08-31T04:16:51+00:00
author: a@qmu.jp
supersedes: 
---

# Give the asking path a bot identity so a directed question actually notifies its addressee

Source: https://github.com/qmu/workaholic/issues/756

The operator's words, from the ask:

Measured 2026-08-30 on a repository running this loop, in the single-developer
configuration that is the normal one. Three items sat waiting on operator input (two
repository variables and one secret); the handoff pull requests and the finish replies
recorded them faithfully in their items' threads, and the operator still discovered them
only by asking a session directly — twice — because nothing had notified them and the
asks were folded into thread replies they had no reason to reopen.

The gap is structural, not a session's omission. `workaholic:notify` already rules
*never mention the identity you are posting as*, on the measured ground that the
connector posts as the developer's own account and Slack never notifies anyone of their
own message. The unstated consequence: wherever the posting identity and the addressee
are the same person, the directed question — the one post shape whose whole purpose is
to reach a person — notifies nobody, by construction. The moderation tick's mentioned
replies, the handoff finish lines, and any waiting-on-a-person item all share this: they
are visible only to an operator who happens to reread the channel. The tokened fallback
(`notify-slack.sh`, `SLACK_BOT_TOKEN`) is the one transport with a different identity,
but it is defined as a degraded fallback that cannot thread, so no call site may choose
it for its identity.

The ask: give the asking path an identity that is not the addressee. Concretely,
sanction bot-identity posting as the carrier for directed questions and for
waiting-on-a-person handoff asks — a bot token the routine holds, posting the mention as
the bot so the mention actually fires — with the connector remaining the carrier for
everything else (roots, finish lines, the lookup). Done means: a directed question
addressed to the operator produces a notification the operator receives without
rereading the channel, and the notify model states which transport carries which shape
and why.
