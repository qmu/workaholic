---
type: Mission
title: Follow the pull requests the loop opens for a person
slug: follow-the-pull-requests-the-loop-opens-for-a-person
status: active
merge_policy:
created_at: 2026-08-29T19:20:15+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260829191722-follow-the-pull-requests-the-loop-opens-for-a-person.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260829-194055
---

# Follow the pull requests the loop opens for a person

## Goal

The loop opens pull requests **for a person** — the ones `publish-tree-pr.sh` refuses to
auto-merge — then stops following them. Measured 2026-08-29: #694 sat 18 hours unanswered
while `ruling-suppression.sh` held the questions it would have settled.

## Scope

The reader, which pull requests are the operator's, one `/moderate` question, the
ruling-hold repair, the run reports, the classification, the drill.

## Acceptance

- [x] An un-acted operator-facing pull request reaches the person who must act, once. (#20260829192137-ask-the-person-who-must-act-on-an-unanswered-pull-request.md)
- [x] The reading is `merged` / `closed` / `open:<age>` / `unreadable`, keyed off the
      seam's refusal word, classified a judgement, and gates nothing. (#20260829192136-read-back-whether-an-operator-facing-pull-request-was-acted-on.md)
- [x] The loop is never silent about a ruling and what it holds at once. (#20260829192137-release-a-ruling-hold-the-ruling-s-own-silence-has-outlived.md)

## Experience

The person who must rule is told, once, that a pull request waits on them, what it would
unblock and how long it has waited — and a subject held by a stale ruling becomes
reachable again. Nothing merges, closes or gates on the reading; a run that cannot read
one says so by name and asks nobody.

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-29 — ticket archived — 20260829192136-derive-the-operator-facing-pull-requests-from-the-seam-s-refusal-word.md
- 2026-08-29 — ticket archived — 20260829192136-read-back-whether-an-operator-facing-pull-request-was-acted-on.md
- 2026-08-29 — ticket archived — 20260829192137-ask-the-person-who-must-act-on-an-unanswered-pull-request.md
- 2026-08-29 — ticket archived — 20260829192137-classify-every-pull-request-reading-as-a-judgement-in-the-one-home.md
- 2026-08-29 — ticket archived — 20260829192137-release-a-ruling-hold-the-ruling-s-own-silence-has-outlived.md
- 2026-08-29 — ticket archived — 20260829192137-report-the-pull-request-reading-in-the-run-reports-as-evidence.md
