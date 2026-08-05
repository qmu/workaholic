---
type: Feedback
title: [Propose] roots a new Slack thread even when the trigger message already is the item's thread
kind: instruction
source: slack
created_at: 2026-08-05T02:14:14+00:00
author: noreply@anthropic.com
supersedes: 
---

# [Propose] roots a new Slack thread even when the trigger message already is the item's thread

When the `[Propose]` routine is triggered by a message a developer posted in the repository's `dev-<repo>` Slack channel, its announcement always opens a brand-new top-level thread root instead of replying inside the thread that triggered it. The developer asks that the routine reply within the triggering message's own thread whenever it can identify one, so that a feedback item keeps a single thread.

On 2026-08-05 a developer reported, in a Slack thread rooted at a 10:55 JST message about routine notifications not rendering the Slack username as a mention, that the underlying issue had been addressed. The `[Propose]` routine then announced the follow-up proposal, PR #238, as a new top-level message rather than as a reply in that thread, leaving one item with two roots in the channel. Nothing in the routine can repair that afterwards: it has no Slack message-deletion capability, so collapsing two roots back into one is a human act. The originating thread is https://qmu.slack.com/archives/C0BLL9J7FMY/p1785894939122119.

The cause is a gap in the `workaholify` skill's *One thread per feedback item* convention, which finds an existing thread only by searching the channel for the feedback record's `fb:<stem>` key. That key is minted by the very session that posts it, so a developer's own message — written before the record existed — carries no key and can never be matched by that search, however recent or visible it is in the channel. The key search is sound for routine-originated items; it simply has no answer for an item whose first message is human.

The ask is to add the trigger-message case alongside the existing key search, not to replace it: when a session can identify the Slack message or thread that triggered its run, it replies there; otherwise the key search and its new-root fallback stand unchanged. The rule belongs in the `workaholify` SKILL's *One thread per feedback item* section, where the notification model is stated once, and in the three routine templates under `plugins/workaholic/skills/workaholify/routines/` — `fb.md`, `merged-pr.md` and `drive.md` — which implement it.
