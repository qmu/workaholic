---
type: Mission
title: Let the operator revise a live direction through the loop
slug: let-the-operator-revise-a-live-direction-through-the-loop
status: achieved
merge_policy:
created_at: 2026-08-27T11:23:01+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260827112022-let-the-operator-revise-a-live-direction-through-the-loop.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260827-114104
---

# Let the operator revise a live direction through the loop

## Goal

Give a **live** strategy a third writer, so the operator revises the direction they own
through the loop instead of by hand on `main`. Only `## Aim`, `target_date` /
`## Schedule` and `assignees:` are revisable; every other field, the `feedback:` refs and
a closed strategy are refused. The operator's merge stays the authorship.

## Experience

The operator announces, by slug, that a direction's date has moved, that its aim has
sharpened, or that someone else carries it. Within the hour a pull request is open
carrying exactly that revision to that one file, and it does not auto-merge. Answering
`/moderate`'s "past its date" becomes a sentence in its own thread. A revision breaching
the floor, naming an immutable field or touching a closed direction is refused by name
with nothing written, and the ask still lands as a record.

## Acceptance

- [x] A *changed* announcement naming a live slug opens a pull request carrying exactly
      that revision, and it does not auto-merge. (#20260827112528-route-the-changed-announcement-to-amend-sh.md)
- [x] `amend.sh` is the one writer of a live direction's three parts, refusing an
      immutable field, a closed direction and a floor breach with nothing written. (#20260827112528-write-amend-sh-the-one-writer-of-a-live-direction.md)
- [x] The reversal is pinned mechanically and written into every document recording
      "two writers and no third". (#20260827112528-write-the-third-writer-reversal-into-the-documents.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-27 — ticket archived — 20260827112528-write-amend-sh-the-one-writer-of-a-live-direction.md
- 2026-08-27 — ticket archived — 20260827112528-hold-a-revised-strategy-to-the-write-time-floor.md
- 2026-08-27 — ticket archived — 20260827112528-record-what-a-revision-moved-in-the-schedule-prose.md
- 2026-08-27 — ticket archived — 20260827112528-pin-that-a-strategy-revision-can-never-auto-merge.md
- 2026-08-27 — ticket archived — 20260827112528-route-the-changed-announcement-to-amend-sh.md
- 2026-08-27 — ticket archived — 20260827112528-name-the-revision-act-in-the-direction-health-questions.md
- 2026-08-27 — ticket archived — 20260827112528-write-the-third-writer-reversal-into-the-documents.md
- 2026-08-27 — ticket archived — 20260827112528-drill-the-strategy-revision-end-to-end-with-no-network.md
- 2026-08-27 — mission achieved — mission.md
