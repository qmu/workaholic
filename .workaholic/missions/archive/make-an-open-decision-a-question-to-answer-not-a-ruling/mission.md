---
type: Mission
title: Make an Open Decision a question to answer, not a ruling
slug: make-an-open-decision-a-question-to-answer-not-a-ruling
status: achieved
merge_policy:
created_at: 2026-08-22T12:58:05+09:00
author: a@qmu.jp
assignees: []
assignee:
predicted_hours:
actual_hours:
feedback: [20260822125408-implement-blocked-on-an-open-decision-its-own-source-document-already-answered.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260823-124835
---

# Make an Open Decision a question to answer, not a ruling

## Goal

An `/implement` tick stopped on an `## Open Decisions` item whose answer sat fifty lines
further down the very page the ticket was about. Two seams produced it: `/specificate` wrote
an item that named an authority and declared itself unresolvable, and `/implement` read that
declaration as evidence rather than as a claim to check. An automated seam's Open Decision
must not be self-certifying.

## Experience

A run that meets a written Open Decision reads the sources the item is about before it may
honour it as a blocker, and its report states what it found there. A run that blocks names
the sources it read and why they did not answer the item.

## Acceptance

- [x] Honouring an Open Decision as a blocker requires reading its named sources first, and
      the report states what they said (#20260822125851-require-reading-an-open-decision-s-sources-before-blocking.md)
- [x] An Open Decision this session writes names the sources a driving run must read, and
      never declares itself unresolvable (#20260822125851-stop-writing-a-self-certifying-open-decision.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-23 — ticket archived — 20260822125851-require-reading-an-open-decision-s-sources-before-blocking.md
- 2026-08-23 — ticket archived — 20260822125851-stop-writing-a-self-certifying-open-decision.md
- 2026-08-23 — mission achieved — mission.md
