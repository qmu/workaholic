---
type: Mission
title: Make routine notifications one semantic story
slug: make-routine-notifications-one-semantic-story
status: achieved
merge_policy: 
created_at: 2026-08-04T20:12:16+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours: 0.6
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
feedback: [20260804101847-make-workaholify-record-the-fb-to-merge-lifecycle-as-one-semantic-slack-thread.md, 20260804085719-make-the-web-routine-notify-slack-only-and-filter-what-it-posts.md, 20260804102558-balance-structure-and-prose-in-fb-issue-authoring.md, 20260804143009-the-drive-routine-s-handoff-section-still-says-resumption-is-impossible.md]
claim: work-20260804-112542
---

# Make routine notifications one semantic story

## Goal

The routines' outward voice is noise: per-step "PR opened"/"PR merged" posts that
thread to nothing, the same event pushed twice (Slack and the mobile app), FB
issues that swing between heading-heavy and structureless prose, and a [Drive]
template whose §5 still asserts a resumption gap that was closed on 2026-08-01 —
a stale premise that §1's live scheduling rule cites as its reason. Four Slack
instructions from 2026-08-04 ask for one thing: a developer following a feedback
item should read its whole life in one place, and read nothing that is not worth
reading.

## Experience

An FB ask starts one Slack thread ("Proposed to @dev", with a [Proposal]-prefixed
PR and the routine session's URL) and every later event of that item — review,
merge, drive outcome (merge requested / merged / auto-merged / handoff) — lands
in that same thread, each with its session URL. Slack is the only notification
surface; a post exists only for events a developer must act on or know about,
with repeat alerts of one failure signature deduplicated. FB issues read as
prose with light structure only where a multi-step ask needs it, and the [Drive]
template's stated model matches the shipped resumption behavior.

## Acceptance

- [x] The routine templates post the FB lifecycle as one thread — root plus in-thread updates with session URLs — and the per-step top-level posts are gone (#20260804201230-thread-the-fb-lifecycle-into-one-semantic-slack-story.md)
- [x] Slack is the sole notification surface and the templates define which events merit a post, reusing the low-severity-drop and same-signature-dedup patterns (#20260804201230-make-slack-the-only-notification-surface-and-filter-it.md)
- [x] The [Drive] template's §5 states the shipped resumption model and §1's unit rule is re-derived from it (#20260804201230-truth-up-the-drive-template-s-resumption-model.md)

## Changelog

<!-- Append-only, dated timeline relating this mission's tickets and reports over time.
     One line per event ("- YYYY-MM-DD — event — filename"); never rewrite past lines. -->
- 2026-08-04 — ticket archived — 20260804201230-truth-up-the-drive-template-s-resumption-model.md
- 2026-08-04 — ticket archived — 20260804201230-thread-the-fb-lifecycle-into-one-semantic-slack-story.md
- 2026-08-04 — ticket archived — 20260804201230-make-slack-the-only-notification-surface-and-filter-it.md
- 2026-08-04 — ticket archived — 20260804201230-balance-structure-and-prose-in-fb-issue-authoring.md
- 2026-08-04 — run recorded (+0.6h) — drive-20260804-112542
- 2026-08-04 — mission achieved — mission.md
