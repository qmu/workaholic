---
type: Mission
title: Register every /fb as an issue
slug: register-every-fb-as-an-issue
status: active
merge_policy:
created_at: 2026-08-17T13:31:32+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260817133031-unify-fb-to-always-register-a-github-issue-regardless-of-destination.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260817-173706
---

# Register every /fb as an issue

## Goal

`/fb` has two shapes today: a destination-less ask becomes a file in
`.workaholic/feedbacks/`, an ask naming another repository becomes a GitHub issue. Make
it one shape — every ask becomes an `[FB] `-marked issue — so the Slack (Claude Tag) FB
route and `/fb` produce the same result, and the caller need not remember which
deliverable a destination buys.

## Experience

A developer runs `/fb <ask>` with no destination. An `[FB] `-marked issue opens on this
repository, assigned to them, and the command reports its URL. No local record is
written on that path — the receiving `[Propose]` tick discovers the issue, registers the
record itself, and judges it. When the issue cannot be opened, the feedback is still
captured rather than lost, and the command says which path it took.

## Acceptance

<!-- PROPOSED sketch, not a plan — the reviewer interrogates this to drive-ready. -->

- [x] The issue writer takes an assignee and accepts this repository as its target. (#20260817133224-give-the-fb-issue-writer-an-assignee-and-this-repo.md)
- [x] A destination-less `/fb` opens that assigned issue, writes no record on that path,
      and `[Propose]`'s discovery ingests it unchanged. (#20260817133224-route-a-destination-less-fb-to-an-in-repo-issue.md)
- [x] `/fb` never loses an ask when the issue cannot be opened. (#20260817133224-keep-the-record-as-fb-s-fallback-when-the-issue-fails.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-17 — ticket archived — 20260817133224-give-the-fb-issue-writer-an-assignee-and-this-repo.md
- 2026-08-17 — ticket archived — 20260817133224-route-a-destination-less-fb-to-an-in-repo-issue.md
- 2026-08-17 — ticket archived — 20260817133224-keep-the-record-as-fb-s-fallback-when-the-issue-fails.md
