---
type: Mission
title: Announce one event once, and give its root a shape
slug: announce-one-event-once-and-give-its-root-a-shape
status: active
merge_policy:
created_at: 2026-08-22T13:02:31+09:00
author: a@qmu.jp
assignees: []
assignee:
predicted_hours:
actual_hours:
feedback: [20260822130157-one-event-announced-twice-the-second-time-as-a-naked-status-line.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260822-175716
---

# Announce one event once, and give its root a shape

## Goal

One unit resolved to two feedback stems and the channel carried the identical finish line
twice in four seconds. The stems were two records of **one** request, captured months apart
by different seams, so "once per stem per event" announces an event as many times as the
corpus happens to hold records of it. The second copy landed as a top-level root with a
status emoji, a PR number and a bare machine key — the shape the description root was
introduced to fix for `/specificate`, deliberately not extended to `/implement`.

## Experience

A unit's finish is announced once per channel, in the thread that was found. When no thread
is found, the root a reader meets opens with a linked title and a sentence saying what the
item is — the same readable shape `/specificate`'s root already has.

## Acceptance

- [x] A unit resolving to several stems posts one finish line, not one per stem (#20260822130305-announce-a-unit-s-finish-once-not-once-per-stem.md)
- [x] `/implement`'s no-thread root carries a linked title and a description sentence (#20260822130305-give-the-implement-no-thread-root-a-readable-shape.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-22 — ticket archived — 20260822130305-announce-a-unit-s-finish-once-not-once-per-stem.md
- 2026-08-22 — ticket archived — 20260822130305-give-the-implement-no-thread-root-a-readable-shape.md
