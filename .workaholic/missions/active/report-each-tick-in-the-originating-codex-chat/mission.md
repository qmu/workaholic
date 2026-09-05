---
type: Mission
title: Report each tick in the originating Codex chat
slug: report-each-tick-in-the-originating-codex-chat
status: active
merge_policy:
created_at: 2026-09-06T02:27:58+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260906022552-report-each-tick-in-the-originating-codex-chat-and-prove-it-end-to-end.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260906-023953
---

# Report each tick in the originating Codex chat

## Goal

The operator's third request for one behaviour: the loop's coordination lives in the chat it
was started in, and each tick's status and each task's outcome arrive there by themselves.
#987 closed #984 and #985 by repairing the timer and detaching the workers, verified against a
stub, and left the return path untouched. Asked to start work, the session launched the CLI
supervisor, ended its turn, and said this chat would get nothing — mode chosen by agent
name, not capability.

## Experience

Started in a chat, the loop keeps its parent turn: it reports each tick there, answers a
question mid-loop without cancelling it, delegates workers it does not wait for, and names
each outcome once. A missing mechanism is named at startup and left unresolved, never swapped
for a supervisor delivering somewhere else.

## Acceptance

- [x] The mode is selected from capabilities the session exposes; an absent delivery path is
      named at startup, not substituted. (#20260906022855-select-the-loop-mode-from-measured-capabilities.md)
- [x] While a delegated task outruns the interval, successive tick reports and its completion
      arrive in the originating chat unprompted. (#20260906022855-run-the-tick-as-a-native-parent-that-keeps-its-turn.md)
- [ ] The behaviour is demonstrated end to end in the operator's own chat, with timestamps,
      environment and version. (#20260906022907-prove-the-behaviour-in-the-operator-s-own-codex-chat.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-06 — ticket archived — 20260906022855-select-the-loop-mode-from-measured-capabilities.md
- 2026-09-06 — ticket archived — 20260906022855-run-the-tick-as-a-native-parent-that-keeps-its-turn.md
- 2026-09-06 — ticket archived — 20260906022855-delegate-each-due-role-as-a-bounded-native-child.md
