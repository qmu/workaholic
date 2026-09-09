---
type: Mission
title: Make the declared Slack route speak, be seen and be named
slug: make-the-declared-slack-route-speak-be-seen-and-be-named
status: achieved
merge_policy:
created_at: 2026-09-09T13:08:24+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours: 2.6
feedback: [20260909130802-detect-replies-in-recent-ongoing-slack-threads.md, 20260909091200-one-jq-typo-silences-every-slack-reply-the-loop-owes.md, 20260909104345-refuse-a-post-that-cannot-speak-as-the-declared-sender.md, 20260909090459-name-the-destination-in-the-binding-report-instead-of-a-boolean.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260909-175052
---

# Make the declared Slack route speak, be seen and be named

## Goal

The declared QFS route is preferred everywhere and works nowhere. `qfs-native.sh:63` guards its
commit on `.total_affected`, which QFS answers at `.preview.total_affected.exact`, so a correct
preview refuses every post. `describe-native-qfs.sh` advertises no `list_thread_changes`, so a
reply under yesterday's root is never seen. And the fallback that takes over speaks as the
operator: 94 of 98 messages in one channel are the loop's shapes under a person's account.

## Experience

The loop's posts arrive as the declared sender, or do not arrive and say why. A reply under an
older root is discovered, and the tick names where it posted.

## Acceptance

- [x] A correct provider preview commits; the guard reads the count where the provider answers it. (#20260909130912-commit-a-post-on-a-correct-qfs-preview.md)
- [x] A new reply under an older root is discovered on the declared route, or the gap is named. (#20260909130912-discover-thread-replies-on-the-native-qfs-route.md)
- [x] A post that cannot speak as the declared sender is refused, not sent as a person. (#20260909130912-refuse-a-post-that-cannot-speak-as-the-sender.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-09 — ticket archived — 20260909130912-commit-a-post-on-a-correct-qfs-preview.md
- 2026-09-09 — ticket archived — 20260909130912-discover-thread-replies-on-the-native-qfs-route.md
- 2026-09-09 — ticket archived — 20260909130912-refuse-a-post-that-cannot-speak-as-the-sender.md
- 2026-09-09 — ticket archived — 20260909130912-name-the-destination-in-the-tick-s-report.md
- 2026-09-09 — mission achieved — mission.md
- 2026-09-09 — story — work-20260909-175052.md
- 2026-09-09 — run recorded (+2.6h) — implement-t16
