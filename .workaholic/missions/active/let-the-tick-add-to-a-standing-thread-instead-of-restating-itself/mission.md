---
type: Mission
title: Let the tick add to a standing thread instead of restating itself
slug: let-the-tick-add-to-a-standing-thread-instead-of-restating-itself
status: active
merge_policy:
created_at: 2026-09-01T12:24:08+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260901122046-the-tick-can-only-behave-like-a-bot-a-per-tick-thread-key-a-banned-recency-match-and-a-string-diff-post-gate.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260901-123859
---

# Let the tick add to a standing thread instead of restating itself

## Goal

The root is keyed `tick:<tick-id>`, so the lookup can never match the previous hour: 14
roots in one window, 12 with no questions. And the post gate is a `cmp` over summaries the
stabilizer barely touches, so `stuck-prs` — embedding a per-pull state list — opens a root
on a value GitHub merely answered differently. The gate built to stop noise produces it.

## Experience

One standing root per day, and an hour with something to add replies into it. A summary
that moved only because a transport answered differently earns no root. And the skill says
what the tick repairs and who repairs the rest.

## Acceptance

- [x] A day's first speaking tick opens the root; every later one replies into it, still by
      exact-string key. (#20260901122448-reply-an-hour-s-changes-into-the-day-s-standing-root.md)
- [x] A summary that moved only because a transport answered differently opens no
      root. (#20260901122448-keep-a-transport-derived-state-list-out-of-the-post-gate.md)
- [ ] `workaholic:moderate` says what the tick may repair and who does the
      rest. (#20260901122448-say-what-the-tick-repairs-on-what-proof-and-who-does-the-rest.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-01 — ticket archived — 20260901122448-derive-the-tick-s-thread-key-from-the-day-not-the-tick.md
- 2026-09-01 — ticket archived — 20260901122448-reply-an-hour-s-changes-into-the-day-s-standing-root.md
- 2026-09-01 — ticket archived — 20260901122448-keep-a-transport-derived-state-list-out-of-the-post-gate.md
