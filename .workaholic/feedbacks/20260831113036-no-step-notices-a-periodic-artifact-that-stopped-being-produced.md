---
type: Feedback
title: No step notices a periodic artifact that stopped being produced
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-08-31T11:30:36+00:00
author: a@qmu.jp
supersedes: 
---

# No step notices a periodic artifact that stopped being produced

# No step notices a periodic artifact that stopped being produced

Source: https://github.com/qmu/workaholic/issues/761

On a consuming repository a scheduled routine that wrote a daily record stopped
producing for four days. Ticks ran every hour throughout and not one reported it.

The cause is structural rather than a missing check: all twenty-nine steps are driven by
objects that exist — open pull requests, open issues, commits since a ref, deployment
records, ticket and mission files, draft release notes. A routine that dies produces
nothing at all, so there is no object for any step to find. `workload-logs` shows the
shape plainly, reporting "nothing declares a workload log" as a healthy line, hourly,
indefinitely.

The tick watches presence and has no way to watch absence.

Please add a step that reads repository-declared cadences — the same declaration shape
`workload-logs` already uses — and raises a human-checkin item when the newest artifact
of a declared cadence is older than its period allows. Deduplicated through the tick log
so it asks once rather than hourly.
