---
type: Mission
title: Point the inbound readers at the channel that exists
slug: point-the-inbound-readers-at-the-channel-that-exists
status: achieved
merge_policy:
created_at: 2026-08-29T06:28:06+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours: 0.6
feedback: [20260829062618-the-inbound-slack-channel-default-resolves-to-a-channel-that-does-not-exist.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260829-104123
---

# Point the inbound readers at the channel that exists

## Goal

Both readers of the repository's channel resolve `WORKAHOLIC_INBOUND_SLACK_CHANNEL`,
unset in the routine container, to the default `<repo_name>` — `workaholic`. This
workspace has no such channel: a private-inclusive search returns exactly one,
`#dev-workaholic` (C0BLL9J7FMY), where every post the loop makes lands. So the writer
finds its thread by exact-string lookup and succeeds, while the `:40` sweep and the
tick's `unanswered-asks` step are aimed at nothing. The inbound-from-Slack path is
dark, and quiet by construction.

## Experience

A question written in the repository's channel reaches a person. The routines name the
channel they actually post to, and a channel name that resolves to no channel is
reported by its own name — never as a quiet hour with nothing waiting.

## Acceptance

- [x] The `:40` sweep and `unanswered-asks` read `#dev-workaholic`, the channel the loop posts to. (#20260829062827-name-the-channel-the-routines-actually-post-to.md)
- [x] A channel that resolves to nothing is named as that, distinctly from an empty window. (#20260829062827-tell-an-unresolvable-channel-from-an-empty-one.md)

## Changelog
- 2026-08-29 — ticket archived — 20260829062827-name-the-channel-the-routines-actually-post-to.md
- 2026-08-29 — ticket archived — 20260829062827-tell-an-unresolvable-channel-from-an-empty-one.md
- 2026-08-29 — story reported — work-20260829-084119.md
- 2026-08-29 — ticket archived — 20260829093500-say-where-a-routines-environment-lives.md
- 2026-08-29 — mission achieved — mission.md
- 2026-08-29 — story reported — work-20260829-104123.md
- 2026-08-29 — run recorded (+0.6h) — run-20260829-104123
