---
type: Feedback
title: Precondition stops should post calm, escalating to red only on persistence
kind: instruction
source: discussion
created_at: 2026-08-10T21:29:24+09:00
author: a@qmu.jp
supersedes: 
---

# Precondition stops should post calm, escalating to red only on persistence

A scheduled run that stops at a known, self-healing precondition — the plugin unbound in a fresh cloud session (`unbound_in_claude_session`), a superseded binding after a version bump (`loaded_version_behind_registry`) — must not be posted to Slack looking like an emergency: not the red-circle shape. These stops are the expected cost of the first tick after a plugin release; the bootstrap has already repaired the environment by the time the post is read, and the next tick proceeds normally, so an alarming red root over-reports a condition the loop absorbs by design. Reserve the red shape for genuine failures: a precondition stop should read calm — a neutral or pause shape — on its first occurrence, and escalate to the alarming form only when the same failure signature persists across consecutive ticks, so a broken fleet still never reads as healthy idle. The existing red-alert dedup rule already keys on the stable failure signature; what changes is the severity of the first report, not the visibility of persistence.
