---
type: Mission
title: Notify the person a directed question addresses
slug: notify-the-person-a-directed-question-addresses
status: active
merge_policy:
created_at: 2026-08-31T04:21:25+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260831041651-give-the-asking-path-a-bot-identity-so-a-directed-question-actually-notifies-its-addressee.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260831-044223
---

# Notify the person a directed question addresses

## Goal

Every post reaches Slack as the operator's own account, and Slack notifies nobody of
their own message — so the directed question, whose whole purpose is to reach a person,
notifies its addressee never. The tokened transport posts as a bot but is a fallback no
call site may pick for its identity, and cannot thread.

## Scope

`notify-slack.sh`, `workaholic:notify`'s transport model and catalog, the check-in
post, the handoff line, the two routine templates, one drill. Not the lookup or the
roots.

## Experience

When the loop has a question for the operator, they are notified without rereading the
channel: the mention fires because a bot posted it. Roots, finish lines and the lookup
still ride the connector unchanged. With no bot token a session behaves exactly as
today and says which surface carried each post.

## Acceptance

- [x] The tokened transport replies into a thread the connector resolved, under the
      same `chat:write` scope, every existing call byte-identical. (#20260831042312-teach-the-tokened-transport-to-reply-into-a-thread.md)
- [ ] The model states which transport carries which shape and why; directed shapes
      ride the bot, everything else the connector, a missing token falls back to
      today's behaviour reported by name. (#20260831042312-state-which-transport-carries-which-shape-and-why.md)
- [ ] Proved offline by a drill with a breaker row, registered in the drill register,
      and the operator confirms one directed question notified them. (#20260831042313-provision-the-bot-identity-and-confirm-it-notifies.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-31 — ticket archived — 20260831042312-teach-the-tokened-transport-to-reply-into-a-thread.md
