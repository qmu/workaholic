---
type: Feedback
title: The operator rejects provisioning a Slack bot identity
kind: instruction
source: discussion
subject: person:tamura.yoshiya@gmail.com
created_at: 2026-08-31T22:17:57+09:00
author: a@qmu.jp
supersedes: 
---

# The operator rejects provisioning a Slack bot identity

The operator rejected provisioning a Slack bot identity for the loop.

The measurement stands and is not in dispute: every post reaches Slack as the operator's own
account (verified on `#coop-planner` — each `🔎 Moderation` root is authored by
`Yoshiya Tamura <a@qmu.jp>`), Slack notifies nobody of their own message, so the `🙋`
question's mention resolves to the poster and pages nobody. What was refused is the repair's
**cost**: creating a Slack App, granting `chat:write`, inviting it to the channel and setting
`SLACK_BOT_TOKEN` on the routines' cloud environment.

Every alternative was checked before the refusal was accepted, and none reaches a Slack
notification: `notifications: push` collides with the standing instruction to turn routine
completion notifications off (ticket `20260818203011`), a self-DM has the same self-post
problem, and the Claude Tag route is retired. **There is no way to make Slack notify the
operator without a bot identity.**

So the mission `notify-the-person-a-directed-question-addresses` cannot reach its stated
Experience and is closed `abandoned`. Its machinery is **not** discarded — the six
implementation tickets were already driven, green and open at PR #758, and the transport
falls back to today's connector post with no token set, so the pull request was merged: the
tokened transport gained `--thread-ts` (a strict improvement to the machine fallback, which
could not thread before), the rule naming which transport carries which shape is stated, and
the drill is registered. Only the provisioning ticket is abandoned.

**Do not re-propose a bot identity, an app token, or any Slack-side credential** until the
operator says otherwise. A proposal that needs one is refused at the ask.
