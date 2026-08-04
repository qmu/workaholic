---
type: Feedback
title: Make the web routine notify Slack only and filter what it posts
kind: instruction
source: slack
created_at: 2026-08-04T08:57:19+00:00
author: noreply@anthropic.com
supersedes: 
---

# Make the web routine notify Slack only and filter what it posts

The Claude Code web routine configured via /workaholify currently sends notifications both to the Slack channel and to the Claude mobile app, so a developer following the routine's activity receives the same event twice — once as a push notification, once as a Slack message. The ask is to stop the routine from sending mobile app notifications entirely, so Slack is the sole notification surface. Removing the mobile channel would reduce visibility unless Slack absorbs that role well, so the routine's system prompt should also define what is "necessary" to post there — not every internal step of a drive/survey tick, but the events a developer actually needs to stay aware of (e.g. a PR merged, a drive blocked on a real precondition failure, a drive started). This should build on patterns already adopted elsewhere in the repository — dropping low-severity items by default (as the branch story now does) and de-duplicating repeat alerts with the same failure signature (as the drive-blocked throttling now does) — applied here to decide, per event, whether it is worth a Slack post at all. Deliberately scoped to the notification channel and its filtering, not to the routine's actual work: the drive/survey logic is unaffected. Reported as qmu/workaholic#187.
