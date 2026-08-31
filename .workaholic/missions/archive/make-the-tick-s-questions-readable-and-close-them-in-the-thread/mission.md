---
type: Mission
title: Make the tick's questions readable and close them in the thread
slug: make-the-tick-s-questions-readable-and-close-them-in-the-thread
status: achieved
merge_policy:
created_at: 2026-08-31T20:08:20+09:00
author: a@qmu.jp
assignees: []
assignee:
predicted_hours:
actual_hours:
feedback: [20260831200350-make-the-tick-s-slack-questions-self-explanatory-and-close-the-loop-in-the-thread.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260831-114321
---

# Make the tick's questions readable and close them in the thread

## Goal

A question opens with a machine subject — a unit id, a path, a verdict, a slug — and
assumes the reader knows which step asked and why, while the operator reads it on Slack
with nothing else at hand. When they answer there, the tick records it and stamps a
reaction but posts nothing: the thread never says what came of it.

## Scope

`workaholic:notify`'s catalog, each step's question spec in
`moderate/reference/workflow.md`, `step-question-answers.sh`, one reader, one drill.
Not the keys, caps or holds.

## Experience

The operator reads one question and knows, without opening the repository, what
happened and what to decide. After they answer, that thread carries the answer as
recorded and what came of it — once.

## Acceptance

- [x] Every question leads with the plain fact and the act it asks for, inside the
      existing one-sentence bound, with no key, cap or hold moved. (#20260831200959-rewrite-each-step-s-question-to-that-contract.md)
- [x] Once the loop has acted on an answer, one reply in that question's thread
      carries the answer as recorded and its outcome, never load-bearing. (#20260831200959-reply-the-answer-and-its-outcome-into-the-thread.md)
- [x] Proved offline by a drill with a breaker row, in the drill register. (#20260831200959-drill-the-outcome-reply-offline.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-31 — ticket archived — 20260831200916-state-what-a-tick-s-question-must-carry.md
- 2026-08-31 — ticket archived — 20260831200959-rewrite-each-step-s-question-to-that-contract.md
- 2026-08-31 — ticket archived — 20260831200959-read-what-a-recorded-answer-became.md
- 2026-08-31 — ticket archived — 20260831200959-give-the-answer-s-outcome-a-reply-shape.md
- 2026-08-31 — ticket archived — 20260831200959-reply-the-answer-and-its-outcome-into-the-thread.md
- 2026-08-31 — ticket archived — 20260831200959-drill-the-outcome-reply-offline.md
- 2026-08-31 — mission achieved — mission.md
