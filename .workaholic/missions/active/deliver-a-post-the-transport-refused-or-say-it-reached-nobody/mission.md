---
type: Mission
title: Deliver a post the transport refused, or say it reached nobody
slug: deliver-a-post-the-transport-refused-or-say-it-reached-nobody
status: active
merge_policy:
created_at: 2026-09-03T08:58:14+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260903085539-a-refused-post-is-a-foreseeable-condition-the-notification-model-has-no-name-for.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260903-101727
---

# Deliver a post the transport refused, or say it reached nobody

## Goal

A denied Slack post is not an accident. Measured 2026-09-02, two `/implement` runs
minutes apart in one session: one had every call refused and lost three lines; the other posted
three of the same shape. With `SLACK_BOT_TOKEN` unset the model's middle branch does not exist,
so a *refused* call falls to the branch written for a session that never had one, and the run
says the post does not exist and stops. The three that did land carry no mention token, the
unit's assignee being the posting identity — six directed lines, three lost, three paging nobody.

## Experience

A post the transport refused is named as refused rather than as absent, is carried on the unit's
own record so the next tick can send it, and a directed shape that reached a channel while paging
nobody says so — so an absent answer is never read as silence from the person.

## Acceptance

- [ ] A refused connector call reports `post_refused`, distinct from `no_slack_transport`, on every surface that reports a notification outcome (#20260903085928-name-a-refused-connector-post-as-its-own-degradation.md)
- [ ] An unposted line is left on the unit's own story and re-sent by a later tick, once, without duplicating a line that landed (#20260903085928-carry-an-unposted-line-on-the-unit-story-for-the-next-tick.md)
- [ ] A directed shape posted with no mention token states that it paged nobody, and the deployment's single-transport reality is written where the transport model is stated (#20260903085928-say-when-a-directed-post-paged-nobody.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
