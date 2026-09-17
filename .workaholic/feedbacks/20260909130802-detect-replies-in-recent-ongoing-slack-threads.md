---
type: Feedback
title: Detect replies in recent ongoing Slack threads
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-09-09T13:08:02+09:00
author: a@qmu.jp
supersedes: 
---

# Detect replies in recent ongoing Slack threads

GitHub Issue: https://github.com/qmu/workaholic/issues/1132

Failing to detect a new reply in a relatively recent Slack thread continuing from yesterday makes
Workaholic monitoring useless. The required behaviour is to discover new comments in such ongoing
threads — including when the root predates the current channel-history window — and to monitor the
conversation more frequently after human activity is detected. The supplied example is a reply
posted today under a root from yesterday; its private Slack coordinates are omitted from the
cross-repository report.

Observed in the loaded Workaholic 1.0.343 runtime: `observe-channel.sh` read the declared channel
through QFS and returned `channel_verified: true`, but reported thread coverage as `partial`,
`discovered: false`, `reason: operation_unavailable` for `list_thread_changes`, and returned no new
input IDs. Sender verification was separately unavailable. These observations establish incomplete
thread discovery, not the absence of replies; the linked reply content was not independently read.
The adaptive polling policy already specifies a 30-second interval after activity, but that policy
cannot help a reply the observation path never discovers.

The ask: make detection and the subsequent faster observation work through the supported Slack
transport for recent ongoing threads, and verify the end-to-end case of a new reply today under
yesterday's root. Coverage limitations must stay explicit until detection is actually available; a
successful channel delta alone must not be presented as effective thread monitoring.
