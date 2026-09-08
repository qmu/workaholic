---
type: Mission
title: Turn quiescent blockers into mature decisions and resume work
slug: turn-quiescent-blockers-into-mature-decisions-and-resume-work
status: active
merge_policy:
created_at: 2026-09-08T12:32:56+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260908123159-make-quiescent-loops-surface-decision-ready-blockers-and-reopen-after-answers.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260908-175401
---

# Turn quiescent blockers into mature decisions and resume work

## Goal

Make a human decision dependency an explicit, reviewable state of the development loop: test whether the question is mature, route only decision-ready blockers to the responsible person, and resume planning after the answer is recorded.

## Experience

A quiescent strategy no longer ends in a worker-only explanation. Premature questions are deferred with their missing premise named; mature blockers become one addressed Slack question, and an answer causes the strategy to be evaluated again.

## Acceptance

- [x] A derived maturity verdict distinguishes decision-ready blockers from premature questions. (#20260908123303-judge-whether-a-human-decision-is-mature-enough-to-block.md)
- [x] A mature blocker is asked once through the existing Slack question/answer path and attributed to its responsible person. (#20260908123303-ask-mature-blockers-in-slack-and-record-the-answer.md)
- [x] Recording an answer reopens strategy evaluation without treating `quiescent` or `no_evolutionary_move` as terminal. (#20260908123303-re-evaluate-quiescent-strategies-after-answers-arrive.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-08 — ticket archived — 20260908123303-judge-whether-a-human-decision-is-mature-enough-to-block.md
- 2026-09-08 — ticket archived — 20260908123303-ask-mature-blockers-in-slack-and-record-the-answer.md
- 2026-09-08 — ticket archived — 20260908123303-re-evaluate-quiescent-strategies-after-answers-arrive.md
- 2026-09-08 — story written — work-20260908-175401.md
