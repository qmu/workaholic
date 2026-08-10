---
type: Mission
title: Right-size /report to single-ticket-per-PR granularity
slug: right-size-report-to-single-ticket-per-pr-granularity
status: achieved
merge_policy:
created_at: 2026-08-09T01:06:19+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours: 0.3
feedback: [.workaholic/feedbacks/20260809010511-lighten-report-now-that-prs-are-merged-per-single-ticket-without-losing-result-records-or-cross-document-relations.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260809-025458
---

# Right-size /report to single-ticket-per-PR granularity

## Goal

The loop now merges a PR per single ticket instead of batching a whole
Story's worth of tickets into one PR. `/report`'s scope — sized around a
whole Story's volume of work — is no longer matched to the unit it reports
on, so it now costs more time and output than the work it describes.

## Experience

Running `/report` after a single-ticket branch produces a report and PR
body proportionate to that branch's size, not a Story-sized one. The two
things `/report` currently gives up nothing on: the recording of results
(what was done and its outcome) and the cross-document relations (FB issue
→ Proposal → Ticket → Report navigability) both survive the resizing.

## Acceptance

- [x] A design is written for `/report`'s right-sized unit of work (e.g.
  per-ticket instead of per-Story) that names what stays and what is
  trimmed, while preserving the result record and the FB/Proposal/
  Ticket/Report relations. (#20260809010644-design-a-right-sized-report-for-single-ticket-per-pr-granularity.md)
- [x] `/report` is implemented to that design and its per-run output/cost
  matches single-ticket-per-PR granularity, with existing linking
  (`feedback:`/`mission:` relations, the stories index, the PR body) intact. (#20260809010647-implement-the-right-sized-report-and-verify-linking-survives.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-09 — ticket archived — 20260809010644-design-a-right-sized-report-for-single-ticket-per-pr-granularity.md
- 2026-08-09 — ticket archived — 20260809010647-implement-the-right-sized-report-and-verify-linking-survives.md
- 2026-08-09 — story reported — work-20260809-025458.md
- 2026-08-09 — run recorded (+0.3h) — implement-20260809-025458
- 2026-08-10 — mission achieved — mission.md
