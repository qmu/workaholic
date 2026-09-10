---
type: Mission
title: Make Slack intake incremental across messages, threads, and mentions
slug: make-slack-intake-incremental-across-messages-threads-and-mentions
status: achieved
merge_policy:
created_at: 2026-09-08T12:38:03+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260908123552-slack-bot.md, 20260908123606-honor-repository-declared-qfs-slack-bindings-before-connector-fallback.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260908-124606
---

# Make Slack intake incremental across messages, threads, and mentions

## Goal

Replace repeated broad Slack scans with one bounded incremental intake model that binds each connection to its real identity and destination, discovers new top-level posts, thread replies, and mentions, and shares deduplication state across loop cadences.

## Experience

Each tick reads only new relevant activity, continues conversations after an unmentioned thread reply, keeps multiple bot identities separate, and can state both the API cost and any scope it could not read or write.

## Acceptance

- [x] Every Slack connection is bound to a verified account, bot/user identity, channel, and reply capability. (#20260908123811-bind-slack-connections-to-verified-bot-identities-and-destinations.md)
- [x] One incremental collector covers new top-level posts, active-thread replies, and addressed mentions with a shared overlap-safe cursor. (#20260908123811-collect-incremental-top-level-thread-and-mention-activity.md)
- [x] Reads and thread writes report measured calls, confirmed delivery, and unreadable or unauthorized coverage explicitly. (#20260908123811-verify-thread-replies-and-report-unreadable-slack-coverage.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-08 — ticket archived — 20260908123811-bind-slack-connections-to-verified-bot-identities-and-destinations.md
- 2026-09-08 — ticket archived — 20260908123811-collect-incremental-top-level-thread-and-mention-activity.md
- 2026-09-08 — ticket archived — 20260908123811-share-intake-cursors-and-deduplicate-every-loop-consumer.md
- 2026-09-08 — ticket archived — 20260908123811-verify-thread-replies-and-report-unreadable-slack-coverage.md
- 2026-09-08 — mission achieved — mission.md
- 2026-09-10 — ticket archived — 20260908124152-declare-and-audit-a-repository-local-slack-transport-binding.md
- 2026-09-10 — ticket archived — 20260908124152-resolve-qfs-slack-first-and-type-every-connector-fallback.md
