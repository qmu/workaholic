---
type: Mission
title: Let an answer in the thread turn back into the loop's work
slug: let-an-answer-in-the-thread-turn-back-into-the-loop-s-work
status: achieved
merge_policy:
created_at: 2026-08-28T03:19:16+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260828031631-let-an-answer-in-the-thread-turn-back-into-the-loop-s-work.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260828-034109
---

# Let an answer in the thread turn back into the loop's work

## Goal

An answer typed into the `🔎 Moderation` thread reaches nothing: it is no channel
message, so neither `step-unanswered-asks.sh` nor the `:40` sweep sees it, and the sweep
excludes answers to the tick's own questions by rule. `record-answer.sh` is reachable
only from the moderator's own session, so answering costs a session.

## Experience

A person answers where the question was asked; the next tick reads that thread on the
coordinate it recorded, records the answer through `record-answer.sh`,
stamps it, and files one asking for work as an `[FB]` issue through
`file-inbound-ask.sh`. No new store, no second inbox, no second writer of the answered
line; the tick still writes nothing but its own log.

## Acceptance

- [x] The coordinate rides the line `ask-question.sh` already writes, and the next tick
      reads that thread and records the answer through `record-answer.sh` — one read per question, no search. (#20260828032058-record-the-coordinate-a-question-was-posted-at.md)
- [x] An answer asking for work becomes one `[FB]` issue through `file-inbound-ask.sh`,
      filed once however many ticks read it, and carries the reaction. (#20260828032101-turn-an-answer-that-asks-for-work-into-an-issue.md)
- [x] The path is drilled with no network, and the documents say so. (#20260828032058-reproduce-the-dead-return-path-and-pin-it.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-28 — ticket archived — 20260828032058-record-the-coordinate-a-question-was-posted-at.md
- 2026-08-28 — ticket archived — 20260828032058-read-the-answer-in-a-question-s-own-thread.md
- 2026-08-28 — ticket archived — 20260828032058-record-the-answer-through-the-one-writer.md
- 2026-08-28 — ticket archived — 20260828032101-turn-an-answer-that-asks-for-work-into-an-issue.md
- 2026-08-28 — ticket archived — 20260828032101-stamp-the-answer-where-it-was-written.md
- 2026-08-28 — ticket archived — 20260828032058-reproduce-the-dead-return-path-and-pin-it.md
- 2026-08-28 — ticket archived — 20260828032101-drill-the-return-path-with-no-network.md
- 2026-08-28 — ticket archived — 20260828032102-write-the-return-path-into-the-documents.md
- 2026-08-28 — mission achieved — mission.md
