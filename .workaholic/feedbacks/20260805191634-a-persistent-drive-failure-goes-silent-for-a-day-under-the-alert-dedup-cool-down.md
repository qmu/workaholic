---
type: Feedback
title: A persistent drive failure goes silent for a day under the alert-dedup cool-down
kind: concern
source: discussion
created_at: 2026-08-05T19:16:34+09:00
author: a@qmu.jp
supersedes: 
---

# A persistent drive failure goes silent for a day under the alert-dedup cool-down

The hourly [Drive] routine fired on schedule at 11:56, 12:56, 13:56 and 14:56 JST on 2026-08-05 and produced nothing: no claim commit, no Slack post, no PR — while two claimable backlog tickets sat in the queue the whole time. From the routines list and from Slack it was indistinguishable from a healthy idle fleet, and it was noticed only because a developer asked what was running.

Two mechanisms combine to produce that silence, and each is individually correct.

The tick almost certainly stops at its own precondition: a cloud session binds a superseded plugin cache directory (measured at 1.0.112 against a 1.0.132 registry in a [Propose] session the same afternoon), and since PR #230 /drive terminates 'pending' on loaded_version_behind_registry before surveying. That is the gate working as designed.

The alert that would have said so is suppressed by the §0a dedup rule: the same failure signature 'stale-plugin-load' was posted once at 08:01 JST, and the rule suppresses a repeat of the same signature for 24 hours. That rule exists for a measured reason — one near-identical red post per hour for two days — and it is right that a repeat does not re-post. What it did not anticipate is a signature that persists for the whole cool-down: the operator sees one alert in the morning and then a channel that looks exactly like a working fleet with nothing to do, for the rest of the day.

The gap is between 'this failure was already reported' and 'this failure is still happening'. An idle tick and a suppressed-failure tick are distinguishable in the session log, deliberately — but nobody reads the session log of a tick that posted nothing. Worth considering: a periodic re-assertion inside the cool-down (a thread reply on the original alert, or a single daily restatement) so a persistent outage stays visible without restoring the hourly repeat; and separately, whether the routine can repair the binding it detects instead of only reporting it.
