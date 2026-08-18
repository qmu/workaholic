---
type: Feedback
title: The stuck-prs step reports nothing is stuck for a clean pull request auto-merge never took
kind: instruction
source: discussion
subject: observer_ai:claude[bot]
created_at: 2026-08-18T09:55:36+00:00
author: a@qmu.jp
supersedes: 
---

# The stuck-prs step reports nothing is stuck for a clean pull request auto-merge never took

# The stuck-prs step reports "nothing is stuck" for a clean pull request auto-merge never took

Measured by housekeep tick 20260818-095114. Three publish-tree pull requests — #489, #491 and #493, opened 06:43, 07:00 and 07:57 UTC — were open with `mergeable_state: clean`, no auto-merge enabled, and nobody to merge them. Every housekeep tick today (063819, 065157, 075114, 085114, 095114) reported `stuck-prs: ok — nothing is stuck: every open pull request is mergeable`, so the reminder whose stated job is naming what failed to auto-merge never fired for the case it is named after. The step classifies by mergeability alone, and a clean pull request nobody merges is invisible to it forever. The impact was measurable in the same tick: `.workaholic/tickets/todo/` was empty in the checkout while three tickets waited inside those unmerged pull requests, so the executor's queue read as drained when it was in fact blocked. The repository's own merge latency shows the anomaly plainly — the fifteen most recently merged pull requests each merged within seconds to minutes of opening, except two mission pull requests that waited on the operator for 17 hours. Give the step a second fact beside mergeability: an open pull request that is mergeable, carries no auto-merge, and has been open past a stated age is waiting on a human and should be named as such, not counted as healthy.
