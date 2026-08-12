---
type: Mission
title: Stop a routine finish line from vanishing on the script path
slug: stop-a-routine-finish-line-from-vanishing-on-the-script-path
status: active
merge_policy:
created_at: 2026-08-12T20:40:49+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260812203825-stop-a-routine-finish-line-from-vanishing-on-the-script-path.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260812-204905
---

# Stop a routine finish line from vanishing on the script path

## Goal

PROPOSED. A routine session carries the Slack MCP connector and no
`SLACK_BOT_TOKEN`, but `drive/SKILL.md`, `drive/reference/routing.md` and
`propose/reference/workflow.md` all name `notify-slack.sh` as the way to post the
finish line. Taking that path returns `{"notified": false, "reason": "no_token"}`
and the post silently never exists — so the FB thread root is missing and every
later reply roots a new top-level line. `workaholic:notify` owns the model but
names no transport; that gap is what the run picks arbitrarily.

## Experience

PROPOSED. A `[Propose]` or `[Implement]` run in a connector-only session posts its
finish line into the feedback item's thread, every time. When no surface can post,
the run report says the line went unposted instead of reading as if it had been
sent.

## Acceptance

- [x] `workaholic:notify` states the transport rule — connector primary, tokened
      script as the machine fallback — and every call site defers to it instead of
      naming `notify-slack.sh` (#20260812204122-make-workaholic-notify-own-the-finish-line-transport.md)
- [x] A run whose finish post did not reach Slack reports that outcome in its own
      terminal report rather than treating it as posted (#20260812204216-report-an-unposted-finish-line-as-unposted.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-12 — ticket archived — 20260812204122-make-workaholic-notify-own-the-finish-line-transport.md
- 2026-08-12 — ticket archived — 20260812204216-report-an-unposted-finish-line-as-unposted.md
