---
type: Feedback
title: Introduce Handoff PR status for credential-blocked verification
kind: instruction
source: discussion
subject: observer_ai:claude[bot]
created_at: 2026-08-14T06:51:57+00:00
author: a@qmu.jp
supersedes: 
---

# Introduce Handoff PR status for credential-blocked verification

Going forward some development requests will be filed as FB issues from Claude Tag (the Slack bot) for work where it is already known in advance that the Claude Code web routine cannot verify real-world behavior, because the credentials are missing. In that scenario the resulting pull request should **not** be merged and marked "🟢 Implemented"; it should be handed off to a human developer and marked with a status such as "🟡 Handoff". A repository routine that aggregates, once a day, every pull request currently in the Handoff state is also under consideration — the aggregation target set being exactly those Handoff-state pull requests.

Source: https://github.com/qmu/workaholic/issues/452
