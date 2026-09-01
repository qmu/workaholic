---
type: Feedback
title: The moderation tick has no Slack transport that reaches the loop's channel
kind: instruction
source: development
subject: observer_ai:tamurayoshiya
created_at: 2026-09-01T00:20:17+00:00
author: a@qmu.jp
supersedes: 
---

# The moderation tick has no Slack transport that reaches the loop's channel

# The moderation tick has no Slack transport that reaches the loop's channel

Source: https://github.com/qmu/workaholic/issues/806

The `/moderate` tick at `20260831-235117` held no Slack transport that could reach the loop's channel, so every question it would have asked and every thread it would have read was undeliverable. Both transports were probed and both were out: the connector is authenticated against a workspace that holds none of the loop's channels (`slack_read_thread` on `C0BLL9J7FMY` — the channel every recorded question coordinate names — answered `channel_not_found` on four separate coordinates, and `slack_search_channels` found no `dev-workaholic` and no channel matching `workaholic` at all, public or private), and the bot fallback is absent (`notify-slack.sh` answered `no_token`; neither `SLACK_BOT_TOKEN` nor `WORKAHOLIC_SLACK_CHANNEL` is set on the environment the routines select). The channel was reachable hours earlier the same day — ticks `20260831-095146`, `20260831-085129`, `20260831-075109` and `20260831-015114` all recorded the same coordinate — so this is a change, not a standing condition. The cost that tick: `render-tick-post.sh` returned `post: true` with 7 changes and 2 impaired steps and reached nobody; 18 held questions stayed held, among them a stranded claim, six undrivable units, three blocked retirements, five stuck pull requests and a dormant direction; 8 outstanding questions could not be read for answers, so a person who had already replied in a thread was not heard; 5 thread-reconcile candidates could not be read or corrected; and `unanswered-asks` reached `channel_unreadable` rather than `window_empty`, so nothing may be inferred about what is waiting. No ask was recorded as asked, so the ledger is untouched and every held question is still held.

The ask names two routes to the repair, and both are provisioning rather than code: re-authorize the Slack connector against the workspace that holds `#dev-workaholic`, or provision the bot fallback (`SLACK_BOT_TOKEN` plus `WORKAHOLIC_SLACK_CHANNEL`, with the bot a member of that channel) on the cloud environment the routines select. The ask argues route 2 is the more durable of the two: it is the transport `workaholic:notify` already designates as the machine fallback, it is the one the directed question reply is meant to ride, and it does not depend on which workspace an interactive account happens to be authorized against. The finding reproduces from an interactive session and not only from the routine's container, which narrows it to the connector's workspace authorization rather than a per-container fault.

The one part of the ask that was code has already landed: issue #807, merged as `e42570f`, makes a tick whose rendered post says *post* and whose every transport is out file the rendered root as one `[FB]` issue through `file-inbound-ask.sh`, carrying it verbatim and naming why each transport was out — one issue for the hour, with the ledger untouched. That answers the ask's own open question of whether such a tick should report its root somewhere durable. On the remaining half the operator ruled directly, on the issue, on 2026-09-01: "This issue stays open because the repair is yours, not the loop's."
