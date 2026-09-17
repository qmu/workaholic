---
type: Feedback
title: Restore automatic Slack mention discovery
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-09-17T12:28:03+09:00
author: a@qmu.jp
supersedes: 
---

# Restore automatic Slack mention discovery

kind: instruction / source: discussion / subject: person:tamurayoshiya

# Restore automatic discovery of Slack mentions outside already-known threads

Workaholic must notice a new Slack @mention or reply without requiring the operator to ask it to reread every thread. The current runtime can poll a thread whose root is already known, but it does not guarantee discovery of a mention posted in another existing thread. This makes the operator choose between expensive full-thread audits and missed instructions.

Issue #1132 was closed, but the operator has now re-reported the same user-visible gap on Workaholic 1.0.351. Add an efficient mention/reply discovery path across active Slack conversations, deduplicate discovered messages, and immediately begin the normal active-thread cadence after a mention is found. A channel-history read must not be treated as complete coverage of replies below older roots. Verification should cover a new mention under a root that is absent from the current channel-history window, without pre-seeding that root in the observer.


Source: https://github.com/qmu/workaholic/issues/1158
