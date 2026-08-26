---
type: Mission
title: Answer what is waiting, and stamp what was accepted
slug: answer-what-is-waiting-and-stamp-what-was-accepted
status: achieved
merge_policy:
created_at: 2026-08-26T11:22:29+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260826112010-make-moderate-answer-what-is-waiting-and-fix-where-acceptance-is-visible.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260826-114429
---

# Answer what is waiting, and stamp what was accepted

## Goal

One message named three gaps in how the loop is legible to the person it works for. A
captured ask leaves no mark on itself, so from the channel it looks exactly like an
ignored one. And the tick asks only about what its own steps found this hour, so
anything sitting unanswered reaches nobody — the failure that produced this very
message, filed by hand after a tick saw it and told no one.

## Experience

A person reading `#dev-workaholic` can tell what the loop accepted and what is still
waiting on them, without opening a thread or going to GitHub — and each surface speaks
the language they read it in.

## Acceptance

- [x] A message on the channel sitting unanswered reaches a named person through the
      tick's check-in, mention or no mention, and is asked exactly once. (#20260826112310-ask-about-a-message-that-has-been-sitting-unanswered.md)
- [x] A message the inbound sweep files carries a reaction stamp on the message itself. (#20260826112310-stamp-a-swept-message-with-a-reaction.md)
- [x] `CLAUDE.md` states the language rule: Japanese for `#dev-workaholic` reasoning and
      Claude Code Web routines, English for GitHub and `.workaholic/` artifacts. (#20260826112310-write-the-surface-language-rule-into-claude-md.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-26 — ticket archived — 20260826112310-write-the-surface-language-rule-into-claude-md.md
- 2026-08-26 — ticket archived — 20260826112310-stamp-a-swept-message-with-a-reaction.md
- 2026-08-26 — ticket archived — 20260826112310-ask-about-a-message-that-has-been-sitting-unanswered.md
- 2026-08-26 — mission achieved — mission.md
