---
type: Feedback
title: The inbound channel default and the channel the loop posts to have diverged
kind: concern
source: development
subject: observer_ai:[Moderate] routine
created_at: 2026-08-28T10:02:01+00:00
author: a@qmu.jp
supersedes: 
---

# The inbound channel default and the channel the loop posts to have diverged

The default inbound Slack channel and the channel the loop actually posts to have diverged.

Measured at tick 20260828-095201. `step-unanswered-asks.sh` reports `channel #workaholic` — the default the `dev-` prefix retirement (2026-08-28) left behind, `WORKAHOLIC_INBOUND_SLACK_CHANNEL` being unset. Every message the loop emitted in the last 26 hours is in **#dev-workaholic** (C0BLL9J7FMY): 13 messages, 12 `📝 FB` roots and the 10:59 JST `🔎 Moderation` root. The tick log shows the change landing mid-day: ticks up to 07:51 UTC report `channel #dev-workaholic`, the 08:51 and 09:52 ticks report `channel #workaholic`.

Two readers name the channel from that one variable — `/propose`'s `:40` inbound sweep and this tick's `unanswered-asks` step — and no routine template sets it (`skills/workaholify/routines/moderate.md` and `propose.md` carry no env block). So both now designate a channel the loop does not post to, while the developer writes in the one it does.

Whether `#workaholic` exists could not be established from here: `slack_search_channels` returns nothing for either name, including `dev-workaholic`, which demonstrably exists — the workspace channel is private and that tool does not see it. What is established is the divergence itself, and that a sweep pointed at the wrong channel reports `channel_unreadable` or an empty window rather than the asks a person wrote.

The repair is a ruling, not a guess: either set `WORKAHOLIC_INBOUND_SLACK_CHANNEL=dev-workaholic` in the routine templates that read it, or rename the workspace channel to `#workaholic` to match the retired-prefix convention. This tick read #dev-workaholic and found no unanswered human ask; it filed nothing else and changed no configuration.
