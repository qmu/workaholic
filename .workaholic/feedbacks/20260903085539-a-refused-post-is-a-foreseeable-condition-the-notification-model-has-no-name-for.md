---
type: Feedback
title: A refused post is a foreseeable condition the notification model has no name for
kind: instruction
source: slack
subject: person:YO
created_at: 2026-09-03T08:55:39+09:00
author: a@qmu.jp
supersedes: 
---

# A refused post is a foreseeable condition the notification model has no name for

Source: https://github.com/qmu/workaholic/issues/942

The operator's words: 拒否されるのがおかしい、これは想定内の挙動だと — a refused post is not an
accident to report and forget, it is a foreseeable condition of the environment the loop runs in.

## What was measured

Two `/implement` runs, same machine, same identity, same session, minutes apart. One had every
`slack_send_message` denied by the harness permission classifier: its `🟢 Implemented` and two
`🟡 Handoff` lines were never posted, and the run reported the refusal honestly, did not retry,
and ended. The other posted three `🟡 Handoff` lines through the same connector without incident.
So the refusal is per-call, not a property of the deployment, and nothing in the notification
model expects that.

`workaholic:notify` states a three-branch transport model: the connector is primary, the tokened
`notify-slack.sh` is the fallback for a caller with no connector, and neither available means the
post does not exist and the run says so. This deployment has `SLACK_BOT_TOKEN` unset, so the
middle branch does not exist, and a connector call that is *refused* — as opposed to *absent* —
lands on the third branch, which was written for a session that never had a transport at all.
The run followed the model correctly and lost the message.

And the posts that did land notified nobody: the three delivered `🟡 Handoff` lines carry no
mention token, because the unit's assignee resolves to the posting identity and the skill's own
rule is never to mention the identity you are posting as. The skill's answer to that case is that
a **directed** shape takes the **bot** identity so the mention becomes real — and with no token it
"falls back to today's behaviour", a post addressed to nobody. Six handoff and finish lines in one
session: three refused outright, three reached a channel while paging no one, every one of them
waiting on one person's act.

## What the ask asks for

- A refused connector call is its own named degradation — `post_refused`, distinct from
  `no_slack_transport`. One is *this session cannot post*; the other is *this call was denied and
  the next may not be*. Collapsing them turned a retryable failure into a terminal one.
- It is retried on the next tick rather than dropped. The loop turns every five minutes, so a post
  that failed once has a natural second chance; nothing carried it forward. The unit's story
  already exists as the place to leave an unsent line.
- The single-transport reality is named. With `SLACK_BOT_TOKEN` unset the two-transport model is
  one transport, and the directed shapes (`🙋`, `🟡 Handoff`) provably reach nobody — so either a
  deployment emitting directed shapes requires the token, or those shapes say plainly that they
  landed in a channel and paged no one, so an absent answer is not read as silence from the person.
